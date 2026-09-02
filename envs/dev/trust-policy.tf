# -----------------------------------------------------------------------------
# Trust policy da role de dev
# -----------------------------------------------------------------------------
# dev (e staging) confiam em um BRANCH específico do repositório, não em um
# GitHub Environment com aprovação manual -- o objetivo de dev é iterar
# rápido, então o "gate" de segurança aqui é puramente o IAM: só o branch
# configurado em var.allowed_branch pode assumir a role, e mais nada.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "GitHubActionsDevAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    # aud garante que o token OIDC foi emitido especificamente para
    # autenticação no STS da AWS -- bloqueia reuso do mesmo token em outro
    # serviço/provider que também confie no emissor do GitHub.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # sub via StringLike (não StringEquals) porque o valor final contém a
    # interpolação de allowed_branch, mas o formato "repo:org/repo:ref:..."
    # continua sendo uma correspondência exata de padrão -- StringLike aqui
    # não introduz nenhum wildcard implícito, é só o operador correto para
    # strings compostas por interpolação. Fail-safe: se github_org/github_repo
    # não forem preenchidos corretamente, a condição nunca casa e ninguém
    # assume a role.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.allowed_branch}"]
    }
  }
}
