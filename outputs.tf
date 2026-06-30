output "platform_project_id" {
  description = "Identifier of the CloudEng Platform project that owns module-factory pipelines and IDP workflow"
  value       = harness_platform_project.platform_project.identifier
}

output "stage_template_refs" {
  description = "Account-scope stage template refs end-user pipelines should consume"
  value = {
    plan             = "account.${harness_platform_template.plan.identifier}"
    apply            = "account.${harness_platform_template.apply.identifier}"
    destroy          = "account.${harness_platform_template.destroy.identifier}"
    detect_drift     = "account.${harness_platform_template.detect_drift.identifier}"
    test             = "account.${harness_platform_template.test.identifier}"
    integration_test = "account.${harness_platform_template.integration_test.identifier}"
  }
}

output "policy_sets" {
  description = "Policy sets gating IaCM pipelines and Terraform plans"
  value = {
    iacm_pipeline = harness_platform_policyset.iacm_pipeline.identifier
    iacm_plan     = harness_platform_policyset.iacm_plan.identifier
  }
}

output "idp_workflow_url" {
  description = "URL to the IDP 'Create Templated Repo' workflow"
  value       = "${data.harness_platform_current_account.platform_account.endpoint}/ng/account/${data.harness_platform_current_account.platform_account.account_id}/module/idp/workflows/create_templated_repo"
}
