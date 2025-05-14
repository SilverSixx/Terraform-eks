# --- Internet Gateway ---
locals {
  igw_id = var.manage_igw ? (
    var.create_vpc ? aws_internet_gateway.this[0].id : (
      var.existing_igw_id != null ? var.existing_igw_id : (
        length(data.aws_internet_gateway.existing_igw) > 0 ? data.aws_internet_gateway.existing_igw[0].id : null
      )
    )
  ) : null
}

resource "aws_internet_gateway" "this" {
  count = var.create_vpc && var.manage_igw ? 1 : 0

  vpc_id = aws_vpc.this[0].id # Only if creating VPC

  tags = merge(
    local.common_tags,
    {
      Name = "${var.cluster_name}-igw"
    }
  )
}

data "aws_internet_gateway" "existing_igw" {
  count = !var.create_vpc && !var.manage_igw && var.existing_igw_id == null ? 1 : 0 # Discover if not creating VPC and no specific IGW ID given
  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc_id]
  }
}
