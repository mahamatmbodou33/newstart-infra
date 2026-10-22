output "cluster_name" {
  value = module.stack.cluster_name
}

output "region" {
  value = module.stack.region
}

output "vpc_id" {
  value = module.stack.vpc_id
}

output "app_host" {
  value = module.stack.app_host
}

output "certificate_arn" {
  value = module.stack.certificate_arn
}

output "waf_acl_arn" {
  value = module.stack.waf_acl_arn
}

output "karpenter_node_role_name" {
  value = module.stack.karpenter_node_role_name
}

output "karpenter_queue_name" {
  value = module.stack.karpenter_queue_name
}

output "container_log_group" {
  value = module.stack.container_log_group
}

output "db_address" {
  value = module.stack.db_address
}

output "db_secret_names" {
  value = module.stack.db_secret_names
}

output "kubeconfig_command" {
  value = module.stack.kubeconfig_command
}
