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

# Create IAM role for EKS cluster
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
  name     = "${var.env}-${var.cluster_name}"
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
  name = "${var.env}-${var.cluster_name}-eks-nodes"
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
    data.aws_subnet.private_zone1.id,
    data.aws_subnet.private_zone2.id,
    data.aws_subnet.private_zone3.id
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = [var.instance_type]

  scaling_config {
    desired_size = var.cluster_name == "dev" ? 1 : 3
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
