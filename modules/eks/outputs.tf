# modules/eks/outputs.tf

output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "ID of the EKS cluster security group"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = aws_security_group.node_groups.id
}

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading https://)"
  value       = try(replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", ""), null)
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if IRSA is enabled"
  value       = try(aws_iam_openid_connect_provider.this[0].arn, null)
}

output "cluster_version" {
  description = "The Kubernetes version for the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.eks_cluster.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.eks_cluster.arn
}

output "node_groups" {
  description = "Map of EKS managed node groups created and their attributes"
  value       = aws_eks_node_group.this
}

output "fargate_profiles" {
  description = "Map of EKS Fargate Profiles created and their attributes"
  value       = aws_eks_fargate_profile.this
}

output "kubeconfig" {
  description = "kubectl config that can be used to connect to the EKS cluster"
  value = templatefile("${path.module}/templates/kubeconfig.tpl", {
    cluster_name                      = aws_eks_cluster.this.name
    cluster_endpoint                  = aws_eks_cluster.this.endpoint
    cluster_certificate_authority_data = aws_eks_cluster.this.certificate_authority[0].data
  })
  sensitive = true
}