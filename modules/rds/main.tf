##############################################################################

##############################################################################

# Define the AWS region and availability zones

locals {
  # Base VPC CIDR block
  vpc_cidr = var.vpc_cidr

  # Generate subnet CIDRs for each AZ
  zone1_cidr = cidrsubnet(local.vpc_cidr, 4, 1)
  zone2_cidr = cidrsubnet(local.vpc_cidr, 4, 2)
  zone3_cidr = cidrsubnet(local.vpc_cidr, 4, 3)
}


resource "aws_subnet" "private_zone1" {
  vpc_id                  = var.vpc_id
  cidr_block              = local.zone1_cidr
  availability_zone       = var.zone1
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.env}-private-${var.zone1}"
  }
}

resource "aws_subnet" "private_zone2" {
  vpc_id                  = var.vpc_id
  cidr_block              = local.zone2_cidr
  availability_zone       = var.zone2
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.env}-private-${var.zone3}"
  }
}

resource "aws_subnet" "private_zone3" {
  vpc_id                  = var.vpc_id
  cidr_block              = local.zone3_cidr
  availability_zone       = var.zone3
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.env}-private-${var.zone3}"
  }
}

