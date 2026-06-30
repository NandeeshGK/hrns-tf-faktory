# --- Module factory pipelines ----------------------------------------------
#
# Module-registry test execution does NOT yet support stage-template references
# (the IACMModuleTestPlugin must live inline). So we use inline pipelines that
# reuse the same `IACM_STAGE_INFRASTRUCTURE` snippet for parity with the
# templated pipelines used by end-user workspaces.
#
# These two pipelines (TF_Module_Testing, TF_Module_Integration_Testing) are
# what the `harness_platform_infra_module_testing` resource wires into every
# module registered through `module/`. On every push to a module repo, Harness
# invokes them and surfaces a status check on the PR.

resource "harness_platform_pipeline" "testing" {
  org_id     = data.harness_platform_organization.platform_org.id
  project_id = harness_platform_project.platform_project.identifier

  identifier  = "TF_Module_Testing"
  name        = "TF Module Testing"
  description = "Unit-test infrastructure module changes (runs examples/ via IACMModuleTestPlugin)"
  tags        = local.common_tags_tuple
  yaml = templatefile(
    "${path.module}/templates/pipelines/testing_pipeline_inline.yaml",
    {
      PIPELINE_IDENTIFIER       = "TF_Module_Testing"
      PIPELINE_NAME             = "TF Module Testing"
      ORGANIZATION_ID           = data.harness_platform_organization.platform_org.id
      PROJECT_ID                = harness_platform_project.platform_project.identifier
      PIPELINE_DESCRIPTION      = "Unit-test infrastructure module changes"
      IACM_STAGE_INFRASTRUCTURE = "  ${indent(4, local.IACM_STAGE_INFRASTRUCTURE)}"
      IACM_TESTING_COMMAND      = "test"
      TAGS                      = yamlencode(local.common_tags)
    }
  )
}

resource "harness_platform_pipeline" "integration_testing" {
  org_id     = data.harness_platform_organization.platform_org.id
  project_id = harness_platform_project.platform_project.identifier

  identifier  = "TF_Module_Integration_Testing"
  name        = "TF Module Integration Testing"
  description = "Integration-test modules end-to-end against real provider connectors"
  tags        = local.common_tags_tuple
  yaml = templatefile(
    "${path.module}/templates/pipelines/testing_pipeline_inline.yaml",
    {
      PIPELINE_IDENTIFIER       = "TF_Module_Integration_Testing"
      PIPELINE_NAME             = "TF Module Integration Testing"
      ORGANIZATION_ID           = data.harness_platform_organization.platform_org.id
      PROJECT_ID                = harness_platform_project.platform_project.identifier
      PIPELINE_DESCRIPTION      = "Integration-test infrastructure module changes"
      IACM_STAGE_INFRASTRUCTURE = "  ${indent(4, local.IACM_STAGE_INFRASTRUCTURE)}"
      IACM_TESTING_COMMAND      = "integration-test"
      TAGS                      = yamlencode(local.common_tags)
    }
  )
}

# --- Existing 'example' module (created out-of-band) -----------------------
#
# The `example` module already lives in the Harness module registry — created
# through the Harness UI rather than by this Terraform. It points at the
# `hrns-tf-faktory` fork on the `account.NandeeshAccountLevel` GitHub
# connector, main branch.
#
# We *only* need to attach the test pipelines to it so PR checks fire. The
# safest pattern is the read-only data source + a standalone
# `harness_platform_infra_module_testing` binding; that way Terraform never
# tries to recreate the module itself.
#
# Consumer-side reference:
#   module "example" {
#     source  = "app.harness.io/Nqvj4rBDR2KoKrjGhauyVg/example/tf"
#     version = "1.0.0"
#     # ... module inputs ...
#   }
#
# Uncomment after a `terraform apply` of the rest of this baseline (we need
# the testing pipelines to exist first).

# data "harness_platform_infra_module" "example" {
#   name   = "example"
#   system = "tf"
# }
#
# resource "harness_platform_infra_module_testing" "example" {
#   module_id           = data.harness_platform_infra_module.example.id
#   org                 = data.harness_platform_organization.platform_org.id
#   project             = harness_platform_project.platform_project.identifier
#   provider_connector  = "account.NandeeshAccountLevel" # swap for a cloud (AWS/GCP/Azure) connector when running integration tests
#   provisioner_type    = var.provisioner_type
#   provisioner_version = "1.7.5"
#   pipelines = [
#     harness_platform_pipeline.testing.identifier,
#     harness_platform_pipeline.integration_testing.identifier,
#   ]
# }

# --- Adding a brand-new module (for future modules) ------------------------
#
# This is the standard onboarding block CloudEng uses for any *new* module
# they author (i.e. when the module isn't yet in the registry). Copy, point at
# the new repo, `terraform apply` -> module is registered + test pipelines
# fire on every push.

# module "my_new_module" {
#   source = "./module"
#
#   name                 = "vpc"
#   description          = "Opinionated CloudEng AWS VPC module"
#   system               = "networking"
#   repository_connector = "account.NandeeshAccountLevel"
#   repository           = "terraform-aws-vpc"
#   repository_branch    = "main"
#   repository_path      = ""
#   provider_connector   = "account.aws_cloudeng_sandbox"
#   provisioner_type     = var.provisioner_type
#   provisioner_version  = "1.7.5"
#   testing_pipelines = [
#     harness_platform_pipeline.testing.identifier,
#     harness_platform_pipeline.integration_testing.identifier,
#   ]
#
#   org_id     = data.harness_platform_organization.platform_org.id
#   project_id = harness_platform_project.platform_project.identifier
# }
