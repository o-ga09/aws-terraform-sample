variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (development, staging, production)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where ALB will be deployed"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for ALB placement"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID for ALB"
}

variable "enable_https" {
  type        = bool
  description = "Enable HTTPS listener (requires certificate_arn)"
  default     = false
}

variable "certificate_arn" {
  type        = string
  description = "ARN of SSL/TLS certificate for HTTPS listener"
  default     = ""
}

variable "enable_deletion_protection" {
  type        = bool
  description = "Enable deletion protection for ALB"
  default     = false
}

variable "enable_access_logs" {
  type        = bool
  description = "Enable access logs for ALB"
  default     = false
}

variable "access_logs_s3_bucket" {
  type        = string
  description = "S3 bucket name for access logs"
  default     = ""
}

variable "access_logs_s3_prefix" {
  type        = string
  description = "S3 prefix for access logs"
  default     = ""
}

variable "idle_timeout" {
  type        = number
  description = "The time in seconds that a connection is allowed to be idle"
  default     = 60
}

variable "enable_http2" {
  type        = bool
  description = "Indicates whether HTTP/2 is enabled in application load balancers"
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  type        = bool
  description = "Indicates whether cross zone load balancing is enabled"
  default     = true
}

variable "target_group_config" {
  type = object({
    name                  = string
    port                  = number
    protocol              = string
    health_check_path     = string
    health_check_interval = number
    health_check_timeout  = number
    healthy_threshold     = number
    unhealthy_threshold   = number
    matcher               = string
  })
  description = "Target group configuration"
  default = {
    name                  = "default"
    port                  = 80
    protocol              = "HTTP"
    health_check_path     = "/"
    health_check_interval = 30
    health_check_timeout  = 5
    healthy_threshold     = 2
    unhealthy_threshold   = 2
    matcher               = "200-299"
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default     = {}
}
