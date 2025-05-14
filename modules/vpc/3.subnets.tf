# --- Subnets ---
# Public Subnet
resource "aws_subnet" "public" {
  # Create if manage_public_subnet is true AND there's at least one AZ specified for it
  count = var.manage_public_subnet && length(var.availability_zones) > 0 ? 1 : 0

  vpc_id                  = local.vpc_id
  cidr_block              = local.calculated_public_subnet_cidr
  availability_zone       = var.availability_zones[0] # Places in the first AZ
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name                                      = "${var.cluster_name}-public-${var.availability_zones[0]}"
      "kubernetes.io/role/elb"                  = "1"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count = var.manage_private_subnets ? length(var.availability_zones) : 0

  vpc_id            = local.vpc_id
  cidr_block        = local.calculated_private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    local.common_tags,
    {
      Name                                      = "${var.cluster_name}-private-${var.availability_zones[count.index]}"
      "kubernetes.io/role/internal-elb"         = "1"
    }
  )
}
