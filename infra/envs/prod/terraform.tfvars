project     = "k8s-portfolio"
environment = "prod"
region      = "us-east-1"
zone_name   = "mbodou.org"

# --- network: highly available ---
vpc_cidr           = "10.20.0.0/16"   # different from dev (10.10) so they could be peered
az_count           = 3
single_nat_gateway = false            # one NAT per AZ: an AZ outage doesn't cut the others off
enable_waf         = true

# --- eks ---
kubernetes_version         = "1.35"
system_node_instance_types = ["m6i.large"]   # no burst credits, steady performance
system_node_min            = 3               # one per AZ
system_node_max            = 4
log_retention_days         = 30

# --- data: Multi-AZ ---
db_instance_class        = "db.t4g.small"
db_multi_az              = true      # standby in another AZ, automatic failover
db_backup_retention_days = 7

# Real production: both true. Kept false so a portfolio prod can be torn down
# with one command. Be ready to explain this trade-off in interviews.
db_deletion_protection = false
db_final_snapshot      = false