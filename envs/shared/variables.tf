variable "aws_region" {
  description = "Região AWS onde os recursos globais/de bootstrap (OIDC provider, permissions boundary) são criados. IAM é um serviço global, mas a API precisa ser chamada a partir de uma região."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Nome curto do projeto, usado como prefixo em nomes de recursos e como tag Project. Ex: myproject."
  type        = string
}

variable "owner" {
  description = "Time ou pessoa responsável pelos recursos deste projeto (tag Owner). Ex: platform-team."
  type        = string
}

variable "allowed_regions" {
  description = "Regiões AWS nas quais as roles de CI/CD deste projeto podem operar. Usada na condition da permissions boundary (DenyOutsideAllowedRegions) para reduzir o risco de recursos criados silenciosamente em regiões não monitoradas."
  type        = list(string)
  default     = ["us-east-1", "us-east-2"]
}

variable "github_org" {
  description = "Organização/usuário dono do repositório GitHub que executa os workflows. Usado na trust policy da role de CI plan (ci-plan-role.tf) -- ver github_repo."
  type        = string
}

variable "github_repo" {
  description = "Nome do repositório GitHub (sem o org). Usado, junto com github_org, para restringir o claim 'sub' da role de CI plan a este repositório."
  type        = string
}

variable "ci_plan_allowed_branch" {
  description = <<-EOT
    Branch a partir do qual workflows disparados por 'schedule' ou
    'workflow_dispatch' (não 'pull_request') podem assumir a role de CI
    plan -- usado pelo workflow de verificação de thumbprint
    (oidc-thumbprint-check.yml), que roda em cron, não em PR. O claim 'sub'
    nesse contexto é "ref:refs/heads/<branch>", diferente do claim
    ":pull_request" usado por terraform-plan.yml.
  EOT
  type        = string
  default     = "main"
}

variable "terraform_state_bucket_arn" {
  description = <<-EOT
    ARN do bucket S3 usado como backend de state (o mesmo referenciado em
    */backend.tf, que é gitignored). Opcional -- se definido, a role de CI
    plan (ci-plan-role.tf) ganha permissão de leitura sobre este bucket,
    necessária para "terraform plan" conseguir ler o state remoto em CI.
    Sem este valor, o workflow terraform-plan.yml não consegue rodar
    "terraform init" com o backend real.
  EOT
  type        = string
  default     = null
}

variable "terraform_lock_table_arn" {
  description = <<-EOT
    ARN da tabela DynamoDB usada para locking do backend de state (se você
    usa dynamodb_table no backend "s3" -- opcional em versões recentes do
    Terraform que suportam locking nativo do S3). Se definido, a role de CI
    plan ganha permissão de leitura/lock sobre esta tabela.
  EOT
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Módulos opcionais de Nível 3 (ver docs/optional-modules.md e SECURITY.md)
# -----------------------------------------------------------------------------
# Desligados por padrão -- clonar este esqueleto continua em Nível 2 até
# alguém decidir conscientemente habilitar cada item.
# -----------------------------------------------------------------------------

variable "enable_config_required_tags" {
  description = "Habilita a AWS Config Rule 'required-tags' (modules/config-required-tags) para compliance contínuo de tags em recursos já existentes. Requer um AWS Config Recorder + Delivery Channel já ativos na conta -- ver docs/optional-modules.md."
  type        = bool
  default     = false
}

variable "config_required_tags_keys" {
  description = "Chaves de tag exigidas pela Config Rule, se enable_config_required_tags = true."
  type        = list(string)
  default     = ["Environment", "ManagedBy", "Project", "Owner"]
}

variable "enable_sts_alerting" {
  description = "Habilita alerting via EventBridge + SNS (modules/cloudtrail-sts-alerting) para toda chamada de sts:AssumeRoleWithWebIdentity nesta conta -- ver docs/optional-modules.md."
  type        = bool
  default     = false
}

variable "sts_alert_email" {
  description = "E-mail que recebe os alertas de STS, se enable_sts_alerting = true. Deixe em branco para não criar assinatura de e-mail (ex: se for consumir o tópico SNS de outra forma)."
  type        = string
  default     = ""
}
