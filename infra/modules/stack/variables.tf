variable "project" {
  type = string
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "region" {
  type = string
}

variable "zone_name" {
  type = string
}

# --- network ---
variable "vpc_cidr" {
  type = string
}

variable "az_count" {
  type = number
}

variable "single_nat_gateway" {
  type = bool
}

# --- edge ---
variable "enable_waf" {
  type = bool
}

# --- eks ---
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

# --- data ---
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

variable "db_final_snapshot" {
  type = bool
}

variable "db_password_version" {
  type    = number
  default = 1
}
