output "repository_url" {
  value       = aws_ecr_repository.main.repository_url
  description = "The URL of the ECR repository"
}

output "repository_arn" {
  value       = aws_ecr_repository.main.arn
  description = "The ARN of the ECR repository"
}

output "repository_name" {
  value       = aws_ecr_repository.main.name
  description = "The name of the ECR repository"
}

output "repository_registry_id" {
  value       = aws_ecr_repository.main.registry_id
  description = "The registry ID of the ECR repository"
}

output "lifecycle_policy_text" {
  value       = var.enable_lifecycle_policy ? aws_ecr_lifecycle_policy.main[0].policy : null
  description = "The lifecycle policy text"
}
