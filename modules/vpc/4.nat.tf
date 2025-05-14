# --- Data Source for Existing NAT Gateway ---
data "aws_nat_gateway" "existing_nat" {
  count = !var.create_nat_gateway && var.existing_nat_gateway_id == null && local.public_subnet_id != null ? 1 : 0

  subnet_id = local.public_subnet_id

  depends_on = [aws_subnet.public, aws_internet_gateway.this, data.aws_internet_gateway.existing_igw]
}

# --- NAT Gateway & EIP ---
resource "aws_eip" "nat" {
  count = var.create_nat_gateway && local.public_subnet_id != null ? 1 : 0

  domain = "vpc"
  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "this" {
  count = var.create_nat_gateway && length(aws_eip.nat) > 0 ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = local.public_subnet_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-nat"
    }
  )
  depends_on = [aws_internet_gateway.this, data.aws_internet_gateway.existing_igw]
}