project            = "k8s-portfolio"
environment        = "dev"
region             = "us-east-1"
vpc_cidr           = "10.10.0.0/16"
az_count           = 3
single_nat_gateway = true

kubernetes_version = "1.37"


system_node_instance_types = ["t3.large"]
system_node_min            = 2
system_node_max            = 3
log_retention_days         = 7

zone_name  = "mbodou.org"
enable_waf = false

db_instance_class        = "db.t4g.micro"
db_multi_az              = false
db_backup_retention_days = 1
db_deletion_protection   = false