###############################################################################
# Harness provider
###############################################################################

variable "harness_endpoint" {
  type        = string
  description = "Harness API endpoint"
  default     = "https://app.harness.io/gateway"
}

variable "harness_account_id" {
  type        = string
  description = "Harness account identifier (e.g. Nqvj4rBDR2KoKrjGhauyVg)"
}

variable "harness_platform_api_key" {
  type        = string
  description = "Harness PAT or service-account token. Provide via TF_VAR_harness_platform_api_key or an external secret reference; never commit."
  sensitive   = true
}

###############################################################################
# Platform project (owns module-factory pipelines and IDP workflow)
###############################################################################

variable "platform_org_id" {
  type        = string
  description = "Org that owns the CloudEng platform project (module-factory, IDP workflow, etc.)"
  default     = "default"
}

variable "platform_project_name" {
  type        = string
  description = "Display name of the platform project. Identifier is derived by replacing spaces/dashes with underscores."
  default     = "CloudEng Platform"
}

###############################################################################
# Stage-template execution infrastructure (Kubernetes vs Harness Cloud)
###############################################################################

variable "kubernetes_connector" {
  type        = string
  description = "K8s connector reference for self-hosted pipeline execution. Use 'skipped' for Harness Cloud."
  default     = "skipped"
}

variable "kubernetes_namespace" {
  type        = string
  description = "K8s namespace when kubernetes_connector is set"
  default     = "default"
}

variable "kubernetes_serviceaccount" {
  type        = string
  description = "K8s service account when kubernetes_connector is set, or 'skipped' for the namespace default"
  default     = "skipped"
}

variable "kubernetes_override_run_as_user" {
  type        = string
  description = "K8s pod runAsUser override (numeric string, or 'skipped')"
  default     = "skipped"

  validation {
    condition = (
      var.kubernetes_override_run_as_user == "skipped"
      || can(tonumber(var.kubernetes_override_run_as_user))
    )
    error_message = "kubernetes_override_run_as_user must be a numeric string or 'skipped'."
  }
}

variable "kubernetes_node_selectors" {
  type        = map(any)
  description = "K8s node selectors for pipeline pods"
  default     = {}
}

variable "kubernetes_override_image_connector" {
  type        = string
  description = "Container registry connector for the IaCM image, or 'skipped' for default"
  default     = "skipped"
}

variable "kubernetes_override_image_name" {
  type        = string
  description = "Custom IaCM image name (relative to kubernetes_override_image_connector), or 'skipped'"
  default     = "skipped"
}

###############################################################################
# Provisioner (Terraform vs OpenTofu) + optional custom plugin image
###############################################################################

variable "provisioner_type" {
  type        = string
  description = "Default IaCM provisioner: 'terraform' or 'opentofu'"
  default     = "opentofu"

  validation {
    condition     = contains(["terraform", "opentofu"], var.provisioner_type)
    error_message = "provisioner_type must be 'terraform' or 'opentofu'."
  }
}

variable "plugin_image" {
  type        = string
  description = "Custom IaCM TF/OpenTofu plugin image. Use 'skipped' for the default harness/harness_terraform image."
  default     = "skipped"
}

variable "plugin_connector" {
  type        = string
  description = "Container registry connector for the custom plugin image, or 'skipped'"
  default     = "skipped"
}

###############################################################################
# Security scanner thresholds
###############################################################################

variable "checkov_fail_on_severity" {
  type        = string
  description = "Checkov fail threshold: none|low|medium|high|critical"
  default     = "high"

  validation {
    condition     = contains(["none", "low", "medium", "high", "critical"], var.checkov_fail_on_severity)
    error_message = "checkov_fail_on_severity must be one of: none, low, medium, high, critical."
  }
}

###############################################################################
# IDP "Create Templated Repo" workflow inputs
###############################################################################

variable "git_connector_type" {
  type        = string
  description = "Git provider used by the IDP repo-creation workflow: Github, Gitlab, Bitbucket, etc."
  default     = "Github"
}

variable "git_connector_ref" {
  type        = string
  description = "Account-scope Git connector reference used to create new application repos (e.g. account.github_cloudeng)"
}

variable "is_personal_account" {
  type        = bool
  description = "Whether git_connector_ref points at a personal Git account (rare for CloudEng; usually false)"
  default     = false
}

variable "git_org" {
  type        = string
  description = "Git organization where the IDP workflow will create new application repos"
}

variable "template_clone_connector_ref" {
  type        = string
  description = "Account-scope Git connector reference used to clone the cookiecutter template repo"
}

variable "template_clone_repo_name" {
  type        = string
  description = "Repo (org/name) containing the cookiecutter template (the 'repo/' folder in this baseline)"
}

variable "template_clone_branch" {
  type        = string
  description = "Branch of template_clone_repo_name to read from"
  default     = "main"
}

variable "repo_branch" {
  type        = string
  description = "Default branch name for newly created application repos"
  default     = "main"
}

###############################################################################
# Tagging
###############################################################################

variable "tags" {
  type        = map(string)
  description = "Extra key/value tags applied to all managed Harness resources"
  default = {
    owner = "cloudeng"
    layer = "platform"
  }
}
