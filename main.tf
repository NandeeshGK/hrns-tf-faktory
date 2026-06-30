# Anchor account + org references and create (or reuse) the CloudEng platform
# project. Stage templates and OPA policies are *account*-scoped; the platform
# project only houses the module-factory pipelines and the IDP workflow.

data "harness_platform_current_account" "platform_account" {}

data "harness_platform_organization" "platform_org" {
  identifier = var.platform_org_id
}

resource "harness_platform_project" "platform_project" {
  identifier = replace(replace(var.platform_project_name, " ", "_"), "-", "_")
  name       = var.platform_project_name
  org_id     = data.harness_platform_organization.platform_org.id

  tags = local.common_tags_tuple
}
