# -----------------------------------------------------------------------------
# Policy de permissões (least privilege) da role de prod
# -----------------------------------------------------------------------------
# Mais restrita que dev/staging por escolha deliberada: prod NÃO recebe
# permissão de delete (nem s3:DeleteObject, nem qualquer lambda:Delete*).
# Um pipeline de deploy legítimo não precisa apagar objetos/funções em prod
# no dia a dia -- se isso for necessário um dia, trate como uma operação
# manual e auditada separadamente, não como parte do fluxo automatizado de
# deploy contínuo.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "permissions" {
  statement {
    sid    = "S3DeployProd"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.project}-prod-deploy-artifacts",
      "arn:aws:s3:::${var.project}-prod-deploy-artifacts/*",
    ]
  }

  statement {
    sid    = "LambdaDeployProd"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:GetFunction",
      "lambda:PublishVersion",
    ]
    resources = [
      "arn:aws:lambda:*:${var.account_id}:function:${var.project}-prod-*",
    ]
  }
}
