variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "az_count" {
  type = number
}

variable "single_nat_gateway" {
  type = bool
}

variable "kubernetes_version" {
  type = string
}

variable "admin_cidrs" {
  type = list(string)
}

variable "admin_principal_arns" {
  type = list(string)
}

variable "system_node_instance_types" {
  type = list(string)
}

variable "system_node_min" {
  type = number
}

variable "system_node_max" {
  type = number
}

variable "log_retention_days" {
  type = number
}

variable "zone_name" {
  type = string
}

variable "enable_waf" {
  type = bool
}

variable "db_instance_class" {
  type = string
}

variable "db_multi_az" {
  type = bool
}

variable "db_backup_retention_days" {
  type = number
}

variable "db_deletion_protection" {
  type = bool
}

variable "db_password_version" {
  type    = number
  default = 1
}
