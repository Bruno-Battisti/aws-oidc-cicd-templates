# Módulos opcionais (Nível 3)

Este documento indexa extensões **opt-in** deste esqueleto, que evoluem a
postura de segurança de Nível 2 para itens de Nível 3 (ver
[SECURITY.md](../SECURITY.md#quando-migrar-para-nível-3)). Nenhum destes
módulos é ativado por padrão — cada um tem uma flag `enable_*` em
`envs/shared/variables.tf` com default `false`, para que quem clonar o
esqueleto continue em Nível 2 até decidir conscientemente subir o nível.

| Módulo | Flag | Cobre | Pré-requisito de conta |
|---|---|---|---|
| `modules/config-required-tags` | `enable_config_required_tags` | Compliance contínuo de tags em recursos já existentes (a boundary atual só bloqueia na *criação*) | AWS Config Recorder + Delivery Channel já ativos |
| `modules/cloudtrail-sts-alerting` | `enable_sts_alerting` | Alerting em tempo real para `AssumeRoleWithWebIdentity` fora do padrão | Nenhum — usa o event bus padrão do EventBridge |
| Verificação de thumbprint OIDC | — (workflow sempre ativo) | Rotação/validação do thumbprint do OIDC provider | Role `ci-plan` (ver `envs/shared/ci-plan-role.tf`) |
| `modules/scp-examples` + `docs/multi-account-migration.md` | — (documentação, não Terraform ativo) | Multi-conta / AWS Organizations / SCPs | AWS Organizations com management account |

Cada seção abaixo é preenchida conforme o módulo correspondente é
implementado.

## `modules/config-required-tags`

Cria a AWS Config Managed Rule `REQUIRED_TAGS`, avaliando continuamente
recursos existentes contra as tags obrigatórias (`Environment`, `ManagedBy`,
`Project`, `Owner` por padrão — ajustável via `config_required_tags_keys`).
Complementa a statement `DenyUntaggedResourceCreation` da permissions
boundary (`envs/shared/permissions-boundary.tf`), que só cobre a *criação*
de recursos, não os que já existiam antes dela.

**Não cria** o Config Recorder/Delivery Channel — são singletons de conta,
normalmente já ativos via alguma baseline (Control Tower, Security Hub).
Habilitar sem isso falha com `InsufficientDeliveryChannelException`.

Habilitar: `enable_config_required_tags = true` em
`envs/shared/terraform.tfvars`.

## `modules/cloudtrail-sts-alerting`

Cria uma regra do EventBridge casando `sts:AssumeRoleWithWebIdentity` (via
`AWS API Call via CloudTrail`, evento disponível no event bus padrão sem
precisar de um Trail dedicado) e publica em um tópico SNS, com assinatura de
e-mail opcional (`sts_alert_email`). Não filtra por origem esperada —
alerta em toda chamada, deixando o julgamento de "é esperado ou não" para
quem recebe o alerta.

Habilitar: `enable_sts_alerting = true` +
`sts_alert_email = "seu-email@..."` em `envs/shared/terraform.tfvars`.

## Verificação de thumbprint OIDC

`.github/workflows/oidc-thumbprint-check.yml`, cron semanal +
`workflow_dispatch`, sempre ativo (não tem flag de módulo — é só um
workflow read-only). Reusa a role `ci-plan`
(`envs/shared/ci-plan-role.tf`) para comparar o thumbprint configurado no
IAM OIDC Provider com o thumbprint real da cadeia TLS de
`token.actions.githubusercontent.com`, avisando (sem bloquear — a AWS já
valida a cadeia automaticamente para este emissor) se divergirem.

Requer as repo Variables `CI_PLAN_ROLE_ARN`, `TF_STATE_REGION` e
`OIDC_PROVIDER_ARN` (ver seção "CI de plan" do README).

## Multi-conta / SCPs

Não vira Terraform ativo neste repo — depende de uma AWS Organization real
(management account, OU IDs) que não existe neste esqueleto. Ver
[`docs/multi-account-migration.md`](./multi-account-migration.md) para o
roteiro completo e os exemplos prontos em `modules/scp-examples/`.
