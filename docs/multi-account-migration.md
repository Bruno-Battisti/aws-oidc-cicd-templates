# Migrando para multi-conta / AWS Organizations / SCPs

Este guia é para quando o item "Nível 3" do [SECURITY.md](../SECURITY.md)
sobre multi-conta deixar de ser hipotético. **Não há Terraform ativo para
isso neste repo** — diferente dos outros módulos opcionais
(`modules/config-required-tags`, `modules/cloudtrail-sts-alerting`), Service
Control Policies dependem de uma AWS Organization real (management account,
OU IDs) que este esqueleto não tem como conhecer de antemão. O que existe
aqui é o roteiro + exemplos prontos para copiar.

## Por que isso é diferente dos outros módulos opcionais

Uma SCP se aplica a nível de **Organizational Unit**, não de conta
individual — ela é criada e anexada a partir da **management account** da
Organization, não da conta onde as roles de CI/CD deste projeto vivem.
Colocar um `aws_organizations_policy` neste repo assumiria uma estrutura de
OU que só existe depois que você já decidiu migrar — por isso a extensão
natural é um repo/root **separado**, com seu próprio provider apontando
para a management account.

## Quando migrar

Ver a lista em `SECURITY.md#quando-migrar-para-nível-3`. Resumindo: quando
uma role por ambiente (o que este esqueleto já faz) deixa de ser granular o
suficiente porque múltiplas contas AWS entram em jogo (uma conta por
ambiente, ou por time), e você precisa de um teto de permissões que nenhuma
conta member consiga contornar mesmo com acesso de administrador local —
esse teto só existe a nível de Organizations (SCP), não a nível de conta
(permissions boundary, que é o que este repo usa hoje).

## Roteiro de migração

1. **Criar/já ter uma AWS Organization** com contas separadas por ambiente
   (`<project>-dev`, `<project>-staging`, `<project>-prod`) em vez de um
   único account com prefixos de nome (o modelo atual deste repo).
2. **Repetir o bootstrap deste repo em cada conta**: cada conta member
   precisa do seu próprio IAM OIDC Provider (`modules/oidc-provider`) e da
   sua própria role de deploy (`modules/iam-role`) — os módulos já são
   reaproveitáveis como estão, o que muda é rodar `envs/dev` contra a conta
   de dev, `envs/prod` contra a conta de prod, etc. (hoje todos os `envs/*`
   rodam na mesma conta).
3. **Anexar as SCPs de exemplo** (`modules/scp-examples/*.json`, ver abaixo)
   às OUs correspondentes, a partir de um root **novo**, fora deste repo,
   com provider apontando para a management account.
4. **Revisar a permissions boundary compartilhada**: com SCPs em vigor a
   nível de OU, avalie se a boundary por conta ainda precisa ser
   compartilhada entre ambientes ou se cada conta member já isolada
   justifica uma boundary por ambiente (ver SECURITY.md, item 5).

## Exemplos disponíveis

- `modules/scp-examples/deny-outside-allowed-regions.json` — mesma
  restrição de região da permissions boundary atual
  (`envs/shared/permissions-boundary.tf`), mas a nível de OU: nenhuma conta
  member consegue burlar mesmo com uma role administrativa local.
- `modules/scp-examples/deny-disable-cloudtrail.json` — bloqueia
  `cloudtrail:StopLogging`/`cloudtrail:DeleteTrail` a nível de OU, para que
  nenhuma conta member consiga desligar sua própria trilha de auditoria.

Para aplicar, em um root separado com provider na management account:

```hcl
resource "aws_organizations_policy" "deny_outside_allowed_regions" {
  name    = "deny-outside-allowed-regions"
  type    = "SERVICE_CONTROL_POLICY"
  content = file("${path.module}/deny-outside-allowed-regions.json")
}

resource "aws_organizations_policy_attachment" "deny_outside_allowed_regions" {
  policy_id = aws_organizations_policy.deny_outside_allowed_regions.id
  target_id = "<OU_ID>"
}
```
