terraform {
  required_version = ">= 1.0.0"

  required_providers {
    harness = {
      source  = "harness/harness"
      version = ">= 0.42.0"
    }
  }
}
