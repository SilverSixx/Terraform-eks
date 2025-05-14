module "vpc" {
  source = ".." 

  create_vpc      = false 
  existing_vpc_id = "vpc-0abcdef1234567890" 
  cluster_name    = ""         

  manage_public_subnet      = false
  existing_public_subnet_id = "subnet-0pub123" 

  manage_private_subnets    = false
  existing_private_subnet_ids = ["subnet-0priv123", "subnet-0priv456"] 
  
  # Availability Zones:
  # - May still be used by the module for other AZ-specific data sources or resource naming if applicable.
  # - If creating resources that require AZs (not the case here for subnets), these would be used.
  availability_zones = ["us-east-1a", "us-east-1b"] # For resource naming consistency if nothing else

 # Indicates that NAT functionality is expected/used by resources depending on this VPC.
  create_nat_gateway      = false 
  existing_nat_gateway_id = "nat-0123abcdef" 

  # Do not manage the Internet Gateway.
  manage_igw = false
  existing_igw_id = "igw-0123abcdef" # ID of your existing Internet Gateway

  # Do not manage any route tables or their associations.
  manage_route_tables = false

  tags = {
    Service = "shared"
  }
}