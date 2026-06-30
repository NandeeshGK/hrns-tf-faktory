locals {
  # Tags every CloudEng-managed Harness resource will carry. `created_by` is the
  # marker we look for when reconciling against drift.
  required_tags = {
    created_by = "Terraform"
    factory    = "cloudeng-iacm-baseline"
  }

  common_tags       = merge(local.required_tags, var.tags)
  common_tags_tuple = [for k, v in local.common_tags : "${k}:${v}"]

  # Rendered into every stage template's `spec.infrastructure` block. Picks
  # between Harness Cloud runtime and self-hosted K8s based on inputs.
  k8s_setup = {
    KUBERNETES_CONNECTOR      = var.kubernetes_connector
    KUBERNETES_NAMESPACE      = var.kubernetes_namespace
    KUBERNETES_SERVICEACCOUNT = var.kubernetes_serviceaccount
    KUBERNETES_OVERRIDE_RUNAS = (
      var.kubernetes_override_run_as_user != "skipped"
      ? tonumber(var.kubernetes_override_run_as_user)
      : "skipped"
    )
    KUBERNETES_NODESELECTORS = (
      length(var.kubernetes_node_selectors) == 0
      ? "skipped"
      : yamlencode(var.kubernetes_node_selectors)
    )
    KUBERNETES_IMAGE_CONNECTOR = var.kubernetes_override_image_connector
  }

  IACM_STAGE_INFRASTRUCTURE = templatefile(
    "${path.module}/templates/snippets/iacm_infrastructure.yaml",
    local.k8s_setup
  )

  IDP_STAGE_INFRASTRUCTURE = templatefile(
    "${path.module}/templates/snippets/idp_infrastructure.yaml",
    local.k8s_setup
  )

  TF_STEP = templatefile(
    "${path.module}/templates/snippets/tf_step.yaml",
    {
      PROVISIONER_TYPE = var.provisioner_type == "terraform" ? "IACMTerraformPlugin" : "IACMOpenTofuPlugin"
      PLUGIN_IMAGE     = var.plugin_image
      PLUGIN_CONNECTOR = var.plugin_connector
    }
  )
}
