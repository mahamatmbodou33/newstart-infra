data "aws_caller_identity" "current" {}

locals {
  name           = "${var.project}-${var.environment}" # k8s-portfolio-dev
  cluster_name   = local.name
  secrets_prefix = "${var.project}/${var.environment}"   # k8s-portfolio/dev
  base_domain    = "${var.environment}.${var.zone_name}" # dev.mbodou.com

  terraform_apply_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-github-terraform-apply"

  databases = {
    "user-service"         = "newstart_users"
    "opportunity-service"  = "newstart_opportunities"
    "checklist-service"    = "newstart_checklists"
    "notification-service" = "newstart_notifications"
  }

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

module "edge" {
  source = "../../modules/edge"

  name        = local.name
  zone_name   = var.zone_name
  base_domain = local.base_domain
  enable_waf  = var.enable_waf
  tags        = local.tags
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
  route53_zone_arn   = module.edge.zone_arn
  log_retention_days = var.log_retention_days
  tags               = local.tags
}

module "data" {
  source = "../../modules/data"

  name                   = local.name
  vpc_id                 = module.network.vpc_id
  db_subnet_group_name   = module.network.database_subnet_group_name
  node_security_group_id = module.eks.node_security_group_id
  secrets_prefix         = local.secrets_prefix
  databases              = local.databases

  instance_class        = var.db_instance_class
  multi_az              = var.db_multi_az
  backup_retention_days = var.db_backup_retention_days
  deletion_protection   = var.db_deletion_protection
  password_version      = var.db_password_version
  tags                  = local.tags
}