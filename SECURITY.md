# Security

Este documento registra as decisões de segurança tomadas neste projeto, o
raciocínio por trás delas, e os trade-offs conscientes de operar em
**Nível 2** de maturidade em vez de Nível 1 ou Nível 3.

## Modelo de maturidade usado como referência

| Nível | Características |
|---|---|
| **1 — Básico** | OIDC configurado, mas trust policy ampla (ex: `sub` confia em todo o repo, `repo:<org>/<repo>:*`, ou até na org inteira). Uma role só, sem separação por ambiente. Sem boundary. |
| **2 — Este projeto** | Role por ambiente, trust policy restrita por branch/environment, permissions boundary compartilhada, tags obrigatórias, least privilege por ambiente. |
| **3 — Avançado** | Boundaries por ambiente (não compartilhada), roles por workflow/job (não por ambiente), SCPs a nível de Organizations, AWS Config Rules ativas bloqueando non-compliance, CloudTrail + alerting em tempo real para `AssumeRoleWithWebIdentity` fora do padrão esperado, IAM Access Analyzer rodando continuamente, sessões com session policies adicionais por chamada. |

## Decisões tomadas e por quê

### 1. IAM OIDC Provider em vez de access keys estáticas

**Decisão**: nenhuma credencial de longa duração é usada pelo CI.
**Por quê**: elimina a classe inteira de risco de "secret vazado continua
válido para sempre". O token OIDC do GitHub expira em minutos e é assinado
por execução de workflow — não há nada de longa duração para vazar.

### 2. Uma IAM Role por ambiente, não uma role única

**Decisão**: `dev`, `staging` e `prod` têm roles, trust policies e policies
de permissão **completamente separadas**.
**Por quê**: least privilege real exige que um workflow rodando para dev
seja fisicamente incapaz (não apenas "não deveria") de tocar recursos de
prod. Uma role única com lógica condicional dentro do workflow para decidir
"o que pode fazer" depende de o workflow estar correto — uma role por
ambiente move essa garantia para a camada de IAM, que é mais difícil de
contornar por erro de código no workflow.

### 3. `sub` claim como principal linha de defesa na trust policy

**Decisão**:
- dev/staging: `repo:<org>/<repo>:ref:refs/heads/<branch>` (StringLike).
- prod: `repo:<org>/<repo>:environment:<nome>` (StringEquals, sem wildcard).

**Por quê**: o claim `sub` é a única parte do token que amarra a chamada a
uma origem específica e verificável. `StringEquals` em prod (em vez de
`StringLike`) é deliberado — prod não deve aceitar nenhum padrão, só
correspondência exata. **Trade-off aceito**: se o nome do GitHub Environment
mudar, a trust policy quebra até ser atualizada — isso é o comportamento
correto (fail-safe: prefere negar acesso a aceitar por engano).

**Por que também validar `aud`**: sem a condition de `aud ==
sts.amazonaws.com`, um token OIDC do GitHub emitido para OUTRO consumidor
(qualquer serviço que também confie no emissor do GitHub) poderia, em teoria,
ser reaproveitado contra a AWS. Validar `aud` fecha essa brecha.

### 4. Aprovação manual só em prod, via GitHub Environment

**Decisão**: dev e staging rodam sem intervenção humana; prod exige
aprovação via **Required reviewers** no GitHub Environment.
**Por quê**: equilíbrio entre velocidade de iteração (dev/staging) e
controle humano no que afeta produção. A aprovação é reforçada em duas
camadas independentes: (a) o GitHub bloqueia o job até aprovação, (b) a AWS
só aceita o token se ele carregar o claim de `environment`, que só existe se
(a) foi respeitado. **Trade-off aceito**: isso adiciona latência ao deploy
de prod — considerado aceitável dado o que está em jogo.

### 5. Permissions boundary compartilhada entre os três ambientes

**Decisão**: uma única boundary (`envs/shared/permissions-boundary.tf`) é
aplicada a todas as roles, em vez de uma boundary por ambiente.
**Por quê**: a boundary é a rede de segurança contra erro de configuração na
policy de permissões (o "teto absoluto"), não o mecanismo de separação por
ambiente — essa separação já vem da trust policy (quem pode assumir) e da
policy inline de cada role (o que pode fazer, já escopado por prefixo
`<project>-<env>-*`). Ter uma boundary por ambiente adicionaria superfície
de manutenção sem adicionar uma garantia de segurança que já não exista.
**Quando migrar para boundaries por ambiente (Nível 3)**: se prod tiver
requisitos de compliance que exijam isolamento de blast radius mais estrito
mesmo dentro do "teto", ou se dev/staging precisarem de um teto mais
permissivo que prod (ex: dev testando integração com um serviço que prod não
usa).

### 6. Tags obrigatórias reforçadas via IAM, não só convenção

**Decisão**: a permissions boundary nega a criação de recursos (`s3:CreateBucket`,
`lambda:CreateFunction`) que não incluam a tag `Environment` na própria
requisição (`aws:RequestTag`).
**Por quê**: convenção sozinha ("lembrem de taggear") não escala e falha
silenciosamente. Forçar via IAM é fail-safe. **Trade-off aceito**: isso só
cobre recursos criados por chamadas que suportam `RequestTag` nessas ações
específicas — não é uma garantia de compliance retroativa para recursos já
existentes. Para isso, uma **AWS Config Rule** (`required-tags`) rodando em
modo de detecção contínua é o complemento recomendado (não incluído neste
esqueleto inicial — ver "Quando migrar para Nível 3").

### 7. Restrição de região na permissions boundary

**Decisão**: ações fora de `us-east-1`/`us-east-2` (configurável) são
negadas por padrão, exceto serviços globais (IAM, STS, CloudFront, Route 53,
Support).
**Por quê**: reduz a chance de recursos serem criados silenciosamente em uma
região não monitorada por dashboards/alertas — um padrão comum em contas
comprometidas é justamente "esconder" atividade numa região pouco vigiada.

### 8. Sessões de curta duração, mais curtas ainda em prod

**Decisão**: `max_session_duration` de 3600s (1h) em dev/staging, 1800s
(30min) em prod.
**Por quê**: reduz a janela de validade de uma credencial temporária caso
ela vaze de algum jeito (ex: logada por engano em um step do workflow).

## Quando migrar para Nível 3

Considere evoluir além deste esqueleto quando:

- O número de workflows/times crescer a ponto de "uma role por ambiente" não
  ser granular o suficiente (ex: você quer que o workflow de deploy de
  frontend não consiga tocar a infraestrutura de backend, mesmo dentro do
  mesmo ambiente).
- Requisitos de compliance formal (SOC 2, ISO 27001, PCI-DSS) exigirem
  boundaries por ambiente, AWS Config Rules ativas em modo enforcement, ou
  auditoria automatizada de toda mudança de IAM.
- A organização usa AWS Organizations com múltiplas contas — nesse cenário,
  Service Control Policies (SCPs) a nível de OU substituem/complementam boa
  parte do que a permissions boundary faz hoje neste projeto.
- Você quiser alertas em tempo real (EventBridge + CloudTrail) para todo
  `AssumeRoleWithWebIdentity` fora do padrão esperado, não apenas prevenção
  preventiva via IAM.

## O que este projeto explicitamente NÃO cobre (ainda)

- AWS Config Rules / compliance contínuo de tags em recursos pré-existentes.
- Alerting/observabilidade sobre uso das roles (CloudTrail + EventBridge).
- Rotação/versionamento automático do thumbprint do OIDC provider.
- Multi-conta / AWS Organizations / SCPs.
- Testes automatizados de policy (ex: `terraform test`, `conftest`/OPA sobre
  os planos de Terraform).

Essas são extensões naturais para quem for evoluir este esqueleto — não
foram incluídas para manter o escopo inicial gerenciável, conforme pedido.

## Reportando vulnerabilidades

Este é um projeto de referência/esqueleto. Se você encontrar um problema de
segurança na estrutura ou nas policies de exemplo, abra uma issue no
repositório descrevendo o cenário de exploração.
