# modules/eks/variables.tf

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment (DEV, UAT, PROD)"
  type        = string
  validation {
    condition     = contains(["DEV", "UAT", "PROD"], var.environment)
    error_message = "Valid values for environment are: DEV, UAT, PROD"
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones where subnets should be created"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = null
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.32"
}

variable "default_instance_type" {
  description = "Default EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_group_defaults" {
  description = "Default values for node groups that override the environment defaults"
  type        = map(any)
  default     = {}
}

variable "node_groups" {
  description = "Map of EKS node group configurations"
  type        = map(any)
  default = {
    general = {
      instance_types = ["t3.medium"]
      labels = {
        role = "general"
      }
    }
  }
}

variable "node_groups_additional_policies" {
  description = "List of additional policy ARNs to attach to node groups"
  type        = list(string)
  default     = []
}

# variable "fargate_profiles" {
#   description = "Map of EKS Fargate Profile configurations"
#   type        = map(any)
#   default     = {}
# }

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_tags" {
  description = "A map of additional tags to add to the EKS cluster"
  type        = map(string)
  default     = {}
}

variable "cluster_endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "include_public_subnet_in_cluster" {
  description = "Whether to include the public subnet in the EKS cluster"
  type        = bool
  default     = false
}

variable "enabled_cluster_log_types" {
  description = "A list of the desired control plane logs to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster"
  type        = string
  default     = "API"
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Whether to enable bootstrap cluster creator admin permissions"
  type        = bool
  default     = true
}

variable "additional_cluster_security_group_ids" {
  description = "List of additional security group IDs to attach to the cluster"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt EKS secrets"
  type        = string
  default     = null
}