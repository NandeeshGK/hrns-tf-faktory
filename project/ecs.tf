# ---------------------------------------------------------------------------
# ECS deployment building blocks (project scope)
#
# Creates:
#   * 1 ECS Service
#   * 4 Environments (Dev, Testing, Stage, Prod)
#   * 1 ECS Infrastructure Definition per environment
#   * 1 Infrastructure-specific Service Override per environment
#
# References:
#   - harness_platform_service              (Service)
#   - harness_platform_environment          (Environment)
#   - harness_platform_infrastructure       (Infrastructure Definition)
#   - harness_platform_service_overrides_v2 (Infra-specific override)
# ---------------------------------------------------------------------------

locals {
  # Environment definitions keyed by identifier. `type` maps to the Harness
  # environment type enum (PreProduction | Production).
  ecs_environments = {
    dev = {
      name = "Dev"
      type = "PreProduction"
    }
    testing = {
      name = "Testing"
      type = "PreProduction"
    }
    stage = {
      name = "Stage"
      type = "PreProduction"
    }
    prod = {
      name = "Prod"
      type = "Production"
    }
  }
}

# ---------------------------------------------------------------------------
# Service (ECS)
# ---------------------------------------------------------------------------
resource "harness_platform_service" "ecs" {
  identifier  = var.ecs_service_id
  name        = var.ecs_service_name
  description = "ECS service managed by Terraform"
  org_id      = data.harness_platform_organization.org.id
  project_id  = local.project_id
  tags        = local.common_tags_tuple

  yaml = <<-EOT
    service:
      name: ${var.ecs_service_name}
      identifier: ${var.ecs_service_id}
      orgIdentifier: ${data.harness_platform_organization.org.id}
      projectIdentifier: ${local.project_id}
      serviceDefinition:
        type: ECS
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
                        - /ecs/task-definition.json
            - manifest:
                identifier: ServiceDefinition
                type: EcsServiceDefinition
                spec:
                  store:
                    type: Harness
                    spec:
                      files:
                        - /ecs/service-definition.json
          artifacts:
            primary:
              primaryArtifactRef: <+input>
              sources: []
          variables:
            - name: cpu
              type: String
              value: "256"
            - name: memory
              type: String
              value: "512"
  EOT
}

# ---------------------------------------------------------------------------
# Environments (Dev, Testing, Stage, Prod)
# ---------------------------------------------------------------------------
resource "harness_platform_environment" "ecs" {
  for_each = local.ecs_environments

  identifier = each.key
  name       = each.value.name
  org_id     = data.harness_platform_organization.org.id
  project_id = local.project_id
  type       = each.value.type
  tags       = local.common_tags_tuple

  yaml = <<-EOT
    environment:
      name: ${each.value.name}
      identifier: ${each.key}
      orgIdentifier: ${data.harness_platform_organization.org.id}
      projectIdentifier: ${local.project_id}
      type: ${each.value.type}
      variables:
        - name: env
          type: String
          value: ${each.key}
          description: "Environment name"
  EOT
}

# ---------------------------------------------------------------------------
# Infrastructure Definition (one ECS infra per environment)
# ---------------------------------------------------------------------------
resource "harness_platform_infrastructure" "ecs" {
  for_each = local.ecs_environments

  identifier      = "${each.key}_ecs"
  name            = "${each.value.name} ECS"
  org_id          = data.harness_platform_organization.org.id
  project_id      = local.project_id
  env_id          = harness_platform_environment.ecs[each.key].identifier
  type            = "ECS"
  deployment_type = "ECS"
  tags            = local.common_tags_tuple

  yaml = <<-EOT
    infrastructureDefinition:
      name: ${each.value.name} ECS
      identifier: ${each.key}_ecs
      orgIdentifier: ${data.harness_platform_organization.org.id}
      projectIdentifier: ${local.project_id}
      environmentRef: ${each.key}
      deploymentType: ECS
      type: ECS
      spec:
        connectorRef: ${var.ecs_aws_connector_ref}
        region: ${var.ecs_region}
        cluster: ${lookup(var.ecs_clusters, each.key, var.ecs_default_cluster)}
      allowSimultaneousDeployments: false
  EOT
}

# ---------------------------------------------------------------------------
# Infrastructure-specific Service Override (one per environment)
# Scoped to service + environment + infrastructure.
# ---------------------------------------------------------------------------
resource "harness_platform_service_overrides_v2" "ecs_infra" {
  for_each = local.ecs_environments

  org_id     = data.harness_platform_organization.org.id
  project_id = local.project_id
  env_id     = harness_platform_environment.ecs[each.key].identifier
  service_id = harness_platform_service.ecs.identifier
  infra_id   = harness_platform_infrastructure.ecs[each.key].identifier
  type       = "INFRA_SERVICE_OVERRIDE"

  yaml = <<-EOT
    variables:
      - name: cpu
        type: String
        value: "${lookup(var.ecs_cpu_overrides, each.key, "256")}"
      - name: memory
        type: String
        value: "${lookup(var.ecs_memory_overrides, each.key, "512")}"
  EOT
}
