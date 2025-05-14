###############################################
# modules/eks/main.tf
###############################################

locals {
  cluster_name = var.cluster_name
  
  # Default capacity values based on environment
  node_groups_defaults = {
    DEV = {
      desired_size = 1
      min_size     = 0
      max_size     = 5
    }
    UAT = {
      desired_size = 1
      min_size     = 0
      max_size     = 7
    }
    PROD = {
      desired_size = 3
      min_size     = 2
      max_size     = 10
    }
  }

  # Merge environment defaults with user-provided values
  node_group_defaults = merge(
    local.node_groups_defaults[var.environment],
    var.node_group_defaults
  )

  # Common tags to be assigned to all resources
  common_tags = merge(
    var.tags,
    {
      "Environment"                             = var.environment
      "terraform-managed"                       = "true"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  # Determine which subnets to use for the EKS cluster
  cluster_subnet_ids = var.cluster_endpoint_public_access_cidrs != null ? concat( 
    [for subnet in module.vpc.private_subnets : subnet.id],
    var.include_public_subnet_in_cluster ? [module.vpc.public_subnet.id] : []
  ) : [for subnet in module.vpc.private_subnets : subnet.id]
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster" {
  name = "${local.cluster_name}-eks-cluster-role"
  
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

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = local.cluster_subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = concat(
      [aws_security_group.cluster.id],
      var.additional_cluster_security_group_ids
    )
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  tags = merge(
    local.common_tags,
    var.cluster_tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]
}

# EKS Cluster Security Group
resource "aws_security_group" "cluster" {
  name        = "${local.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-cluster-sg"
    }
  )
}

# EKS Node Groups IAM Role
resource "aws_iam_role" "node_groups" {
  name = "${local.cluster_name}-eks-node-group-role"
  
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

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "node_groups_eks_worker_node_policy" {
  role       = aws_iam_role.node_groups.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_groups_eks_cni_policy" {
  role       = aws_iam_role.node_groups.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_groups_ecr_read_only" {
  role       = aws_iam_role.node_groups.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Apply additional policies if provided
resource "aws_iam_role_policy_attachment" "node_groups_additional" {
  for_each   = toset(var.node_groups_additional_policies)
  role       = aws_iam_role.node_groups.name
  policy_arn = each.value
}

# Node groups security group
resource "aws_security_group" "node_groups" {
  name        = "${local.cluster_name}-node-groups-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-node-groups-sg"
    }
  )
}

# Allow workers to communicate with the cluster API Server
resource "aws_security_group_rule" "node_groups_to_cluster" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node_groups.id
  to_port                  = 443
  type                     = "ingress"
}

# Allow cluster API Server to communicate with the worker nodes
resource "aws_security_group_rule" "cluster_to_node_groups" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node_groups.id
  source_security_group_id = aws_security_group.cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

# Allow nodes to communicate with each other
resource "aws_security_group_rule" "node_groups_self" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.node_groups.id
  source_security_group_id = aws_security_group.node_groups.id
  to_port                  = 65535
  type                     = "ingress"
}

# Create EKS Node Groups
resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  version         = lookup(each.value, "kubernetes_version", var.kubernetes_version)
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node_groups.arn

  subnet_ids = [for subnet in module.vpc.private_subnets : subnet.id]

  ami_type        = lookup(each.value, "ami_type", "AL2_x86_64")
  capacity_type   = lookup(each.value, "capacity_type", "ON_DEMAND")
  instance_types  = lookup(each.value, "instance_types", [var.default_instance_type])
  disk_size       = lookup(each.value, "disk_size", 50)

  scaling_config {
    desired_size = lookup(each.value, "desired_size", local.node_group_defaults.desired_size)
    min_size     = lookup(each.value, "min_size", local.node_group_defaults.min_size)
    max_size     = lookup(each.value, "max_size", local.node_group_defaults.max_size)
  }

  update_config {
    max_unavailable = lookup(each.value, "max_unavailable", 1)
  }

  labels = merge(
    lookup(each.value, "labels", {}),
    {
      "node-group" = each.key
    }
  )

  # Taints can be specified for specialized workloads
  dynamic "taint" {
    for_each = lookup(each.value, "taints", [])
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Remote access allows SSH access to the nodes if needed
  dynamic "remote_access" {
    for_each = lookup(each.value, "ec2_ssh_key", null) != null ? [1] : []
    content {
      ec2_ssh_key               = each.value.ec2_ssh_key
      source_security_group_ids = lookup(each.value, "source_security_group_ids", [])
    }
  }

  tags = merge(
    local.common_tags,
    lookup(each.value, "tags", {}),
    {
      Name = "${local.cluster_name}-${each.key}"
    }
  )

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_groups_eks_worker_node_policy,
    aws_iam_role_policy_attachment.node_groups_eks_cni_policy,
    aws_iam_role_policy_attachment.node_groups_ecr_read_only,
    aws_iam_role_policy_attachment.node_groups_additional
  ]
}

# Fargate profile (optional)
# resource "aws_eks_fargate_profile" "this" {
#   for_each = var.fargate_profiles

#   cluster_name           = aws_eks_cluster.this.name
#   fargate_profile_name   = each.key
#   pod_execution_role_arn = aws_iam_role.fargate_profile[0].arn
#   subnet_ids             = [for subnet in module.vpc.private_subnets : subnet.id]

#   dynamic "selector" {
#     for_each = each.value.selectors
#     content {
#       namespace = selector.value.namespace
#       labels    = lookup(selector.value, "labels", {})
#     }
#   }

#   tags = merge(
#     local.common_tags,
#     lookup(each.value, "tags", {}),
#     {
#       Name = "${local.cluster_name}-fargate-${each.key}"
#     }
#   )
# }

# # IAM Role for Fargate Profile
# resource "aws_iam_role" "fargate_profile" {
#   count = length(var.fargate_profiles) > 0 ? 1 : 0
  
#   name = "${local.cluster_name}-eks-fargate-profile-role"
  
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = "sts:AssumeRole"
#       Principal = {
#         Service = "eks-fargate-pods.amazonaws.com"
#       }
#     }]
#   })

#   tags = local.common_tags
# }

# resource "aws_iam_role_policy_attachment" "fargate_profile" {
#   count      = length(var.fargate_profiles) > 0 ? 1 : 0
#   role       = aws_iam_role.fargate_profile[0].name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
# }