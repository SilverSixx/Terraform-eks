##############################################################################
# EKS Cluster Module
# This module creates an EKS cluster with the specified configuration.

# It includes the creation of IAM roles, node groups, and VPC subnets.
# The module is designed to be reusable and configurable through input variables.
##############################################################################

# Define the AWS region and availability zones

locals {
  # Base VPC CIDR block
  vpc_cidr = var.vpc_cidr

  # Generate subnet CIDRs for each AZ
  zone1_cidr = cidrsubnet(local.vpc_cidr, 4, 5)
  zone2_cidr = cidrsubnet(local.vpc_cidr, 4, 6)
  zone3_cidr = cidrsubnet(local.vpc_cidr, 4, 7)
  public_zone_cidr = cidrsubnet(local.vpc_cidr, 4, 8)
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = var.vpc_id
  cidr_block              = local.public_zone_cidr
  availability_zone       = var.zone1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-${var.zone1}"
    "kubernetes.io/role/elb"  = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_subnet" "private_zone1" {
  vpc_id                  = var.vpc_id
  cidr_block              = local.zone1_cidr
  availability_zone       = var.zone1

  tags = {
    Name = "${var.cluster_name}-private-${var.zone1}"
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

}

resource "aws_subnet" "private_zone2" {
  vpc_id                  = var.vpc_id
  cidr_block              = local.zone2_cidr
  availability_zone       = var.zone2
  
  tags = {
    Name = "${var.cluster_name}-private-${var.zone2}"
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_subnet" "private_zone3" {
  vpc_id                  = var.vpc_id
  cidr_block              = local.zone3_cidr
  availability_zone       = var.zone3

  tags = {
    Name = "${var.cluster_name}-private-${var.zone3}"
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

data "aws_internet_gateway" "igw" {
  filter {
    name = "attachment.vpc-id"
    values  = [var.vpc_id]
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}-nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "${var.cluster_name}-nat"
  }

}

resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.cluster_name}-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.cluster_name}-private"
  }
}


resource "aws_route_table_association" "private_zone1" {
  subnet_id      = aws_subnet.private_zone1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_zone2" {
  subnet_id      = aws_subnet.private_zone2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_zone3" {
  subnet_id      = aws_subnet.private_zone3.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public_zone" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

# This role allows the EKS cluster to interact with AWS services
resource "aws_iam_role" "eks" {
  name = "${var.cluster_name}-eks-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "eks" {
  name     = "${var.cluster_name}"
  version  = var.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    subnet_ids = [
      aws_subnet.private_zone1.id,
      aws_subnet.private_zone2.id,
      aws_subnet.private_zone3.id
    ]
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks]
}

# Create IAM role for EKS nodes
# This role allows the EKS nodes to interact with AWS services
resource "aws_iam_role" "nodes" {
  name = "${var.cluster_name}-eks-nodes"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.eks.name
  version         = var.eks_version
  node_group_name = "general"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = [
    aws_subnet.private_zone1.id,
    aws_subnet.private_zone2.id,
    aws_subnet.private_zone3.id
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = [var.instance_type]

  scaling_config {
    desired_size = var.cluster_name == "DEV" ? 1 : 3
    min_size     = 0
    max_size     = 10
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only
  ]
}
