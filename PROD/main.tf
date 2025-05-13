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

module "eks" {
  source        = "../modules/eks"

  env           = var.env
  cluster_name  = var.cluster_name
  eks_version   = var.eks_version
  instance_type = var.instance_type
  vpc_cidr      = var.vpc_cidr
  vpc_id        = var.vpc_id
  zone1         = var.zone1
  zone2         = var.zone2
  zone3         = var.zone3
}
