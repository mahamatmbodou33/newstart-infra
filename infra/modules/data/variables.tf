variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_subnet_group_name" {
  type = string
}

variable "node_security_group_id" {
  type = string
}

variable "secrets_prefix" {
  description = "e.g. k8s-portfolio/dev (External Secrets can only read under this)"
  type        = string
}

variable "databases" {
  description = "service name => database name"
  type        = map(string)
}

variable "engine_version" {
  type    = string
  default = "17"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "master_username" {
  type    = string
  default = "newstart_admin"
}

variable "password_version" {
  description = "Increase by 1 to rotate ALL generated passwords"
  type        = number
  default     = 1
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_days" {
  type    = number
  default = 1
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "secret_recovery_days" {
  description = "0 = delete immediately on destroy, so dev can be recreated right away"
  type        = number
  default     = 0
}

variable "tags" {
  type    = map(string)
  default = {}
}
