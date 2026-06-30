# ---------------------------------------------------------------------------
# Scope
# ---------------------------------------------------------------------------

variable "org_id" {
  description = "Harness organization identifier"
  type        = string
}

variable "project_id" {
  description = "Harness project identifier (created when create_project is true, otherwise must already exist)"
  type        = string
}

variable "project_name" {
  description = "Harness project display name when create_project is true. Defaults to project_id."
  type        = string
  default     = null
}

variable "create_project" {
  description = "Create a new Harness project. When false, project_id must reference an existing project."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to platform resources. Merged over default_tags (same key wins)."
  type        = map(string)
  default     = {}
}

variable "default_tags" {
  description = "Baseline tags applied to all platform resources unless overridden by tags."
  type        = map(string)
  default = {
    team = "platform"
  }
}

# ---------------------------------------------------------------------------
# Feature flags
# ---------------------------------------------------------------------------

variable "create_cloud_connector" {
  description = "Create a cloud connector (AWS OIDC)"
  type        = bool
  default     = true
}

variable "create_cd_stack" {
  description = "Create CD service, environments, and infrastructure definitions"
  type        = bool
  default     = true
}

variable "create_infra_overrides" {
  description = "Create INFRA_GLOBAL_OVERRIDE per environment/infrastructure (Infrastructure Specific tab in Harness UI)."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Cloud connector
# ---------------------------------------------------------------------------

variable "cloud_connector_identifier" {
  description = "Cloud connector identifier (lowercase, underscores allowed)"
  type        = string
  default     = "cloud_connector"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.cloud_connector_identifier))
    error_message = "cloud_connector_identifier must start with a letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "cloud_connector_name" {
  description = "Display name for the cloud connector"
  type        = string
  default     = "Cloud Connector"
}

variable "cloud_connector_description" {
  description = "Description for the cloud connector"
  type        = string
  default     = "Cloud connector using Harness OIDC authentication"
}

variable "cloud_connector_tags" {
  description = "Tags for the cloud connector (Harness key:value format)"
  type        = set(string)
  default     = []
}

variable "iam_role_arn" {
  description = "AWS IAM role ARN that Harness OIDC will assume"
  type        = string
  default     = "arn:aws:iam::568258498023:role/harness-demo-oidc-role"
}

variable "cloud_region" {
  description = "Cloud region for connector test and infrastructure definitions"
  type        = string
  default     = "us-east-1"
}

variable "delegate_selectors" {
  description = "Delegate selectors for OIDC credential inheritance"
  type        = set(string)
  default     = []
}

variable "execute_on_delegate" {
  description = "Run connector operations on a delegate when true"
  type        = bool
  default     = false
}

variable "fixed_backoff" {
  description = "Fixed backoff delay in milliseconds for cloud API retries. Null omits backoff override."
  type        = number
  default     = null
}

variable "retry_count" {
  description = "Retry count when fixed_backoff is set"
  type        = number
  default     = 0
}

# ---------------------------------------------------------------------------
# CD platform
# ---------------------------------------------------------------------------

variable "service_identifier" {
  description = "Harness service identifier"
  type        = string
  default     = "platform_service"
}

variable "service_name" {
  description = "Harness service display name"
  type        = string
  default     = "Platform Service"
}

variable "service_description" {
  description = "Harness service description"
  type        = string
  default     = "Platform service managed by Terraform"
}

variable "deployment_type" {
  description = "Harness deployment type for service and infrastructure"
  type        = string
  default     = "ECS"
}

variable "task_definition_manifest_path" {
  description = "Harness File Store path to the task definition manifest"
  type        = string
  default     = "/platform/task-definition.json"
}

variable "service_definition_manifest_path" {
  description = "Harness File Store path to the service definition manifest"
  type        = string
  default     = "/platform/service-definition.json"
}

variable "cloud_connector_ref" {
  description = "Existing cloud connector reference for infrastructure when create_cloud_connector is false. Use connector identifier for project-scoped connectors."
  type        = string
  default     = null
}

variable "default_cluster" {
  description = "Default cluster name when not set per environment"
  type        = string
  default     = "default"
}

variable "cluster_overrides" {
  description = "Per-environment cluster overrides (keyed by environment identifier)"
  type        = map(string)
  default     = {}
}

variable "infrastructure_identifier_suffix" {
  description = "Suffix appended to environment key for infrastructure identifier when not explicitly set"
  type        = string
  default     = "_infra"
}

variable "allow_simultaneous_deployments" {
  description = "Allow simultaneous deployments on infrastructure definitions"
  type        = bool
  default     = false
}

variable "environments" {
  description = "Harness CD environments to create. Map key is the environment identifier."
  type = map(object({
    name                      = string
    type                      = string
    cluster                   = optional(string)
    infrastructure_identifier = optional(string)
    infrastructure_name       = optional(string)
  }))

  default = {
    dev = {
      name = "Dev"
      type = "PreProduction"
    }
    testing = {
      name = "Testing"
      type = "PreProduction"
    }
    stage = {
      name = "Stage"
      type = "PreProduction"
    }
    prod = {
      name = "Prod"
      type = "Production"
    }
  }
}
