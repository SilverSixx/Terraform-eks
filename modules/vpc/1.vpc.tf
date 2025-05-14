# ./modules/vpc/main.tf
locals {
  vpc_id = var.create_vpc ? aws_vpc.this[0].id : var.existing_vpc_id

  # CIDR Calculations
  calculated_public_subnet_cidr = var.manage_public_subnet && var.public_subnet_cidr_in == null ? cidrsubnet(var.vpc_cidr, 4, length(var.availability_zones)) : var.public_subnet_cidr_in # Ensure this is unique

  calculated_private_subnet_cidrs = var.manage_private_subnets && length(var.private_subnet_cidrs_in) == 0 ? [
    for i in range(length(var.availability_zones)) : cidrsubnet(var.vpc_cidr, 4, i) # Adjust newbits and netnum as needed
  ] : var.private_subnet_cidrs_in


  # Effective Subnet IDs
  public_subnet_id = var.manage_public_subnet ? (length(aws_subnet.public) > 0 ? aws_subnet.public[0].id : null) : var.existing_public_subnet_id

  private_subnet_ids = var.manage_private_subnets ? [for subnet in aws_subnet.private : subnet.id] : var.existing_private_subnet_ids

  common_tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  igw_id = var.manage_igw ? (
    var.create_vpc ? (length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null) : (
      var.existing_igw_id != null ? var.existing_igw_id : (
        length(data.aws_internet_gateway.existing_igw) > 0 ? data.aws_internet_gateway.existing_igw[0].id : null
      )
    )
  ) : null

  # Effective NAT Gateway ID for routing
  nat_gateway_id_for_routes = var.create_nat_gateway ? (length(aws_nat_gateway.this) > 0 ? aws_nat_gateway.this[0].id : null) : var.existing_nat_gateway_id
}

# --- VPC ---
resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-vpc"
    }
  )
}

data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  id    = var.existing_vpc_id
}