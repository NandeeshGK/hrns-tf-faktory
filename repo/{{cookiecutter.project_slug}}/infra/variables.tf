variable "application_name" {
  type = string
  default = "{{ cookiecutter.project_slug }}"
}

variable "environment" {
  type = string
}
