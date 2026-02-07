output "cluster_id" {
  value       = aws_ecs_cluster.main.id
  description = "ECS Cluster ID"
}

output "cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "ECS Cluster Name"
}

output "service_id" {
  value       = aws_ecs_service.main.id
  description = "ECS Service ID"
}

output "service_name" {
  value       = aws_ecs_service.main.name
  description = "ECS Service Name"
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.main.arn
  description = "ECS Task Definition ARN"
}

output "task_definition_family" {
  value       = aws_ecs_task_definition.main.family
  description = "ECS Task Definition Family"
}

output "task_execution_role_arn" {
  value       = aws_iam_role.ecs_task_execution_role.arn
  description = "ARN of the ECS Task Execution Role"
}

output "task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "ARN of the ECS Task Role"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.ecs.name
  description = "CloudWatch Log Group Name for ECS"
}

output "log_group_arn" {
  value       = aws_cloudwatch_log_group.ecs.arn
  description = "CloudWatch Log Group ARN for ECS"
}
