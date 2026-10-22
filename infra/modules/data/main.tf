# --- Passwords that never touch Terraform state ---
ephemeral "random_password" "master" {
  length           = 32
  override_special = "!#%^*-_=+"
}
// --- One password per service ---
ephemeral "random_password" "app" {
  for_each         = var.databases
  length           = 32
  override_special = "!#%^*-_=+"
}

# --- Network: only EKS nodes may connect ---
// --- Security group for the database ---
resource "aws_security_group" "db" {
  name        = "${var.name}-db"
  description = "PostgreSQL from EKS nodes only"
  vpc_id      = var.vpc_id
  tags        = var.tags
}
// --- Ingress rule for the database security group ---
resource "aws_vpc_security_group_ingress_rule" "db_from_nodes" {
  security_group_id            = aws_security_group.db.id   // The database SG
  referenced_security_group_id = var.node_security_group_id // The EKS nodes SG
  ip_protocol                  = "tcp"
  from_port                    = 5432 // PostgreSQL
  to_port                      = 5432 // PostgreSQL
  description                  = "EKS nodes (managed + Karpenter)"
}

# --- The database instance ---
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.0"

  identifier = var.name

  engine               = "postgres"
  engine_version       = var.engine_version
  family               = "postgres${var.engine_version}"
  major_engine_version = var.engine_version
  instance_class       = var.instance_class

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  username                    = var.master_username
  manage_master_user_password = false
  password_wo                 = ephemeral.random_password.master.result
  password_wo_version         = var.password_version
  port                        = 5432

  multi_az               = var.multi_az
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  backup_retention_period = var.backup_retention_days
  deletion_protection     = var.deletion_protection
  
  skip_final_snapshot              = !var.final_snapshot
  final_snapshot_identifier_prefix = "${var.name}-final"

  auto_minor_version_upgrade      = true
  performance_insights_enabled    = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  create_cloudwatch_log_group     = true

  create_db_parameter_group = true
  parameters = [
    { name = "rds.force_ssl", value = "1" },
    { name = "log_min_duration_statement", value = "1000" },
  ]

  tags = var.tags
}

# --- Master credentials (used only by the DB bootstrap Job in Part 9) ---
// --- The master credentials are stored in Secrets Manager, not in Terraform state ---
resource "aws_secretsmanager_secret" "master" {
  name                    = "${var.secrets_prefix}/db/master"
  recovery_window_in_days = var.secret_recovery_days
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "master" {
  secret_id = aws_secretsmanager_secret.master.id
  secret_string_wo = jsonencode({
    username = var.master_username
    password = ephemeral.random_password.master.result
    host     = module.db.db_instance_address
    port     = "5432"
  })
  secret_string_wo_version = var.password_version
}

# --- One secret per service ---

resource "aws_secretsmanager_secret" "app" {
  for_each                = var.databases
  name                    = "${var.secrets_prefix}/db/${each.key}"
  recovery_window_in_days = var.secret_recovery_days
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "app" {
  for_each  = var.databases
  secret_id = aws_secretsmanager_secret.app[each.key].id
  secret_string_wo = jsonencode({
    username = replace(each.key, "-", "_")
    password = ephemeral.random_password.app[each.key].result
    dbname   = each.value
    host     = module.db.db_instance_address
    port     = "5432"
  })
  secret_string_wo_version = var.password_version
}