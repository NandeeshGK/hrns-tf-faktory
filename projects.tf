# Demonstration of bootstrapping an end-user Harness project against the
# account-level stage templates. Each consumer team gets a project of their own
# with the four standard pipelines (TF_Plan / TF_Apply / TF_Destroy / TF_Drift)
# already wired up. Add or remove `module "project_*"` blocks as needed, or
# replace this with a for_each driven by a CMDB / team manifest.
#
# Set `create_project = false` to attach to a pre-existing project rather than
# creating a new one.

# module "project_acme" {
#   source = "./project"
#
#   create_project = true
#   org_id         = "default"
#   project_id     = "acme"
#
#   plan_stage_template_ref         = "account.${harness_platform_template.plan.identifier}"
#   plan_stage_template_version     = harness_platform_template.plan.version
#   apply_stage_template_ref        = "account.${harness_platform_template.apply.identifier}"
#   apply_stage_template_version    = harness_platform_template.apply.version
#   destroy_stage_template_ref      = "account.${harness_platform_template.destroy.identifier}"
#   destroy_stage_template_version  = harness_platform_template.destroy.version
#   drift_stage_template_ref        = "account.${harness_platform_template.detect_drift.identifier}"
#   drift_stage_template_version    = harness_platform_template.detect_drift.version
#
#   tags = local.common_tags
# }
