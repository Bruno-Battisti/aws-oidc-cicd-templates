# mock_provider isola os testes de credenciais/rede reais -- este módulo não
# faz nenhuma chamada de API AWS durante "plan" (trust/permissions policy
# chegam prontas via variável), então mockar é só uma questão de não exigir
# nenhum provider configurado por quem roda "terraform test" localmente.
mock_provider "aws" {}

variables {
  environment = "dev"
  role_name   = "myproj-dev-deploy"

  trust_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" }
    }]
  })

  permissions_policy_json = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "s3:GetObject", Resource = "*" }]
  })

  permissions_boundary_arn = "arn:aws:iam::123456789012:policy/myproj-permissions-boundary"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "myproj"
    Owner       = "platform-team"
  }
}

run "valid_dev_role_plans_successfully" {
  command = plan

  assert {
    condition     = aws_iam_role.this.name == "myproj-dev-deploy"
    error_message = "Role name deve refletir exatamente var.role_name"
  }
}

run "environment_tag_is_always_derived_from_environment_variable" {
  command = plan

  # tags.Environment propositalmente divergente de var.environment, para
  # provar que locals.tags (main.tf) força o valor correto por construção,
  # em vez de confiar em quem chama o módulo passar a tag certa.
  variables {
    tags = {
      Environment = "staging"
      ManagedBy   = "terraform"
      Project     = "myproj"
      Owner       = "platform-team"
    }
  }

  assert {
    condition     = aws_iam_role.this.tags["Environment"] == "dev"
    error_message = "A tag Environment final deve vir de var.environment (merge em locals.tags), nunca ser copiada cegamente de var.tags"
  }
}

run "rejects_environment_outside_allowed_set" {
  command = plan

  variables {
    environment = "qa"
  }

  expect_failures = [
    var.environment,
  ]
}

run "rejects_max_session_duration_below_minimum" {
  command = plan

  variables {
    max_session_duration = 800
  }

  expect_failures = [
    var.max_session_duration,
  ]
}

run "rejects_max_session_duration_above_maximum" {
  command = plan

  variables {
    max_session_duration = 7200
  }

  expect_failures = [
    var.max_session_duration,
  ]
}

run "rejects_tags_missing_a_required_key" {
  command = plan

  variables {
    tags = {
      Environment = "dev"
      ManagedBy   = "terraform"
      Project     = "myproj"
      # Owner ausente de propósito
    }
  }

  expect_failures = [
    var.tags,
  ]
}
