# ---------------------------------------------------------------------------
# Platform CD bootstrap
#
# Optionally provisions:
#   - Harness project (optional)
#   - Cloud connector (AWS OIDC)
#   - CD service, environments, infrastructure definitions, infra overrides (INFRA_GLOBAL_OVERRIDE)
# ---------------------------------------------------------------------------

data "harness_platform_organization" "org" {
  identifier = var.org_id
}

resource "harness_platform_project" "platform" {
  count = var.create_project ? 1 : 0

  identifier = var.project_id
  name       = coalesce(var.project_name, var.project_id)
  org_id     = data.harness_platform_organization.org.id
}

data "harness_platform_project" "platform" {
  count = var.create_project ? 0 : 1

  identifier = var.project_id
  org_id     = data.harness_platform_organization.org.id
}

locals {
  org_id     = data.harness_platform_organization.org.id
  project_id = var.create_project ? harness_platform_project.platform[0].id : data.harness_platform_project.platform[0].id

  common_tags       = merge(var.default_tags, var.tags)
  common_tags_tuple = [for k, v in local.common_tags : "${k}:${v}"]

  environments = var.create_cd_stack ? var.environments : {}

  # Project-scoped connector in infra YAML: use identifier only (same project as infra).
  # Qualified refs (org.* / account.*) are only needed for cross-scope connectors.
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
      condition     = !var.create_infra_overrides || var.create_cd_stack
      error_message = "create_infra_overrides requires create_cd_stack to be true."
    }
  }
}

# ---------------------------------------------------------------------------
# Cloud connector (AWS OIDC)
# ---------------------------------------------------------------------------

resource "harness_platform_connector_aws" "cloud" {
  count = var.create_cloud_connector ? 1 : 0

  identifier          = var.cloud_connector_identifier
  name                = var.cloud_connector_name
  description         = var.cloud_connector_description
  org_id              = local.org_id
  project_id          = local.project_id
  tags                = var.cloud_connector_tags
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
    region             = var.cloud_region
    delegate_selectors = var.delegate_selectors
  }
}

# ---------------------------------------------------------------------------
# CD service
# ---------------------------------------------------------------------------

resource "harness_platform_service" "platform" {
  count = var.create_cd_stack ? 1 : 0

  identifier  = var.service_identifier
  name        = var.service_name
  description = var.service_description
  org_id      = local.org_id
  project_id  = local.project_id
  tags        = local.common_tags_tuple

  yaml = <<-EOT
    service:
      name: ${var.service_name}
      identifier: ${var.service_identifier}
      orgIdentifier: ${local.org_id}
      projectIdentifier: ${local.project_id}
      serviceDefinition:
        type: ${var.deployment_type}
        spec:
          manifests:
            - manifest:
                identifier: TaskDefinition
                type: EcsTaskDefinition
                spec:
                  store:
                    type: Harness
                    spec:
                      files:
                        - ${var.task_definition_manifest_path}
            - manifest:
                identifier: ServiceDefinition
                type: EcsServiceDefinition
                spec:
                  store:
                    type: Harness
                    spec:
                      files:
                        - ${var.service_definition_manifest_path}
          artifacts:
            primary:
              primaryArtifactRef: <+input>
              sources: []
  EOT
}

# ---------------------------------------------------------------------------
# Environments
# ---------------------------------------------------------------------------

resource "harness_platform_environment" "platform" {
  for_each = local.environments

  identifier = each.key
  name       = each.value.name
  org_id     = local.org_id
  project_id = local.project_id
  type       = each.value.type
  tags       = local.common_tags_tuple

  yaml = <<-EOT
    environment:
      name: ${each.value.name}
      identifier: ${each.key}
      orgIdentifier: ${local.org_id}
      projectIdentifier: ${local.project_id}
      type: ${each.value.type}
  EOT
}

# ---------------------------------------------------------------------------
# Infrastructure definitions
# ---------------------------------------------------------------------------

resource "harness_platform_infrastructure" "platform" {
  for_each = local.environments

  identifier      = local.infrastructure_identifiers[each.key]
  name            = local.infrastructure_names[each.key]
  org_id          = local.org_id
  project_id      = local.project_id
  env_id          = harness_platform_environment.platform[each.key].identifier
  type            = var.deployment_type
  deployment_type = var.deployment_type
  tags            = local.common_tags_tuple

  depends_on = [harness_platform_connector_aws.cloud]

  yaml = <<-EOT
    infrastructureDefinition:
      name: ${local.infrastructure_names[each.key]}
      identifier: ${local.infrastructure_identifiers[each.key]}
      orgIdentifier: ${local.org_id}
      projectIdentifier: ${local.project_id}
      environmentRef: ${each.key}
      deploymentType: ${var.deployment_type}
      type: ${var.deployment_type}
      spec:
        connectorRef: ${local.cloud_connector_ref}
        region: ${var.cloud_region}
        cluster: ${coalesce(try(each.value.cluster, null), lookup(var.cluster_overrides, each.key, var.default_cluster))}
      allowSimultaneousDeployments: ${var.allow_simultaneous_deployments}
  EOT
}

# ---------------------------------------------------------------------------
# Infrastructure-specific overrides (INFRA_GLOBAL_OVERRIDE)
# ---------------------------------------------------------------------------
resource "harness_platform_service_overrides_v2" "infra" {
  for_each = {} 

  org_id     = var.org_id
  project_id = var.project_id
  env_id     = "dev"
  infra_id   = "dev_infra"
  service_id = "platform_service"   # [0] because the service uses count
  type       = "INFRA_GLOBAL_OVERRIDE"

  yaml = <<-EOT
    variables:
      - name: env
        type: String
        value: ${each.key}
  EOT
}
