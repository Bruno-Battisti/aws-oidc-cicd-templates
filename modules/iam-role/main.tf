# -----------------------------------------------------------------------------
# IAM Role parametrizável para autenticação federada GitHub Actions -> AWS
# -----------------------------------------------------------------------------

locals {
  # A tag Environment é derivada de var.environment, não copiada cegamente
  # de var.tags -- isso garante por construção que a tag nunca destoa do
  # ambiente real da role, mesmo que quem chame o módulo erre o valor em
  # var.tags (ex: copiar/colar tags de outro ambiente).
  tags = merge(var.tags, { Environment = var.environment })
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  assume_role_policy   = var.trust_policy_json
  permissions_boundary = var.permissions_boundary_arn
  max_session_duration = var.max_session_duration

  # force_detach_policies garante que, ao destruir a role, as managed
  # policies anexadas sejam desanexadas automaticamente -- evita erros de
  # "DeleteConflict" no terraform destroy.
  force_detach_policies = true

  tags = local.tags
}

# Policy inline em vez de um recurso standalone: assim ela vive e morre com a
# role, sem risco de ficar "policy órfã" para trás em refactors futuros do
# módulo ou dos roots que o consomem.
resource "aws_iam_role_policy" "permissions" {
  name   = "${var.role_name}-permissions"
  role   = aws_iam_role.this.id
  policy = var.permissions_policy_json
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
