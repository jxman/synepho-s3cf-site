terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.30"
      configuration_aliases = [aws.west]
    }
  }
}
