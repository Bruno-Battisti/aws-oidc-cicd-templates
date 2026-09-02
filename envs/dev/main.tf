locals {
  environment = "dev"
  role_name   = "${var.project}-${local.environment}-deploy"

  common_tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
    Project     = var.project
    Owner       = var.owner
  }
}

module "dev_deploy_role" {
  source = "../../modules/iam-role"

  environment = local.environment
  role_name   = local.role_name

  trust_policy_json       = data.aws_iam_policy_document.trust.json
  permissions_policy_json = data.aws_iam_policy_document.permissions.json

  permissions_boundary_arn = var.permissions_boundary_arn
  max_session_duration     = 3600

  tags = local.common_tags
}
