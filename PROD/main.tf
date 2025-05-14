# should check the networking infras with the linkedin link when create new subnets
provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49"
    }
  }

  backend "s3" {
    bucket         = "tf-states"
    key            = "eks/prod/terraform.tfstate"
    region         = "ap-southeast-1"
    use_lock_table = true
    encrypt        = true
  }
}
