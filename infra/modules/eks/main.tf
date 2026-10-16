data "aws_caller_identity" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # --- API endpoint ---
  endpoint_private_access      = true
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.admin_cidrs

  # --- audit trail ---
  enabled_log_types                      = ["api", "audit", "authenticator"]
  cloudwatch_log_group_retention_in_days = var.log_retention_days

  # --- who is admin ---
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = false

  access_entries = {
    for i, arn in var.admin_principal_arns : "admin-${i}" => {
      principal_arn = arn
      policy_associations = {
        admin = {
          policy_arn   = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  # --- add-ons (managed by AWS, upgraded through Terraform) ---
  addons = {
    eks-pod-identity-agent = { before_compute = true } // Lets Kubernetes workloads obtain AWS permissions through Pod Identity.
    vpc-cni = { // Lets Kubernetes workloads access AWS services through VPC networking.
      before_compute       = true // Must be installed before any other add-on that requires networking.
      configuration_values = jsonencode({ enableNetworkPolicy = "true" })
    }
    kube-proxy = {} // Lets Kubernetes workloads access the cluster API through the VPC CNI.
    coredns    = {} // Lets Kubernetes workloads resolve DNS names through the cluster DNS service.
    aws-ebs-csi-driver = { // Lets Kubernetes workloads use AWS EBS volumes as persistent storage.
      pod_identity_association = [{ // Associate the EBS CSI driver pods with the EBS CSI IAM role.
        role_arn        = module.ebs_csi_pod_identity.iam_role_arn
        service_account = "ebs-csi-controller-sa"
      }]
    }
  }

  # --- system node group ---
  eks_managed_node_groups = { // Lets Kubernetes workloads run on EC2 instances managed by AWS.
    system = {                
      instance_types = var.system_node_instance_types
      capacity_type  = "ON_DEMAND"
      min_size       = var.system_node_min
      max_size       = var.system_node_max
      desired_size   = var.system_node_min

      labels = { //
        "node-role/system"        = "true"
        "karpenter.sh/controller" = "true"
      }

      iam_role_additional_policies = { // Lets the system node group run the Karpenter controller.
        ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" 
      }
    }
  }

  node_security_group_tags = { // Lets Karpenter discover the cluster's security group.
    "karpenter.sh/discovery" = var.cluster_name
  }

  tags = var.tags
}

// Karpenter is an open-source, high-performance node lifecycle management and autoscaling tool for Kubernetes clusters

module "karpenter" { 
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.0"

  cluster_name = module.eks.cluster_name // Reference to the EKS cluster name

  enable_inline_policy = true // Enable inline policy for the Karpenter controller
  
  node_iam_role_use_name_prefix = false // Use the full name for the IAM role instead of a prefix
  node_iam_role_name            = "${var.cluster_name}-karpenter-node" // Name of the IAM role for Karpenter nodes
  iam_role_use_name_prefix      = false // Use the full name for the IAM role instead of a prefix
  iam_role_name                 = "${var.cluster_name}-karpenter-controller" // Name of the IAM role for the Karpenter controller
  queue_name                    = "${var.cluster_name}-karpenter" // Name of the SQS queue for Karpenter

  create_pod_identity_association = true // Create an association between the Karpenter controller and the IAM role
  namespace                       = "kube-system" // Namespace where the Karpenter controller will be deployed
  service_account                 = "karpenter" // Service account for the Karpenter controller

  node_iam_role_additional_policies = { // Additional IAM policies for the Karpenter node role
    ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = var.tags
}

// Creates AWS permissions and a Pod Identity association for the AWS Load Balancer Controller.
// This controller manages AWS load-balancing resources for Kubernetes applications, such as Application Load Balancers (ALBs) created through Ingress resources.
// The association connects those permissions to the aws-load-balancer-controller service account in kube-system.

module "aws_lb_controller_pod_identity" { 
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name                            = "${var.cluster_name}-aws-lbc"
  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
  tags = var.tags
}

// Creates AWS permissions and a Pod Identity association for the External Secrets Controller.
// Purpose: Kubernetes applications can retrieve secrets from AWS Secrets Manager without hardcoding credentials into their container images or manifests.
module "external_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name                           = "${var.cluster_name}-external-secrets"
  attach_external_secrets_policy = true // Lets the External Secrets Controller read secrets from AWS Secrets Manager and SSM Parameter Store.
  external_secrets_secrets_manager_arns = [
    "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.secrets_prefix}/*"
  ] // Lets the External Secrets Controller read secrets from AWS Secrets Manager.
  external_secrets_ssm_parameter_arns = []
  external_secrets_kms_key_arns       = []
  external_secrets_create_permission  = false

  associations = { // Connects the permissions to the external-secrets service account
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }
  tags = var.tags
}
 // Creates the IAM role and permissions required by the EBS CSI driver to manage EBS volumes.
 // The role is associated with the ebs-csi-controller-sa service account through the EKS add-on configuration above
module "ebs_csi_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name                      = "${var.cluster_name}-ebs-csi"
  attach_aws_ebs_csi_policy = true
  tags                      = var.tags
}

// Creates a CloudWatch log group for the EKS cluster's container logs and sets up a Pod Identity association for Fluent Bit to send those logs to CloudWatch.

resource "aws_cloudwatch_log_group" "containers" {
  name              = "/eks/${var.cluster_name}/containers"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

 // Creates the IAM role and permissions required by Fluent Bit to send container logs to CloudWatch.
  // Purpose: Fluent Bit collects container logs and forwards them to CloudWatch Logs.
module "fluent_bit_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name                 = "${var.cluster_name}-fluent-bit"
  attach_custom_policy = true
  policy_statements = [
    {
      sid       = "WriteContainerLogs"
      actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
      resources = ["${aws_cloudwatch_log_group.containers.arn}:*"]
    },
    {
      sid       = "FindLogGroup"
      actions   = ["logs:DescribeLogGroups"]
      resources = ["*"]
    }
  ]

  associations = {
    this = {
      cluster_name    = module.eks.cluster_name
      namespace       = "logging"
      service_account = "aws-for-fluent-bit"
    }
  }
  tags = var.tags
}
