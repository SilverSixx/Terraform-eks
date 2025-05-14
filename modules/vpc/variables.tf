# ./modules/vpc/variables.tf (Illustrative - define your variables here)
variable "create_vpc" {
  description = "Set to true to create a new VPC, false to use an existing one."
  type        = bool
  default     = true
}

variable "existing_vpc_id" {
  description = "The ID of an existing VPC to use when create_vpc is false."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC. Used if create_vpc is true."
  type        = string
  default     = "10.0.0.0/16" # Example default
}

variable "cluster_name" {
  description = "Name of the EKS cluster, used for tagging and naming resources."
  type        = string
}

variable "availability_zones" {
  description = "A list of availability zones for deploying subnets."
  type        = list(string)
}

variable "manage_public_subnet" {
  description = "Set to true to create a new public subnet, false to use an existing one. If creating, it will be placed in the first AZ from availability_zones."
  type        = bool
  default     = true
}

variable "existing_public_subnet_id" {
  description = "ID of an existing public subnet. Required if manage_public_subnet is false."
  type        = string
  default     = null
}

variable "public_subnet_cidr_in" {
  description = "CIDR block for the public subnet. If empty and manage_public_subnet is true, it will be calculated."
  type        = string
  default     = null
}

variable "manage_private_subnets" {
  description = "Set to true to create new private subnets, false to use existing ones."
  type        = bool
  default     = true
}

variable "existing_private_subnet_ids" {
  description = "List of IDs of existing private subnets. Used if manage_private_subnets is false."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs_in" {
  description = "List of CIDR blocks for private subnets. If empty and manage_private_subnets is true, they will be calculated."
  type        = list(string)
  default     = []
}

variable "create_nat_gateway" {
  description = "Set to true to create a new NAT Gateway. Set to false if enable_nat_gateway is true but you want to use an existing NAT Gateway."
  type        = bool
  default     = true
}

variable "existing_nat_gateway_id" {
  description = "The ID of an existing NAT Gateway to use. Required if enable_nat_gateway is true and create_nat_gateway is false."
  type        = string
  default     = null
}

variable "manage_igw" {
  description = "Set to true to manage the Internet Gateway. If create_vpc is true, an IGW will be created. If create_vpc is false, it will look for an existing IGW."
  type        = bool
  default     = true
}

variable "existing_igw_id" {
  description = "The ID of an existing Internet Gateway. If not provided and manage_igw is true and create_vpc is false, the module will try to discover it."
  type        = string
  default     = null
}

variable "manage_route_tables" {
  description = "Set to true to create and manage route tables and associations."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to created resources."
  type        = map(string)
  default     = {}
}