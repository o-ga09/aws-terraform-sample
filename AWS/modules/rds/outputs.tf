output "cluster_id" {
  value       = aws_rds_cluster.main.id
  description = "Aurora Cluster ID"
}

output "cluster_arn" {
  value       = aws_rds_cluster.main.arn
  description = "Aurora Cluster ARN"
}

output "cluster_endpoint" {
  value       = aws_rds_cluster.main.endpoint
  description = "Aurora Cluster Endpoint"
}

output "cluster_reader_endpoint" {
  value       = aws_rds_cluster.main.reader_endpoint
  description = "Aurora Cluster Reader Endpoint"
}

output "cluster_resource_id" {
  value       = aws_rds_cluster.main.cluster_resource_id
  description = "Aurora Cluster Resource ID"
}

output "database_name" {
  value       = aws_rds_cluster.main.database_name
  description = "Name of the default database"
}

output "master_username" {
  value       = aws_rds_cluster.main.master_username
  description = "Master username"
  sensitive   = true
}

output "port" {
  value       = aws_rds_cluster.main.port
  description = "Database port"
}

output "instance_endpoints" {
  value       = concat(aws_rds_cluster_instance.main[*].endpoint, aws_rds_cluster_instance.serverless[*].endpoint)
  description = "Instance endpoints"
}

output "db_subnet_group_id" {
  value       = aws_db_subnet_group.main.id
  description = "DB Subnet Group ID"
}

output "parameter_group_id" {
  value       = aws_rds_cluster_parameter_group.main.id
  description = "Cluster Parameter Group ID"
}

output "log_group_names" {
  value       = { for log_type, log_group in aws_cloudwatch_log_group.aurora : log_type => log_group.name }
  description = "CloudWatch Log Group names by type"
}

output "is_serverless" {
  value       = var.is_serverless
  description = "Whether the cluster is Aurora Serverless v2"
}

output "http_endpoint" {
  value       = var.is_serverless ? aws_rds_cluster.main.endpoint : null
  description = "HTTP endpoint for Data API (Serverless only)"
}
