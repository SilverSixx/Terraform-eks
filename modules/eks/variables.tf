variable "cluster_name" {
  type = string
}

variable "eks_version" {
  type    = string
  default = "1.30"
}

variable "zone1" {
  type = string
}

variable "zone2" {
  type = string
}

variable "zone3" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "region" {
  type = string
}


