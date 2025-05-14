# Additional improvements to the main EKS module

# Add AWS OIDC provider for EKS
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_name}-eks-irsa"
    }
  )
}

# Add additional variables to support this
variable "enable_irsa" {
  description = "Whether to enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

# Add CloudWatch Log Group for EKS cluster logs
resource "aws_cloudwatch_log_group" "this" {
  count = length(var.enabled_cluster_log_types) > 0 ? 1 : 0

  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_in_days
  kms_key_id        = var.cluster_log_kms_key_id

  tags = local.common_tags
}

variable "cluster_log_retention_in_days" {
  description = "Number of days to retain EKS cluster logs"
  type        = number
  default     = 90
}

variable "cluster_log_kms_key_id" {
  description = "KMS key ID to encrypt EKS cluster logs"
  type        = string
  default     = null
}

# Add additional control over node group taints
variable "node_group_taints" {
  description = "Map of node group taints"
  type        = map(list(object({
    key    = string
    value  = string
    effect = string
  })))
  default     = {}
}

# Add support for launch templates to enable more customization
resource "aws_launch_template" "this" {
  for_each = { for k, v in var.node_groups : k => v if lookup(v, "use_custom_launch_template", false) }

  name_prefix = "${local.cluster_name}-${each.key}-"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = lookup(each.value, "disk_size", 50)
      volume_type           = lookup(each.value, "volume_type", "gp3")
      delete_on_termination = true
      encrypted             = lookup(each.value, "encrypted", true)
      kms_key_id            = lookup(each.value, "kms_key_id", null)
      iops                  = lookup(each.value, "volume_type", "gp3") == "gp3" ? lookup(each.value, "iops", 3000) : null
      throughput            = lookup(each.value, "volume_type", "gp3") == "gp3" ? lookup(each.value, "throughput", 125) : null
    }
  }

  monitoring {
    enabled = lookup(each.value, "enable_monitoring", true)
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      lookup(each.value, "tags", {}),
      {
        Name = "${local.cluster_name}-${each.key}-node"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    
    tags = merge(
      local.common_tags,
      lookup(each.value, "tags", {}),
      {
        Name = "${local.cluster_name}-${each.key}-volume"
      }
    )
  }

  user_data = base64encode(templatefile("${path.module}/templates/userdata.tpl", {
    cluster_name         = aws_eks_cluster.this.name
    cluster_endpoint     = aws_eks_cluster.this.endpoint
    bootstrap_extra_args = lookup(each.value, "bootstrap_extra_args", "")
    custom_userdata      = lookup(each.value, "custom_userdata", "")
  }))

  lifecycle {
    create_before_destroy = true
  }
}

# Update node_group resource to use launch template when specified
resource "aws_eks_node_group" "with_launch_template" {
  for_each = { for k, v in var.node_groups : k => v if lookup(v, "use_custom_launch_template", false) }

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node_groups.arn

  subnet_ids = [for subnet in module.vpc.private_subnets : subnet.id]

  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")
  
  launch_template {
    id      = aws_launch_template.this[each.key].id
    version = aws_launch_template.this[each.key].latest_version
  }

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

  dynamic "taint" {
    for_each = lookup(each.value, "taints", [])
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
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