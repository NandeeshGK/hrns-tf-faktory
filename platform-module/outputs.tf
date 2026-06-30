output "project_id" {
  description = "Harness project resource ID"
  value       = local.project_id
}

output "project_identifier" {
  description = "Harness project identifier"
  value       = var.project_id
}

output "cloud_connector_id" {
  description = "Cloud connector resource ID"
  value       = var.create_cloud_connector ? harness_platform_connector_aws.cloud[0].id : null
}

output "cloud_connector_identifier" {
  description = "Cloud connector identifier"
  value       = var.create_cloud_connector ? harness_platform_connector_aws.cloud[0].identifier : null
}

output "cloud_connector_ref" {
  description = "Cloud connector reference for pipelines and infrastructure"
  value       = local.cloud_connector_ref
}

output "service_id" {
  description = "Platform service resource ID"
  value       = var.create_cd_stack ? harness_platform_service.platform[0].id : null
}

output "service_identifier" {
  description = "Platform service identifier"
  value       = var.create_cd_stack ? harness_platform_service.platform[0].identifier : null
}

output "environment_ids" {
  description = "Environment resource IDs keyed by environment identifier"
  value       = { for k, env in harness_platform_environment.platform : k => env.id }
}

output "environment_identifiers" {
  description = "Environment identifiers keyed by environment identifier"
  value       = { for k, env in harness_platform_environment.platform : k => env.identifier }
}

output "infrastructure_ids" {
  description = "Infrastructure definition resource IDs keyed by environment identifier"
  value       = { for k, infra in harness_platform_infrastructure.platform : k => infra.id }
}

output "infrastructure_identifiers" {
  description = "Infrastructure definition identifiers keyed by environment identifier"
  value       = { for k, infra in harness_platform_infrastructure.platform : k => infra.identifier }
}



output "ids" {
  description = "All created resource IDs in one map"
  value = {
    project_id         = local.project_id
    cloud_connector_id = var.create_cloud_connector ? harness_platform_connector_aws.cloud[0].id : null
    service_id         = var.create_cd_stack ? harness_platform_service.platform[0].id : null
    environments       = { for k, env in harness_platform_environment.platform : k => env.id }
    infrastructures    = { for k, infra in harness_platform_infrastructure.platform : k => infra.id }
  }
}
