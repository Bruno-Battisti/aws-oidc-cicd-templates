# -----------------------------------------------------------------------------
# Policy de permissões (least privilege) da role de dev
# -----------------------------------------------------------------------------
# Escopo: só os recursos com prefixo "<project>-dev-" -- a role de dev não
# consegue, nem por engano, tocar recursos de staging ou prod, porque o nome
# desses recursos usa um prefixo diferente. Ajuste as actions/recursos para
# o que o seu pipeline de deploy realmente precisa.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "permissions" {
  statement {
    sid    = "S3DeployDev"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${var.project}-dev-deploy-artifacts",
      "arn:aws:s3:::${var.project}-dev-deploy-artifacts/*",
    ]
  }

  statement {
    sid    = "LambdaDeployDev"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:GetFunction",
      "lambda:PublishVersion",
    ]
    resources = [
      "arn:aws:lambda:*:${var.account_id}:function:${var.project}-dev-*",
    ]
  }
}
