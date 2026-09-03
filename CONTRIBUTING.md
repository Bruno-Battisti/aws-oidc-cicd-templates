# Contribuindo

Este é um projeto de referência/esqueleto — mudanças devem manter a
filosofia de "explícito em vez de implícito" já praticada no repo (ver
[SECURITY.md](./SECURITY.md) para o raciocínio por trás de cada decisão).

## Antes de abrir um PR

Rode localmente o mesmo que o CI (`.github/workflows/terraform-ci.yml`)
roda, para não gerar ida-e-volta:

```bash
terraform fmt -recursive -diff

# Para cada diretório em modules/* e envs/*:
terraform init -backend=false -input=false
terraform validate
tflint --init
tflint
```

Se o diretório tiver `tests/*.tftest.hcl`, rode também `terraform test`.

## Convenções do repo

- **Trust policy e permissions policy em arquivos próprios**
  (`trust-policy.tf`, `permissions-policy.tf`), não dentro de `main.tf` —
  é intencional (ver comentário em `.tflint.hcl` sobre
  `terraform_standard_module_structure`), não "arrume" isso.
- **Toda variável e output precisa de `description`** — regra ativa via
  `terraform_documented_variables`/`terraform_documented_outputs` no
  `.tflint.hcl`, o CI falha sem isso.
- **Nomenclatura `snake_case`** para variáveis/outputs/recursos
  (`terraform_naming_convention`).
- **Comentários explicam o "porquê", não o "o quê"** — o padrão em todo o
  repo é justificar decisões de segurança (por que uma condition existe, por
  que um trade-off foi aceito), não narrar o que o HCL já deixa óbvio.
- **Módulos não decidem trust/permissions policy** (`modules/iam-role` é
  "burro" de propósito — recebe JSON pronto). Não adicione lógica condicional
  de ambiente dentro dos módulos; isso pertence aos roots em `envs/*`.
- **Novos módulos opcionais** (Nível 3, ver `docs/optional-modules.md`)
  devem nascer com uma flag `enable_*` default `false` em `envs/shared` —
  nunca ativos por padrão.

## Estrutura para novo módulo opcional

1. `modules/<nome>/` com `main.tf`, `variables.tf`, `outputs.tf`,
   `versions.tf`.
2. Flag `enable_<nome>` (default `false`) + variáveis específicas em
   `envs/shared/variables.tf`.
3. Entrada em `docs/optional-modules.md`.
4. Adicionar o diretório às matrices `validate`/`tflint` de
   `.github/workflows/terraform-ci.yml`.
