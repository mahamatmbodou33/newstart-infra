variable "name" {
  description = "Prefix for all resources, e.g. k8s-portfolio-dev"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name, used in Karpenter discovery tags"
  type        = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = number
  default = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "Use 2 or 3 AZs."
  }
}

variable "single_nat_gateway" {
  description = "true = one NAT for all AZs (cheap, dev). false = one per AZ (HA, prod)"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
