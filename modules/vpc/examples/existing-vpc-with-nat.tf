module "vpc" {
  source = ".." # Or your actual module path e.g., "./modules/vpc" or "github.com/your-org/your-module//vpc"

  create_vpc      = false 
  existing_vpc_id = "vpc-0abcdef1234567890" 
  cluster_name    = "my-eks-cluster"         

  manage_public_subnet      = false
  existing_public_subnet_id = "subnet-0pub123" # ID of your existing public subnet

  manage_private_subnets    = false
  existing_private_subnet_ids = ["subnet-0priv123", "subnet-0priv456"] 

  availability_zones = ["us-east-1a", "us-east-1b"]

  create_nat_gateway = true 

  manage_igw = false
  existing_igw_id = "igw-0123abcdef" # ID of your existing Internet Gateway

  manage_route_tables = true

  tags = {
    Application = "legacy-app"
    Orchestrator = "Terraform"
  }
}