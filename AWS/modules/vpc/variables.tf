variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "environment" {
  type        = string
  description = "Environment name (development, staging, production)"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for subnets"
}

variable "db_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for database subnets (one per AZ)"
}

variable "management_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for management subnets (one per AZ, with +1 for backup)"
}
