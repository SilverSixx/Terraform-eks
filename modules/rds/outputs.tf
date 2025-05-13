output "db_instance_identifier" {
  description = "The DB instance identifier"
  value = aws_db_instance.rds[0].db_instance_identifier
  
}

output "db_instance_endpoint" {
  description = "The DB instance endpoint"
  value = aws_db_instance.rds[0].endpoint
}

output "db_instance_port" {
  description = "The DB instance port"
  value = aws_db_instance.rds[0].port
}

output "db_instance_arn" {
  description = "The DB instance ARN"
  value = aws_db_instance.rds[0].arn
}
