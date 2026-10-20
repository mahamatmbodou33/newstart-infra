variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "admin_cidrs" {
  description = "Who can reach the public Kubernetes API (your IP/32)"
  type        = list(string)

  validation {
    condition     = !contains(var.admin_cidrs, "0.0.0.0/0")
    error_message = "Never open the Kubernetes API to the whole internet."
  }
}

variable "admin_principal_arns" {
  description = "IAM users/roles that get cluster-admin"
  type        = list(string)
}

variable "system_node_instance_types" {
  type    = list(string)
  default = ["t3.large"]
}

variable "system_node_min" {
  type    = number
  default = 2
}

variable "system_node_max" {
  type    = number
  default = 3
}

variable "secrets_prefix" {
  description = "External Secrets may only read Secrets Manager secrets under this prefix"
  type        = string
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "route53_zone_arn" {
  description = "ExternalDNS may only change records in this hosted zone"
  type        = string
}