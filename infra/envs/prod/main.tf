module "stack" {
  source = "../../modules/stack"

  project     = var.project
  environment = var.environment
  region      = var.region
  zone_name   = var.zone_name

  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = var.single_nat_gateway
  enable_waf         = var.enable_waf

  kubernetes_version         = var.kubernetes_version
  admin_cidrs                = var.admin_cidrs
  admin_principal_arns       = var.admin_principal_arns
  system_node_instance_types = var.system_node_instance_types
  system_node_min            = var.system_node_min
  system_node_max            = var.system_node_max
  log_retention_days         = var.log_retention_days

  db_instance_class        = var.db_instance_class
  db_multi_az              = var.db_multi_az
  db_backup_retention_days = var.db_backup_retention_days
  db_deletion_protection   = var.db_deletion_protection
  db_final_snapshot        = var.db_final_snapshot
  db_password_version      = var.db_password_version
}
