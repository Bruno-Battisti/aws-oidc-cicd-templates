plugin "aws" {
  enabled = true
  version = "0.48.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Regras da ruleset "core" (terraform_*). Habilitadas explicitamente em vez
# de depender do preset padrão, para deixar claro o que este projeto exige
# de todo módulo/root: variáveis e outputs documentados, tipos declarados,
# nomes consistentes e sem declarações mortas.
rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

# terraform_standard_module_structure fica desabilitada de propósito: ela
# espera resources/data sources concentrados em main.tf, mas este projeto
# separa trust policy e permissions policy em arquivos próprios
# (trust-policy.tf, permissions-policy.tf) por legibilidade -- um padrão
# comum e intencional, não um desvio a ser sinalizado.
