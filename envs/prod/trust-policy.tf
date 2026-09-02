# -----------------------------------------------------------------------------
# Trust policy da role de prod
# -----------------------------------------------------------------------------
# Diferença crítica em relação a dev/staging: aqui o claim 'sub' usa
# ":environment:<nome>" em vez de ":ref:refs/heads/<branch>". Esse claim só
# aparece no token OIDC quando o job do workflow declara
# "environment: production" (ver .github/workflows/deploy-prod.yml) -- e um
# job com "environment" configurado com "Required reviewers" no GitHub fica
# BLOQUEADO aguardando aprovação manual antes de rodar qualquer step,
# inclusive antes de o runner conseguir solicitar o token OIDC.
#
# Ou seja: a aprovação manual não é imposta por este arquivo Terraform --
# ela é imposta pela configuração do GitHub Environment (fora do Terraform,
# em Settings > Environments do repositório) combinada com o job usar esse
# Environment. O que ESTE arquivo garante é que, mesmo que alguém tente
# contornar a aprovação chamando a API do GitHub Actions diretamente ou
# alterando o workflow, a AWS ainda vai exigir que o token tenha o claim de
# environment correto -- sem ele, o AssumeRoleWithWebIdentity é negado pelo
# IAM antes mesmo de qualquer policy de permissões ser avaliada.
#
# Por que StringEquals (não StringLike) aqui: prod não deve aceitar NENHUM
# padrão/wildcard no sub -- é correspondência exata ou nada. Esse é o
# princípio de "fail-safe por padrão" citado no SECURITY.md.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "GitHubActionsProdAssumeRole"
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
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:environment:${var.github_environment}"]
    }
  }
}
