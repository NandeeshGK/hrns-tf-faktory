variable "create_project" {
  type    = bool
  default = true
}

variable "org_id" {
  type = string
}

variable "project_id" {
  type = string
}

variable "plan_stage_template_ref" {
  type = string
}

variable "plan_stage_template_version" {
  type = string
}

variable "apply_stage_template_ref" {
  type = string
}

variable "apply_stage_template_version" {
  type = string
}

variable "destroy_stage_template_ref" {
  type = string
}

variable "destroy_stage_template_version" {
  type = string
}

variable "drift_stage_template_ref" {
  type = string
}

variable "drift_stage_template_version" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ---------------------------------------------------------------------------
# ECS service / infrastructure variables
# ---------------------------------------------------------------------------
variable "ecs_service_id" {
  type        = string
  description = "Identifier of the ECS service."
  default     = "ecs_service"
}

variable "ecs_service_name" {
  type        = string
  description = "Display name of the ECS service."
  default     = "ECS Service"
}

variable "ecs_aws_connector_ref" {
  type        = string
  description = "Harness AWS connector reference used by the ECS infrastructure (e.g. account.myAwsConnector)."
}

variable "ecs_region" {
  type        = string
  description = "AWS region for the ECS clusters."
  default     = "us-east-1"
}

variable "ecs_default_cluster" {
  type        = string
  description = "Fallback ECS cluster name when a per-environment cluster is not provided."
  default     = ""
}

variable "ecs_clusters" {
  type        = map(string)
  description = "Per-environment ECS cluster names, keyed by environment identifier (dev, testing, stage, prod)."
  default     = {}
}

variable "ecs_cpu_overrides" {
  type        = map(string)
  description = "Per-environment CPU override values, keyed by environment identifier."
  default     = {}
}

variable "ecs_memory_overrides" {
  type        = map(string)
  description = "Per-environment memory override values, keyed by environment identifier."
  default     = {}
}

