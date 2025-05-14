module "vpc" {
  source = ".." # Or your module source

  cluster_name        = "my-eks-cluster"
  vpc_cidr            = "10.10.0.0/16"
  availability_zones  = ["us-west-2a", "us-west-2b", "us-west-2c"]
  # private_subnet_cidrs_in = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"] # Optional: provide specific CIDRs
  # public_subnet_cidr_in   = "10.10.100.0/24" # Optional

  tags = {
    Environment = "dev"
    Project     = "eks"
  }
}