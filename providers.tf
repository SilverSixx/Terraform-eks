provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source    = "hashicorp/aws"
      version   = "~> 5.49"
    }
  }
}
