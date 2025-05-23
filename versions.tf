terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }

  # S3 backend configuration - aligned with local deployment
  backend "s3" {
    bucket         = "synepho-terraform-state"
    key            = "synepho-com/terraform.tfstate" # Same as local
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks" # Added for state locking
  }
}
