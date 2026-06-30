# Consumer-side demo pipeline — what an end-user team's deploy pipeline looks
# like when it leans on the CloudEng baseline. Lives in CloudEng_Platform for
# the demo; a real app team would copy this into their own project (or have it
# auto-created by the IDP "Create Templated Repo" workflow).
#
# NOTE: a project-scope version of this pipeline already exists in the account
# (created via MCP during initial setup) and is the one that produced the
# observable `template_enforcement` OPA warning. After this terraform applies
# the *account*-scope stage templates, that warning vanishes because the
# `templateRef` below points at `account.TF_Plan` / `account.TF_Apply`.
#
# If you want this terraform to take over the existing pipeline (instead of
# erroring on "resource exists"), import it once:
#
#   terraform import harness_platform_pipeline.application_deploy \
#     default/cloudeng_platform/Application_Deploy

resource "harness_platform_pipeline" "application_deploy" {
  org_id     = data.harness_platform_organization.platform_org.id
  project_id = harness_platform_project.platform_project.identifier

  identifier  = "Application_Deploy"
  name        = "Application Deploy"
  description = "End-to-end pipeline: plan + apply an end-user IaCM workspace using the CloudEng baseline templates."
  tags        = local.common_tags_tuple

  yaml = yamlencode({
    pipeline = {
      name              = "Application Deploy"
      identifier        = "Application_Deploy"
      projectIdentifier = harness_platform_project.platform_project.identifier
      orgIdentifier     = data.harness_platform_organization.platform_org.id
      description       = "End-to-end pipeline: plan + apply an end-user IaCM workspace using the CloudEng baseline templates."
      tags              = local.common_tags
      variables = [
        {
          name        = "workspace"
          type        = "String"
          description = "IaCM workspace identifier to plan and apply"
          required    = true
          value       = "<+input>"
        },
      ]
      stages = [
        {
          stage = {
            name       = "TF Plan"
            identifier = "TF_Plan"
            tags       = {}
            template = {
              templateRef  = "account.${harness_platform_template.plan.identifier}"
              versionLabel = harness_platform_template.plan.version
              templateInputs = {
                type = "IACM"
                spec = {
                  workspace = "<+pipeline.variables.workspace>"
                }
              }
            }
          }
        },
        {
          stage = {
            name       = "TF Apply"
            identifier = "TF_Apply"
            tags       = {}
            template = {
              templateRef  = "account.${harness_platform_template.apply.identifier}"
              versionLabel = harness_platform_template.apply.version
              templateInputs = {
                type = "IACM"
                spec = {
                  workspace = "<+pipeline.variables.workspace>"
                }
              }
            }
          }
        },
      ]
    }
  })
}
