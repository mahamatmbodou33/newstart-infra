output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "node_security_group_id" {
  description = "RDS will allow 5432 from this SG (Part 4)"
  value       = module.eks.node_security_group_id
}

output "karpenter_node_role_name" {
  value = module.karpenter.node_iam_role_name
}

output "karpenter_queue_name" {
  value = module.karpenter.queue_name
}

output "container_log_group" {
  value = aws_cloudwatch_log_group.containers.name
}
