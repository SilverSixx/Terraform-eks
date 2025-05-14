# ./modules/vpc/outputs.tf

output "vpc_id" {
  description = "The ID of the VPC."
  value       = local.vpc_id
}

output "public_subnet_id" {
  description = "The ID of the public subnet (either created or existing)."
  value       = local.public_subnet_id
}

output "public_subnet_cidr" {
  description = "The CIDR block of the public subnet. Value is from input if using existing, or calculated/input if managed."
  value       = var.manage_public_subnet ? local.calculated_public_subnet_cidr : null # Or you might want to data source the existing subnet to get its CIDR
}

output "private_subnet_ids" {
  description = "A list of IDs of the private subnets (either created or existing)."
  value       = local.private_subnet_ids
}

output "private_subnet_cidrs" {
  description = "The CIDR blocks of the private subnets. Value is from input if using existing, or calculated/input if managed."
  value       = var.manage_private_subnets ? local.calculated_private_subnet_cidrs : null # Similar to public, could data source existing ones
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway, if enabled (could be new or existing)."
  value       = local.nat_gateway_id_for_routes # This local var holds the effective NGW ID
}

output "nat_gateway_eip" {
  description = "The public IP of the NAT Gateway's EIP, if a new NAT Gateway was created by this module."
  value       = var.create_nat_gateway && length(aws_eip.nat) > 0 ? aws_eip.nat[0].public_ip : null
}

output "igw_id" {
  description = "The ID of the Internet Gateway, if managed or discovered."
  value       = local.igw_id
}

output "public_route_table_id" {
  description = "The ID of the public route table, if managed."
  value       = length(aws_route_table.public) > 0 ? aws_route_table.public[0].id : null
}

output "private_route_table_id" {
  description = "The ID of the private route table, if managed."
  value       = length(aws_route_table.private) > 0 ? aws_route_table.private[0].id : null
}