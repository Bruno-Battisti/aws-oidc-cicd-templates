# -----------------------------------------------------------------------------
# Trust policy da role de staging
# -----------------------------------------------------------------------------
# Mesmo modelo de dev: confiança por branch (ref), não por GitHub Environment.
# Se o seu processo exigir aprovação também para staging, replique o padrão
# usado em envs/prod/trust-policy.tf (claim ":environment:<nome>").
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "GitHubActionsStagingAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.allowed_branch}"]
    }
  }
}
