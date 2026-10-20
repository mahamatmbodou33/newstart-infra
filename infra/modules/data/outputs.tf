output "db_address" {
  value = module.db.db_instance_address
}

output "master_secret_name" {
  value = aws_secretsmanager_secret.master.name
}

output "app_secret_names" {
  value = { for k, s in aws_secretsmanager_secret.app : k => s.name }
}
