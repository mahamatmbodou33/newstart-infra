output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnets" {
  value = module.network.private_subnets
}

output "public_subnets" {
  value = module.network.public_subnets
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name} --alias ${module.eks.cluster_name}"
}

output "app_host" {
  value = "app.${local.base_domain}"
}

output "certificate_arn" {
  value = module.edge.certificate_arn
}

output "db_address" {
  value = module.data.db_address
}

output "db_secret_names" {
  value = module.data.app_secret_names
}
