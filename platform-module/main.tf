# ---------------------------------------------------------------------------
# Platform CD bootstrap
#
# Optionally provisions:
#   - Cloud connector (AWS OIDC)
#   - CD service, environments, infrastructure definitions, service overrides
# ---------------------------------------------------------------------------

data "harness_platform_organization" "org" {
  identifier = var.org_id
}

locals {
  org_id     = data.harness_platform_organization.org.id
  project_id = var.project_id

  required_tags = {
    created_by = "Terraform"
    managed_by = "hrns-tf-faktory"
  }

  common_tags       = merge(local.required_tags, var.tags)
  common_tags_tuple = [for k, v in local.common_tags : "${k}:${v}"]

  environments = var.create_cd_stack ? var.environments : {}

  cloud_connector_ref = var.create_cloud_connector ? var.cloud_connector_identifier : var.cloud_connector_ref

  infrastructure_identifiers = {
    for key, env in local.environments : key => coalesce(
      env.infrastructure_identifier,
      "${key}${var.infrastructure_identifier_suffix}"
    )
  }

  infrastructure_names = {
    for key, env in local.environments : key => coalesce(
      env.infrastructure_name,
      "${env.name} ${var.deployment_type}"
    )
  }
}

resource "terraform_data" "platform_validation" {
  lifecycle {
    precondition {
      condition     = !var.create_cd_stack || var.create_cloud_connector || var.cloud_connector_ref != null
      error_message = "cloud_connector_ref must be set when create_cloud_connector is false and create_cd_stack is true."
    }

    precondition {
      condition     = !var.create_service_overrides || var.create_cd_stack
      error_message = "create_service_overrides requires create_cd_stack to be true."
    }
  }
}

# ---------------------------------------------------------------------------
# Cloud connector (AWS OIDC)
# ---------------------------------------------------------------------------

resource "harness_platform_connector_aws" "cloud" {
  count = var.create_cloud_connector ? 1 : 0

  identifier          = var.cloud_conn
