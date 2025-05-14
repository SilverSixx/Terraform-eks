module "vpc" {
  source = ".." 

  cluster_name        = "my-eks-cluster"
  create_vpc      = true 
  vpc_cidr        = "10.20.0.0/16"

  availability_zones  = ["us-east-1a", "us-east-1b"] 

  manage_public_subnet      = false 
  existing_public_subnet_id = "subnet-0pubabcdef12345" 

  manage_private_subnets    = true  

  create_nat_gateway = true 

  manage_igw          = true 
  manage_route_tables = true 

  tags = {
    Environment = "staging"
    UseCase     = "eks-mixed-subnets"
  }
}