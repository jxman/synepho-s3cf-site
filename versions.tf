terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }

  # S3 backend configuration
  backend "s3" {
    bucket  = "synepho-terraform-state" # Replace with your state bucket name
    key     = "synepho-com/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    # Optional: If you want state locking (recommended)
    # dynamodb_table = "terraform-locks"
  }
}
