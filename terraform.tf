terraform {
  required_version = ">= 1.5.0"

  required_providers {
    harness = {
      source  = "harness/harness"
      version = ">= 0.43.6"
    }
  }

  # Recommended: replace with your remote backend (e.g. S3 + DynamoDB lock or
  # the cloudeng-platform IaCM-managed Terraform Cloud workspace).
  # backend "s3" {
  #   bucket         = "cloudeng-tf-state"
  #   key            = "harness/iacm-baseline.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "cloudeng-tf-locks"
  #   encrypt        = true
  # }
}
