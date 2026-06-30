# Pillar 4: Automation
# --------------------
# An IDP workflow + backing pipeline that bootstraps a brand-new application
# repo by:
#   1. Creating a private Git repo in the CloudEng Git org
#   2. Cloning this baseline (which carries the cookiecutter template under repo/)
#   3. Running cookiecutter to render the templated app + infra-vars skeleton
#   4. Pushing the rendered code to the new repo
#
# The downstream effect: a new application is one click away from having a
# repo that already conforms to CloudEng conventions and can be pointed at an
# IaCM workspace with zero hand-editing.

resource "harness_platform_template" "create_templated_repo" {
  identifier = "Create_Templated_Repo"
  name       = "Create Templated Repo"
  comments   = "Bootstrap a new application repo from the CloudEng cookiecutter template"
  version    = "v1"
  is_stable  = true

  template_yaml = templatefile(
    "${path.module}/templates/stages/create_templated_repo.yaml",
    {
      TEMPLATE_IDENTIFIER          = "Create_Templated_Repo"
      TEMPLATE_NAME                = "Create Templated Repo"
      TEMPLATE_COMMENTS            = "Bootstrap a new application repo from a cookiecutter template"
      TEMPLATE_VERSION             = "v1"
      IDP_STAGE_INFRASTRUCTURE     = local.IDP_STAGE_INFRASTRUCTURE
      GIT_CONNECTOR_TYPE           = var.git_connector_type
      GIT_CONNECTOR_REF            = var.git_connector_ref
      GIT_ORG                      = var.git_org
      IS_PERSONAL_ACCOUNT          = var.is_personal_account
      TEMPLATE_CLONE_CONNECTOR_REF = var.template_clone_connector_ref
      TEMPLATE_CLONE_REPO_NAME     = var.template_clone_repo_name
      TEMPLATE_CLONE_BRANCH        = var.template_clone_branch
      REPO_BRANCH                  = var.repo_branch
      TAGS                         = yamlencode(local.common_tags)
    }
  )

  tags = local.common_tags_tuple
}

resource "harness_platform_pipeline" "create_templated_repo" {
  org_id     = data.harness_platform_organization.platform_org.id
  project_id = harness_platform_project.platform_project.identifier

  identifier  = "Create_Templated_Repo"
  name        = "Create Templated Repo"
  description = "Pipeline backing the IDP 'Create Templated Repo' workflow"
  tags        = local.common_tags_tuple
  yaml = templatefile(
    "${path.module}/templates/pipelines/create_templated_repo.yaml",
    {
      PIPELINE_IDENTIFIER    = "Create_Templated_Repo"
      PIPELINE_NAME          = "Create Templated Repo"
      ORGANIZATION_ID        = data.harness_platform_organization.platform_org.id
      PROJECT_ID             = harness_platform_project.platform_project.identifier
      PIPELINE_DESCRIPTION   = "Create a new repo from a cookiecutter template"
      STAGE_TEMPLATE_REF     = "account.${harness_platform_template.create_templated_repo.identifier}"
      STAGE_TEMPLATE_VERSION = harness_platform_template.create_templated_repo.version
      TAGS                   = yamlencode(local.common_tags)
    }
  )
}

resource "harness_platform_idp_catalog_entity" "create_templated_repo" {
  identifier = "create_templated_repo"
  kind       = "workflow"
  yaml = templatefile("${path.module}/templates/workflows/create_templated_repo.yaml", {
    WORKFLOW_IDENTIFIER     = "create_templated_repo"
    WORKFLOW_NAME           = "Create Templated Repo"
    ACCOUNT_URL             = data.harness_platform_current_account.platform_account.endpoint
    ACCOUNT_ID              = data.harness_platform_current_account.platform_account.account_id
    PLATFORM_ORG_ID         = data.harness_platform_organization.platform_org.id
    PLATFORM_PROJECT_ID     = harness_platform_project.platform_project.identifier
    CREATE_REPO_PIPELINE_ID = harness_platform_pipeline.create_templated_repo.identifier
  })
}
