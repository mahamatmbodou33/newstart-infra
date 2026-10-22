output "cluster_name" {
  value = module.eks.cluster_name
}

output "region" {
  value = var.region
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "app_host" {
  value = "app.${local.base_domain}"
}

output "certificate_arn" {
  value = module.edge.certificate_arn
}

output "waf_acl_arn" {
  value = module.edge.waf_acl_arn
}

output "karpenter_node_role_name" {
  value = module.eks.karpenter_node_role_name
}

output "karpenter_queue_name" {
  value = module.eks.karpenter_queue_name
}

output "container_log_group" {
  value = module.eks.container_log_group
}

output "db_address" {
  value = module.data.db_address
}

output "db_secret_names" {
  value = module.data.app_secret_names
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name}"
}
