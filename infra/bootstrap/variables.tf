variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "k8s-portfolio"
}

variable "github_owner" {
  description = "Your GitHub username"
  type        = string
}

variable "infra_repo" {
  description = "Repo with Terraform + infra pipeline (plan/apply roles trust it)"
  type        = string
}

variable "app_repo" {
  description = "Repo with the application code (ECR push role trusts it)"
  type        = string
}

variable "services" {
  description = "One ECR repo per service"
  type        = list(string)
  default     = ["users", "orders", "frontend"]
}

variable "create_github_oidc_provider" {
  description = "false if your account already has one (e.g. from your three-tier project)"
  type        = bool
  default     = true
}

variable "monthly_budget_usd" {
  type    = number
  default = 100
}

variable "budget_email" {
  type = string
}

# GitHub OIDC "sub" now contains immutable numeric IDs (owner@id/repo@id).
# IDs survive renames and can't be re-used by someone else.
variable "github_owner_id" {
  type        = string
  description = "Numeric GitHub user/org ID"
}

variable "infra_repo_id" {
  type        = string
  description = "Numeric ID of the infra repo"
}

variable "app_repo_id" {
  type        = string
  description = "Numeric ID of the app repo"
}
