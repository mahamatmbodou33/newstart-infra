data "aws_caller_identity" "current" {}

locals {
  name           = "${var.project}-${var.environment}"
  cluster_name   = local.name
  secrets_prefix = "${var.project}/${var.environment}"

  # The CI apply role (from bootstrap) must be admin too, so pipelines can manage the cluster
  terraform_apply_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-github-terraform-apply"

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}


module "network" {
  source = "../../modules/network"

  name               = local.name
  cluster_name       = local.cluster_name
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = var.single_nat_gateway
  tags               = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version
  region             = var.region

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnets

  admin_cidrs          = var.admin_cidrs
  admin_principal_arns = distinct(concat(var.admin_principal_arns, [local.terraform_apply_role_arn]))

  system_node_instance_types = var.system_node_instance_types
  system_node_min            = var.system_node_min
  system_node_max            = var.system_node_max

  secrets_prefix     = local.secrets_prefix
  log_retention_days = var.log_retention_days
  tags               = local.tags
}
