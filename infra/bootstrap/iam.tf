# --- 1. plan: read-only, used on pull requests ---
// --- The plan role is read-only, but it can also lock the Terraform state file and refresh secrets from Secrets Manager. ---
resource "aws_iam_role" "terraform_plan" {
  name               = "${var.project}-github-terraform-plan"
  assume_role_policy = data.aws_iam_policy_document.github_trust["plan"].json
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.terraform_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
// --- Extra permissions for the plan role: lock state file and refresh secrets ---
resource "aws_iam_role_policy" "plan_extras" {
  name = "state-lock-and-secret-refresh"
  role = aws_iam_role.terraform_plan.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StateLockFiles"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.state.arn}/*.tflock"
      },
      {
        Sid      = "RefreshProjectSecrets"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:*:${local.account_id}:secret:${var.project}/*"
      }
    ]
  })
}

# --- 2. apply: admin, only from GitHub environments dev/prod ---
// --- The apply role is admin, but it can only be assumed from the GitHub environments dev/prod. ---
resource "aws_iam_role" "terraform_apply" {
  name               = "${var.project}-github-terraform-apply"
  assume_role_policy = data.aws_iam_policy_document.github_trust["apply"].json
}
// --- Extra permissions for the apply role: admin access ---
resource "aws_iam_role_policy_attachment" "apply_admin" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- 3. ecr-push: main branch only, only this project's repos ---
// --- The ecr-push role is used to push Docker images to the ECR repositories of this project. It can only be assumed from the main branch of the app repo. ---
resource "aws_iam_role" "ecr_push" {
  name               = "${var.project}-github-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.github_trust["ecr"].json
}
// --- Extra permissions for the ecr-push role: push to ECR repos ---
resource "aws_iam_role_policy" "ecr_push" {
  name = "ecr-push"
  role = aws_iam_role.ecr_push.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload",
          "ecr:PutImage", "ecr:DescribeImages"
        ]
        Resource = [for r in aws_ecr_repository.svc : r.arn]
      }
    ]
  })
}
