variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (development, staging, production)"
}

variable "repository_name" {
  type        = string
  description = "Name of the ECR repository"
}

variable "image_tag_mutability" {
  type        = string
  description = "The tag mutability setting for the repository (MUTABLE or IMMUTABLE)"
  default     = "MUTABLE"
}

variable "scan_on_push" {
  type        = bool
  description = "Scan image on push to the repository"
  default     = true
}

variable "enable_lifecycle_policy" {
  type        = bool
  description = "Enable lifecycle policy for image retention"
  default     = true
}

variable "image_retention_count" {
  type        = number
  description = "Number of images to retain in the repository"
  default     = 10
}

variable "encryption_type" {
  type        = string
  description = "The encryption type to use for the repository (AES256 or KMS)"
  default     = "AES256"
}

variable "kms_key_id" {
  type        = string
  description = "ARN of the KMS key (required if encryption_type is KMS)"
  default     = null
}

variable "repository_policy" {
  type        = string
  description = "The policy document for the repository"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to be applied to resources"
  default     = {}
}
