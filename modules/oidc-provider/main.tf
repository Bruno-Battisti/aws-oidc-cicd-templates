# -----------------------------------------------------------------------------
# IAM OIDC Provider para GitHub Actions
# -----------------------------------------------------------------------------
# Este é o recurso que estabelece a relação de confiança de baixo nível entre
# a conta AWS e o emissor de tokens OIDC do GitHub Actions
# (token.actions.githubusercontent.com). Sem ele, nenhuma IAM Role pode listar
# esse emissor como "Federated principal" na trust policy, e a autenticação
# federada (AssumeRoleWithWebIdentity) simplesmente não funciona.
#
# Por que só um provider por conta:
# A AWS impõe unicidade por URL -- tentar criar um segundo provider para a
# mesma URL falha. Por isso este módulo é chamado uma única vez a partir de
# envs/shared, e o ARN resultante é propagado (via variável ou remote state)
# para os roots de dev/staging/prod, que apenas o referenciam.
# -----------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list  = var.client_id_list
  thumbprint_list = var.thumbprint_list

  tags = var.tags
}
