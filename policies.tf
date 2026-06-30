# Account-level OPA policies. Policy sets bind them to events:
#   * iacm_pipeline    -> action=onsave  / type=pipeline       (catches bad pipeline YAML on save)
#   * iacm_plan        -> action=afterTerraformPlan / type=terraformPlan
#                                                  (catches bad module sources/resources during plan)
#
# Severities default to "warning" so CloudEng can introduce these without
# breaking existing pipelines; flip to "error" once teams are clean.

resource "harness_platform_policy" "template_enforcement" {
  identifier  = "template_enforcement"
  name        = "Template Enforcement"
  description = "Require every IaCM stage to consume an account-level CloudEng stage template"
  rego        = file("${path.module}/templates/policies/template_enforcement.rego")
}

resource "harness_platform_policy" "allowed_modules" {
  identifier  = "allowed_modules"
  name        = "Allowed Modules"
  description = "Restrict Terraform module sources to local paths, the Harness module registry, and a curated public allow-list"
  rego        = file("${path.module}/templates/policies/allowed_modules.rego")
}

resource "harness_platform_policyset" "iacm_pipeline" {
  identifier = "iacm_pipeline"
  name       = "IaCM Pipeline Policy Set"
  action     = "onsave"
  type       = "pipeline"
  enabled    = true

  policy_references {
    identifier = harness_platform_policy.template_enforcement.identifier
    severity   = "warning"
  }
}

resource "harness_platform_policyset" "iacm_plan" {
  identifier = "iacm_plan"
  name       = "IaCM Plan Policy Set"
  action     = "afterTerraformPlan"
  type       = "terraformPlan"
  enabled    = true

  policy_references {
    identifier = harness_platform_policy.allowed_modules.identifier
    severity   = "warning"
  }
}
