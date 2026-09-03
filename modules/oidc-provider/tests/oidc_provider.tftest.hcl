mock_provider "aws" {}

variables {
  tags = {
    Environment = "shared"
    ManagedBy   = "terraform"
    Project     = "myproj"
    Owner       = "platform-team"
  }
}

run "url_is_always_the_github_actions_issuer" {
  command = plan

  # A URL não é parametrizável por design (ver comentário em main.tf) --
  # criar um segundo provider para outra URL é o único jeito de errar isso,
  # então o teste trava o valor em vez de confiar em revisão manual.
  assert {
    condition     = aws_iam_openid_connect_provider.github_actions.url == "https://token.actions.githubusercontent.com"
    error_message = "A URL do OIDC provider deve ser sempre o emissor do GitHub Actions"
  }
}

run "default_audience_matches_sts_condition_used_by_trust_policies" {
  command = plan

  # Todas as trust policies em envs/*/trust-policy.tf validam
  # "token.actions.githubusercontent.com:aud" == "sts.amazonaws.com". Se o
  # client_id_list default divergisse disso, toda role ficaria inutilizável.
  assert {
    condition     = contains(aws_iam_openid_connect_provider.github_actions.client_id_list, "sts.amazonaws.com")
    error_message = "client_id_list default deve incluir sts.amazonaws.com"
  }
}

run "rejects_tags_missing_a_required_key" {
  command = plan

  variables {
    tags = {
      Environment = "shared"
      ManagedBy   = "terraform"
      Project     = "myproj"
      # Owner ausente de propósito
    }
  }

  expect_failures = [
    var.tags,
  ]
}
