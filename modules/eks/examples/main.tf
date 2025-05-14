# Example usage of the improved EKS module
provider "aws" {
  region = "us-east-1"
}

# Define different configurations for different environments
locals {
  environments = {
    DEV = {
      cluster_name    = "dev-cluster"
      instance_type   = "t3.medium"
      desired_nodes   = 1
      min_nodes       = 0
      max_nodes       = 5
    },
    UAT = {
      cluster_name    = "uat-cluster"
      instance_type   = "t3.large"
      desired_nodes   = 2
      min_nodes       = 1
      max_nodes       = 7
    },
    PROD = {
      cluster_name    = "prod-cluster"
      instance_type   = "m5.large"
      desired_nodes   = 3
      min_nodes       = 2
      max_nodes       = 10
    }
  }

  # Select environment based on workspace or parameter
  current_env = terraform.workspace == "default" ? "DEV" : upper(terraform.workspace)
  
  # Get config for current environment
  env_config = local.environments[local.current_env]
}

# Create EKS cluster
module "eks" {
  source = "./modules/eks"

  # Basic cluster configuration
  cluster_name  = local.env_config.cluster_name
  environment   = local.current_env
  vpc_id        = aws_vpc.main.id
  vpc_cidr      = aws_vpc.main.cidr_block
  
  # Use latest recommended EKS version
  kubernetes_version = "1.28"
  
  # Define availability zones
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Define node groups
  node_groups = {
    general = {
      instance_types = [local.env_config.instance_type]
      desired_size   = local.env_config.desired_nodes
      min_size       = local.env_config.min_nodes
      max_size       = local.env_config.max_nodes
      labels = {
        role = "general"
      }
    },
    # Example of a specialized node group with custom launch template
    compute = {
      use_custom_launch_template = true
      instance_types = ["c5.xlarge"]
      desired_size   = local.current_env == "PROD" ? 2 : 0
      min_size       = local.current_env == "PROD" ? 1 : 0
      max_size       = 5
      disk_size      = 100
      volume_type    = "gp3"
      iops           = 4000
      throughput     = 200
      labels = {
        role = "compute"
      }
      taints = [
        {
          key    = "workload"
          value  = "compute"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
  
  # Add policies for node groups if needed
  node_groups_additional_policies = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
  
  # Configure logging
  enabled_cluster_log_types = ["api", "audit"]
  cluster_log_retention_in_days = 30
  
  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true
  
  # Add tags for all resources
  tags = {
    Environment = local.current_env
    ManagedBy   = "Terraform"
    Project     = "EKS-Infrastructure"
  }
}

# Example usage of the VPC module with existing resources
module "vpc" {
  source = "../../vpc"

  create_vpc      = false 
  existing_vpc_id = "vpc-0abcdef1234567890" 
  cluster_name    = ""         

  manage_public_subnet      = false
  existing_public_subnet_id = "subnet-0pub123" 

  manage_private_subnets    = false
  existing_private_subnet_ids = ["subnet-0priv123", "subnet-0priv456"] 
  
  availability_zones = ["us-east-1a", "us-east-1b"] 

  create_nat_gateway      = false 
  existing_nat_gateway_id = "nat-0123abcdef" 

  # Do not manage the Internet Gateway.
  manage_igw = false
  existing_igw_id = "igw-0123abcdef"

  # Do not manage any route tables or their associations.
  manage_route_tables = false

  tags = {
    Service = "shared"
  }
}