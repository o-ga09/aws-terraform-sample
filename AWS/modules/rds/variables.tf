variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (development, staging, production)"
}

variable "database_name" {
  type        = string
  description = "Initial database name"
}

variable "master_username" {
  type        = string
  description = "Master username for database"
  sensitive   = true
}

variable "master_password" {
  type        = string
  description = "Master password for database. If use_secrets_manager is true, this value is ignored"
  sensitive   = true
  default     = null
}

variable "use_secrets_manager" {
  type        = bool
  description = "Whether to retrieve password from AWS Secrets Manager instead of using plain text"
  default     = false
}

variable "secrets_manager_secret_name" {
  type        = string
  description = "The name of the secret in Secrets Manager containing the database password (JSON format with 'password' key)"
  default     = null
}

variable "use_parameter_store" {
  type        = bool
  description = "Whether to retrieve password from AWS Systems Manager Parameter Store instead of using plain text"
  default     = false
}

variable "parameter_store_password_name" {
  type        = string
  description = "The name of the parameter in Parameter Store containing the master password"
  default     = null
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where RDS will be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for RDS placement"
}

variable "db_security_group_id" {
  type        = string
  description = "Security group ID for RDS database"
}

# Aurora configuration
variable "engine_version" {
  type        = string
  description = "Aurora MySQL version"
  default     = "8.0.mysql_aurora.3.04.0"
}

variable "is_serverless" {
  type        = bool
  description = "Use Aurora Serverless v2"
  default     = false
}

# For provisioned Aurora
variable "instance_class" {
  type        = string
  description = "Instance class for Aurora (e.g., db.t4g.small, db.r6g.large)"
  default     = "db.t4g.small"
}

variable "cluster_size" {
  type        = number
  description = "Number of instances in the cluster"
  default     = 1
}

# For serverless Aurora
variable "rds_min_capacity" {
  type        = number
  description = "Minimum capacity for Aurora Serverless (0.5 to 128 ACUs)"
  default     = 0.5
}

variable "rds_max_capacity" {
  type        = number
  description = "Maximum capacity for Aurora Serverless (0.5 to 128 ACUs)"
  default     = 1
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention period in days"
  default     = 7
}

variable "preferred_backup_window" {
  type        = string
  description = "Preferred backup window (HH:MM-HH:MM)"
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  type        = string
  description = "Preferred maintenance window (ddd:HH:MM-ddd:HH:MM)"
  default     = "sun:04:00-sun:05:00"
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment"
  default     = false
}

variable "storage_encrypted" {
  type        = bool
  description = "Enable storage encryption"
  default     = true
}

variable "enable_cloudwatch_logs" {
  type        = list(string)
  description = "Enable CloudWatch logs (error, general, slowquery)"
  default     = ["error", "slowquery"]
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 7
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final DB snapshot when destroying"
  default     = false
}

variable "copy_tags_to_snapshot" {
  type        = bool
  description = "Copy tags to snapshots"
  default     = true
}

variable "enable_http_endpoint" {
  type        = bool
  description = "Enable HTTP endpoint for Data API (Serverless v1 only)"
  default     = false
}

variable "db_parameter_group_family" {
  type        = string
  description = "DB parameter group family"
  default     = "aurora-mysql8.0"
}

variable "db_parameters" {
  type        = map(string)
  description = "Custom database parameters"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources"
  default     = {}
}
