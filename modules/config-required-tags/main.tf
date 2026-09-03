# -----------------------------------------------------------------------------
# AWS Config Managed Rule: required-tags
# -----------------------------------------------------------------------------
# Complementa (não substitui) a statement "DenyUntaggedResourceCreation" da
# permissions boundary compartilhada (envs/shared/permissions-boundary.tf):
# aquela bloqueia a CRIAÇÃO de recursos sem tag; esta regra avalia
# continuamente recursos JÁ EXISTENTES e os marca como NON_COMPLIANT se a
# tag estiver ausente -- cobre o caso de recursos criados antes da boundary
# existir, ou por fora do Terraform.
# -----------------------------------------------------------------------------

locals {
  # Monta {tag1Key = "Environment", tag2Key = "ManagedBy", ...} a partir da
  # lista var.tag_keys -- é o formato de input_parameters exigido pela regra
  # gerenciada REQUIRED_TAGS.
  input_parameters = merge([
    for idx, key in var.tag_keys : { "tag${idx + 1}Key" = key }
  ]...)
}

resource "aws_config_config_rule" "required_tags" {
  name = var.rule_name

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode(local.input_parameters)

  tags = var.tags
}
