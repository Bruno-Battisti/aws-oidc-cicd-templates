# -----------------------------------------------------------------------------
# Policy de permissões (least privilege) da role de staging
# -----------------------------------------------------------------------------
# Escopo idêntico ao de dev, mas com prefixo "<project>-staging-" -- a role
# de staging não consegue tocar recursos de dev nem de prod.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "permissions" {
  statement {
    sid    = "S3DeployStaging"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${var.project}-staging-deploy-artifacts",
      "arn:aws:s3:::${var.project}-staging-deploy-artifacts/*",
    ]
  }

  statement {
    sid    = "LambdaDeployStaging"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:GetFunction",
      "lambda:PublishVersion",
    ]
    resources = [
      "arn:aws:lambda:*:${var.account_id}:function:${var.project}-staging-*",
    ]
  }
}
