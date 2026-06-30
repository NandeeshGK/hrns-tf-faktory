variable "identifier" {
  description = "Harness connector identifier (lowercase, underscores allowed)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.identifier))
    error_message = "identifier must start with a letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "name" {
  description = "Display name for the AWS connector in Harness"
  type        = string
}

variable "description" {
  description = "Optional description for the connector"
  type        = string
  default     = "AWS connector using Harness OIDC authentication"
}

variable "org_id" {
  description = "Harness organization identifier. Omit for account-scoped connector."
  type        = string
  default     = null
}

variable "project_id" {
  description = "Harness project identifier. Requires org_id when set."
  type        = string
  default     = null
}

variable "iam_role_arn" {
  description = "AWS IAM role ARN that Harness OIDC will assume"
  type        = string
  default     = "arn:aws:iam::568258498023:role/harness-demo-oidc-role"
}

variable "aws_region" {
  description = "AWS region used for the connector connection test"
  type        = string
  default     = "us-east-1"
}

variable "delegate_selectors" {
  description = "Delegate selectors that inherit OIDC credentials. Leave empty for Harness-managed runtimes."
  type        = set(string)
  default     = []
}

variable "execute_on_delegate" {
  description = "When true, connector operations run on a delegate matching delegate_selectors"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Harness tags in key:value string format (e.g. team:platform)"
  type        = set(string)
  default     = []
}

variable "fixed_backoff" {
  description = "Fixed backoff delay in milliseconds for AWS API retries. Set null to omit backoff override."
  type        = number
  default     = null
}

variable "retry_count" {
  description = "Retry count when fixed_backoff is set"
  type        = number
  default     = 0
}
