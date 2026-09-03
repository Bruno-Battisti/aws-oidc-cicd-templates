# -----------------------------------------------------------------------------
# Role de CI plan -- somente leitura, usada por .github/workflows/terraform-plan.yml
# -----------------------------------------------------------------------------
# Propósito: dar visibilidade do diff de "terraform plan" em Pull Requests,
# sem reusar nenhuma das roles de deploy (dev/staging/prod), que têm
# permissão de escrita. Vive em envs/shared (não por ambiente) porque é uma
# preocupação de todo o projeto, não de um ambiente específico -- ela só lê
# recursos, então não há razão de segurança para separá-la por ambiente
# (ao contrário das roles de deploy, ver SECURITY.md item 2).
#
# Trust policy aceita dois valores exatos de 'sub' (StringEquals contra uma
# lista -- ainda é correspondência exata, sem wildcard, mesmo padrão
# fail-safe de envs/prod/trust-policy.tf):
#   - "repo:<org>/<repo>:pull_request" -- workflows disparados por PR
#     (terraform-plan.yml).
#   - "repo:<org>/<repo>:ref:refs/heads/<ci_plan_allowed_branch>" --
#     workflows disparados por 'schedule'/'workflow_dispatch', que não têm
#     claim de pull_request (oidc-thumbprint-check.yml).
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "ci_plan_trust" {
  statement {
    sid     = "GitHubActionsCiPlanAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.github_oidc_provider.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:pull_request",
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.ci_plan_allowed_branch}",
      ]
    }
  }
}

# Só verbos de leitura (Get/List/Describe), escopados ao namespace deste
# projeto -- mesmo padrão de prefixo "<project>-*" usado nas policies de
# deploy (envs/dev/permissions-policy.tf etc.), para que esta role não
# consiga ler recursos de outro projeto na mesma conta.
data "aws_iam_policy_document" "ci_plan_permissions" {
  statement {
    sid    = "ReadProjectIamResources"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListRoleTags",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project}-*",
    ]
  }

  statement {
    sid    = "ReadProjectDeployResources"
    effect = "Allow"
    actions = [
      "s3:GetBucketPolicy",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:ListBucket",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:ListVersionsByFunction",
      "lambda:ListTags",
    ]
    resources = [
      "arn:aws:s3:::${var.project}-*",
      "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.project}-*",
    ]
  }

  statement {
    sid       = "ReadCallerIdentity"
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  # Usado por .github/workflows/oidc-thumbprint-check.yml para comparar o
  # thumbprint configurado na AWS com o thumbprint real da cadeia TLS do
  # emissor OIDC do GitHub -- ver modules/oidc-provider/variables.tf.
  # ListOpenIDConnectProviders não suporta escopo por resource (só "*");
  # GetOpenIDConnectProvider fica escopado ao provider específico.
  statement {
    sid       = "ListOidcProviders"
    effect    = "Allow"
    actions   = ["iam:ListOpenIDConnectProviders"]
    resources = ["*"]
  }

  statement {
    sid       = "ReadOidcProvider"
    effect    = "Allow"
    actions   = ["iam:GetOpenIDConnectProvider"]
    resources = [module.github_oidc_provider.arn]
  }
}

data "aws_caller_identity" "current" {}

module "ci_plan_role" {
  source = "../../modules/iam-role"

  environment = "shared"
  role_name   = "${var.project}-ci-plan"

  trust_policy_json       = data.aws_iam_policy_document.ci_plan_trust.json
  permissions_policy_json = data.aws_iam_policy_document.ci_plan_permissions.json

  permissions_boundary_arn = aws_iam_policy.ci_plan_boundary.arn
  max_session_duration     = 1800

  tags = local.common_tags
}
