# --- Route Tables & Associations ---
# Public Route Table
resource "aws_route_table" "public" {
  count = var.manage_route_tables && local.igw_id != null && local.public_subnet_id != null ? 1 : 0

  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = local.igw_id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-public-rt"
    }
  )
}

resource "aws_route_table_association" "public" {
  # Associate if: managing RTs, public RT was created, AND a public subnet ID is available
  count = var.manage_route_tables && length(aws_route_table.public) > 0 && local.public_subnet_id != null ? 1 : 0

  subnet_id      = local.public_subnet_id
  route_table_id = aws_route_table.public[0].id
}

# Private Route Table
resource "aws_route_table" "private" {
  # Create if: managing RTs, NGW is enabled, AND a NGW ID is available (either created or existing)
  count = var.manage_route_tables && local.nat_gateway_id_for_routes != null ? 1 : 0

  vpc_id = local.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = local.nat_gateway_id_for_routes
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-private-rt"
    }
  )
}

resource "aws_route_table_association" "private" {
  # Associate if: managing RTs, private RT was created, AND private subnet IDs are available
  count = var.manage_route_tables && length(aws_route_table.private) > 0 && length(local.private_subnet_ids) > 0 ? length(local.private_subnet_ids) : 0

  subnet_id      = local.private_subnet_ids[count.index]
  route_table_id = aws_route_table.private[0].id
}