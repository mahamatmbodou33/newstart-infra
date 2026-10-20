// This file creates an IAM OIDC provider for GitHub Actions, and three IAM roles for Terraform plan, apply, and ECR push. The trust policies for the roles are defined in the data.aws_iam_policy_document.github_trust resource, which uses the GitHub OIDC provider ARN and the appropriate "sub" values for each role.
resource "aws_iam_openid_connect_provider" "github" {
  count          = var.create_github_oidc_provider ? 1 : 0 // Create the OIDC provider if the variable is true
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

locals {
  github_oidc_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# One trust policy per role. The ONLY difference is the "sub" value.
data "aws_iam_policy_document" "github_trust" {
  for_each = {
    plan  = ["repo:${local.infra_repo}:pull_request"]
    apply = ["repo:${local.infra_repo}:environment:dev", "repo:${local.infra_repo}:environment:prod"]
    ecr   = ["repo:${local.app_repo}:ref:refs/heads/main"]
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = each.value
    }
  }
}