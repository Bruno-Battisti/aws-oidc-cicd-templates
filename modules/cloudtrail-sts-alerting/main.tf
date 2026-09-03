# -----------------------------------------------------------------------------
# Alerting em tempo real para AssumeRoleWithWebIdentity fora do padrão
# -----------------------------------------------------------------------------
# Não cria um CloudTrail Trail dedicado: desde 2020 toda conta AWS entrega
# eventos de management ("AWS API Call via CloudTrail") ao event bus padrão
# do EventBridge automaticamente, sem precisar de um Trail configurado. Um
# Trail continua recomendado para retenção/auditoria de longo prazo (>90
# dias) e para regiões/serviços que exigem log de eventos de dados -- mas
# isso é infraestrutura de conta, fora do escopo deste módulo (mesmo
# racional do Config Recorder em modules/config-required-tags).
#
# Este módulo não filtra por "sub" ou origem esperada -- ele alerta em TODA
# chamada de AssumeRoleWithWebIdentity nesta conta, deixando o julgamento de
# "é esperado ou não" para quem recebe o alerta. Filtrar automaticamente
# exigiria replicar a lógica das trust policies aqui (duplicação que
# divergiria com o tempo).
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "alerts" {
  name = var.sns_topic_name
  tags = var.tags
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.assume_role_web_identity.arn]
    }
  }
}

resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_cloudwatch_event_rule" "assume_role_web_identity" {
  name        = var.rule_name
  description = "Alerta em toda chamada de sts:AssumeRoleWithWebIdentity nesta conta -- ver SECURITY.md, item 'alerting em tempo real'."

  event_pattern = jsonencode({
    source        = ["aws.sts"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["AssumeRoleWithWebIdentity"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "sns" {
  rule = aws_cloudwatch_event_rule.assume_role_web_identity.name
  arn  = aws_sns_topic.alerts.arn
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
