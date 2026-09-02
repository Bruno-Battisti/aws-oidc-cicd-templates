# -----------------------------------------------------------------------------
# Permissions Boundary compartilhada
# -----------------------------------------------------------------------------
# Esta é a FONTE DA VERDADE da permissions boundary (a versão Terraform, com
# comentários de verdade). Uma cópia estática equivalente em JSON puro, para
# leitura rápida sem precisar rodar "terraform show", vive em
# ../../policies/permissions-boundary.json -- mantenha as duas em sincronia
# se editar uma delas. A explicação statement-a-statement está em
# ../../policies/permissions-boundary.README.md.
#
# Por que uma boundary ÚNICA para os três ambientes:
# a boundary é o "teto" absoluto de permissões -- ela não substitui o escopo
# por ambiente (isso é feito pela trust policy + policy inline de cada role,
# ver envs/dev, envs/staging, envs/prod). Ter uma boundary por ambiente
# adicionaria complexidade sem adicionar segurança real neste estágio
# (Nível 2 -- ver SECURITY.md para quando migrar para boundaries por
# ambiente).
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "permissions_boundary" {
  # Teto de serviços: nenhuma role com esta boundary consegue, mesmo por
  # engano na policy inline, tocar em serviços fora desta lista.
  statement {
    sid       = "AllowedServicesCeiling"
    effect    = "Allow"
    actions   = ["s3:*", "lambda:*", "logs:*", "sts:GetCallerIdentity"]
    resources = ["*"]
  }

  # A statement mais importante do arquivo: sem isso, uma role comprometida
  # poderia se auto-conceder mais permissões (ex: anexar AdministratorAccess
  # a si mesma) ou remover a própria boundary.
  statement {
    sid    = "DenyIamPrivilegeEscalation"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateAccessKey",
      "iam:AttachUserPolicy",
      "iam:PutUserPolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DetachRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:UpdateAssumeRolePolicy",
      "iam:CreatePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:PutRolePermissionsBoundary",
      "iam:DeleteRolePermissionsBoundary",
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
    ]
    resources = ["*"]
  }

  # Restringe a "área geográfica" de blast radius. NotAction exclui serviços
  # globais/sem região (senão a condition de região quebraria chamadas
  # legítimas de IAM/STS/CloudFront/Route53/Support).
  statement {
    sid    = "DenyOutsideAllowedRegions"
    effect = "Deny"
    not_actions = [
      "iam:*",
      "sts:*",
      "cloudfront:*",
      "route53:*",
      "support:*",
    ]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }
  }

  # Aplicação em nível de IAM da exigência de tags obrigatórias: nega a
  # criação do recurso se a tag Environment não vier na própria requisição.
  # Complementa (não substitui) uma AWS Config Rule para compliance contínuo
  # de recursos já existentes.
  statement {
    sid       = "DenyUntaggedResourceCreation"
    effect    = "Deny"
    actions   = ["s3:CreateBucket", "lambda:CreateFunction"]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/Environment"
      values   = ["true"]
    }
  }

  # Evita que uma role deste projeto consiga afetar buckets de OUTRO
  # projeto na mesma conta -- blast radius contido ao próprio namespace.
  statement {
    sid    = "DenyOutsideProjectResourcePrefix"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:PutBucketPolicy",
      "s3:PutBucketAcl",
    ]
    not_resources = [
      "arn:aws:s3:::${var.project}-*",
    ]
  }
}

resource "aws_iam_policy" "permissions_boundary" {
  name        = "${var.project}-permissions-boundary"
  description = "Teto máximo de permissões aplicado a todas as IAM Roles de CI/CD deste projeto (dev, staging, prod)."
  policy      = data.aws_iam_policy_document.permissions_boundary.json

  tags = {
    Environment = "shared"
    ManagedBy   = "terraform"
    Project     = var.project
    Owner       = var.owner
  }
}
