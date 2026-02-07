output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "VPC CIDR block"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List of private subnet IDs"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.main.id
  description = "Internet Gateway ID"
}

output "nat_gateway_ids" {
  value       = aws_nat_gateway.main[*].id
  description = "List of NAT Gateway IDs"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public route table ID"
}

output "private_route_table_ids" {
  value       = aws_route_table.private[*].id
  description = "List of private route table IDs"
}

output "default_security_group_id" {
  value       = aws_security_group.default.id
  description = "Default security group ID"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "ALB security group ID"
}

output "db_subnet_ids" {
  value       = aws_subnet.database[*].id
  description = "List of database subnet IDs"
}

output "management_subnet_ids" {
  value       = aws_subnet.management[*].id
  description = "List of management subnet IDs"
}

output "db_route_table_ids" {
  value       = aws_route_table.database[*].id
  description = "List of database route table IDs"
}

output "management_route_table_ids" {
  value       = aws_route_table.management[*].id
  description = "List of management route table IDs"
}

output "database_security_group_id" {
  value       = aws_security_group.database.id
  description = "Database security group ID"
}

output "management_security_group_id" {
  value       = aws_security_group.management.id
  description = "Management security group ID"
}

output "db_subnet_group_name" {
  value       = aws_db_subnet_group.main.name
  description = "RDS DB Subnet Group name"
}
