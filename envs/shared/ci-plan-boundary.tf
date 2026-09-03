# -----------------------------------------------------------------------------
# Permissions boundary dedicada à role de CI plan
# -----------------------------------------------------------------------------
# Por que uma boundary separada da compartilhada (permissions-boundary.tf):
# aquela boundary é um teto de ESCRITA para as roles de deploy (s3:*,
# lambda:*, logs:*) e não libera nenhuma ação de leitura em IAM. A role de
# CI plan (ci-plan-role.tf) precisa ler os recursos IAM que
# modules/iam-role gerencia (para "terraform plan" conseguir dar refresh na
# aws_iam_role/aws_iam_role_policy de cada ambiente) -- ampliar a boundary
# compartilhada para isso seria dar essa leitura de IAM também às roles de
# deploy, que não precisam dela. Duas boundaries com propósitos diferentes
# (uma de escrita escopada a app, outra de leitura escopada a Terraform) é
# mais claro do que uma única boundary tentando cobrir os dois casos.
#
# Esta boundary só permite verbos Get/List/Describe -- por construção, uma
# role com esta boundary não consegue executar nenhuma ação mutável, mesmo
# que a policy de permissões anexada a ela tenha um erro.
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "ci_plan_boundary" {
  statement {
    sid    = "ReadOnlyCeiling"
    effect = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*",
      "s3:Get*",
      "s3:List*",
      "lambda:Get*",
      "lambda:List*",
      "logs:Describe*",
      "logs:Get*",
      "logs:List*",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }

  # Leitura do state remoto (bucket S3) -- statement condicional porque
  # terraform_state_bucket_arn é opcional (ver variables.tf). Sem isso,
  # "terraform init"/"plan" com o backend real falha por falta de permissão
  # de ler o objeto de state.
  dynamic "statement" {
    for_each = var.terraform_state_bucket_arn != null ? [1] : []
    content {
      sid    = "ReadTerraformStateBucket"
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
      ]
      resources = [
        var.terraform_state_bucket_arn,
        "${var.terraform_state_bucket_arn}/*",
      ]
    }
  }

  # Leitura/lock da tabela de lock -- também condicional (ver
  # terraform_lock_table_arn em variables.tf). GetItem/PutItem/DeleteItem
  # são necessários mesmo em um "plan" porque o Terraform adquire o lock
  # antes de ler o state, independente do comando ser só leitura.
  dynamic "statement" {
    for_each = var.terraform_lock_table_arn != null ? [1] : []
    content {
      sid    = "TerraformStateLock"
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable",
      ]
      resources = [var.terraform_lock_table_arn]
    }
  }

  # Mesmo racional de DenyOutsideAllowedRegions em permissions-boundary.tf --
  # mesmo sendo só leitura, não há motivo para essa role conseguir ler
  # recursos fora das regiões que o projeto usa.
  statement {
    sid    = "DenyOutsideAllowedRegions"
    effect = "Deny"
    not_actions = [
      "iam:*",
      "sts:*",
      "dynamodb:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }
}

resource "aws_iam_policy" "ci_plan_boundary" {
  name        = "${var.project}-ci-plan-boundary"
  description = "Teto máximo de permissões (somente leitura) aplicado à role de CI usada para 'terraform plan' em PRs."
  policy      = data.aws_iam_policy_document.ci_plan_boundary.json

  tags = {
    Environment = "shared"
    ManagedBy   = "terraform"
    Project     = var.project
    Owner       = var.owner
  }
}
