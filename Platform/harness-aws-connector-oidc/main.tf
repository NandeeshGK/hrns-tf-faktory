resource "harness_platform_connector_aws" "this" {
  identifier          = var.identifier
  name                = var.name
  description         = var.description
  org_id              = var.org_id
  project_id          = var.project_id
  tags                = var.tags
  execute_on_delegate = var.execute_on_delegate

  dynamic "fixed_delay_backoff_strategy" {
    for_each = var.fixed_backoff != null ? [1] : []
    content {
      fixed_backoff = var.fixed_backoff
      retry_count   = var.retry_count
    }
  }

  oidc_authentication {
    iam_role_arn       = var.iam_role_arn
    region             = var.aws_region
    delegate_selectors = var.delegate_selectors
  }
}
