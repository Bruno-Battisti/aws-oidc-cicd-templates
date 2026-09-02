# Permissions Boundary — decisões por statement

> IAM policy JSON não suporta comentários nativamente. Este documento explica
> o "porquê" de cada `Sid` em [`permissions-boundary.json`](./permissions-boundary.json).
> A versão Terraform equivalente (com comentários inline de verdade) vive em
> `envs/shared/permissions-boundary.tf` — trate-a como a fonte da verdade;
> o `.json` aqui é uma cópia estática para leitura rápida e deve ser mantido
> em sincronia manualmente (ou gerado via `terraform show`, se preferir).

Uma permissions boundary **não concede** permissão nenhuma por si só — ela
define o **teto máximo** de permissões que uma role pode ter, mesmo que a
policy de permissões da role (a inline attachada em `modules/iam-role`)
seja mais permissiva por engano. É a rede de segurança para erro humano.

## `AllowedServicesCeiling`

Define o conjunto de serviços que **qualquer** role com esta boundary pode,
no máximo, tocar: S3, Lambda, CloudWatch Logs e `sts:GetCallerIdentity`
(usado por scripts de debug/CI para confirmar qual identidade foi assumida).
Isso significa que, mesmo que alguém erre a policy inline de uma role e
coloque `"Action": "*"`, a boundary corta tudo que não estiver nesta lista —
por exemplo, a role nunca conseguirá chamar `ec2:*`, `rds:*` ou `dynamodb:*`
por acidente.

## `DenyIamPrivilegeEscalation`

Bloqueia explicitamente as ações clássicas de escalonamento de privilégio via
IAM: criar usuários/access keys, anexar policies a si mesma ou a outras
entidades, alterar a própria trust policy, criar novas versões de policy,
**remover a própria permissions boundary** (`PutRolePermissionsBoundary` /
`DeleteRolePermissionsBoundary` — sem isso, uma role comprometida poderia
simplesmente trocar sua boundary por uma mais permissiva) e mexer no IAM
OIDC Provider. Esta é a statement mais importante do arquivo: sem ela, todas
as outras restrições são contornáveis.

## `DenyOutsideAllowedRegions`

Nega qualquer ação fora das regiões permitidas (`us-east-1`, `us-east-2` no
exemplo — ajuste para as regiões reais do seu projeto). O `NotAction`
exclui ações globais/não regionais (IAM, STS, CloudFront, Route 53, Support)
para não quebrar chamadas que não têm conceito de região. Isso reduz o risco
de "shadow resources" criados silenciosamente em uma região não monitorada.

## `DenyUntaggedResourceCreation`

Exige que recursos criados via IaC/CI (bucket S3, função Lambda) já nasçam
com a tag `Environment`. Usa a condição `Null` para negar a chamada quando a
tag **não** foi enviada na requisição (`aws:RequestTag/Environment` ausente).
Isso é a aplicação em nível de IAM da exigência de "tags obrigatórias" —
complementa (não substitui) uma AWS Config Rule de compliance contínuo, que
detecta recursos já existentes sem tag.

## `DenyOutsideProjectResourcePrefix`

Impede ações destrutivas/sensíveis em buckets S3 que não sigam o prefixo de
nome do projeto (`<PROJECT>-*`). Isso evita que uma role de um projeto acabe,
por erro de configuração, afetando o bucket de outro projeto na mesma conta.

## Trade-offs conscientes

- A boundary é **compartilhada** entre dev, staging e prod. A separação real
  de permissões por ambiente vem da policy inline de cada role (que já
  restringe pelo prefixo `<PROJECT>-<ENV>-*`) e da trust policy (que restringe
  quem pode assumir cada role). A boundary é o teto comum a todos; ela não
  substitui o escopo por ambiente, apenas garante um limite absoluto.
- `s3:*` e `lambda:*` no teto são propositalmente amplos — a boundary não
  tenta ser o único controle de acesso, apenas a última linha de defesa.
  O controle fino de "qual bucket, qual função" é responsabilidade da policy
  inline de cada role. Ver [SECURITY.md](../SECURITY.md) para a discussão
  completa de por que isso é "Nível 2" e não "Nível 3".
