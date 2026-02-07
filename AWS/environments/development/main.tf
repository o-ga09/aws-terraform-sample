terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  region = var.aws_region
}

# ================================
# VPC Module
# ================================
module "vpc" {
  source = "../../modules/vpc"

  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  availability_zones      = var.availability_zones
  db_subnet_cidrs         = var.db_subnet_cidrs
  management_subnet_cidrs = var.management_subnet_cidrs
}

# ================================
# Security Groups
# ================================
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
  }
}

# ================================
# ALB Module
# ================================
module "alb" {
  source = "../../modules/alb"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_security_group_id      = aws_security_group.alb.id
  enable_https               = var.enable_https
  certificate_arn            = var.certificate_arn
  enable_deletion_protection = var.enable_deletion_protection
  enable_access_logs         = var.enable_access_logs
  access_logs_s3_bucket      = var.access_logs_s3_bucket
}

# ================================
# ECR Module
# ================================
module "ecr" {
  source = "../../modules/ecr"

  project_name            = var.project_name
  environment             = var.environment
  repository_name         = var.repository_name
  image_tag_mutability    = var.image_tag_mutability
  scan_on_push            = var.scan_on_push
  enable_lifecycle_policy = var.enable_lifecycle_policy
  image_retention_count   = var.image_retention_count
  encryption_type         = var.encryption_type
  kms_key_id              = var.kms_key_id
}

# ================================
# Local Variables for ECS Configuration
# ================================
locals {
  container_registry = var.container_image_registry != "" ? var.container_image_registry : (
    var.use_ecr_url ? split("/", module.ecr.repository_url)[0] : ""
  )

  container_repository = var.container_image_repository != "" ? var.container_image_repository : (
    var.use_ecr_url ? module.ecr.repository_name : ""
  )
}

# ================================
# ECS Module
# ================================
module "ecs" {
  source = "../../modules/ecs"

  project_name               = var.project_name
  environment                = var.environment
  container_port             = var.container_port
  container_image            = var.container_image
  container_image_registry   = local.container_registry
  container_image_repository = local.container_repository
  container_image_tag        = var.container_image_tag
  container_name             = var.container_name
  replica_count              = var.replica_count
  task_cpu                   = var.task_cpu
  task_memory                = var.task_memory
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  ecs_security_group_id      = aws_security_group.ecs.id
  target_group_arn           = module.alb.target_group_arn
  container_environment      = var.container_environment
  log_retention_days         = var.log_retention_days
  enable_auto_scaling        = var.enable_auto_scaling
  max_capacity               = var.max_capacity
  min_capacity               = var.min_capacity
}

# ================================
# RDS Module
# ================================
module "rds" {
  source = "../../modules/rds"

  project_name                  = var.project_name
  environment                   = var.environment
  database_name                 = var.database_name
  master_username               = var.master_username
  master_password               = var.use_parameter_store ? null : var.master_password
  use_parameter_store           = var.use_parameter_store
  parameter_store_password_name = var.parameter_store_password_name
  use_secrets_manager           = var.use_secrets_manager
  secrets_manager_secret_name   = var.secrets_manager_secret_name
  vpc_id                        = module.vpc.vpc_id
  private_subnet_ids            = module.vpc.private_subnet_ids
  db_security_group_id          = aws_security_group.rds.id
  engine_version                = var.engine_version
  is_serverless                 = var.is_serverless
  instance_class                = var.instance_class
  cluster_size                  = var.cluster_size
  min_capacity                  = var.min_capacity
  max_capacity                  = var.max_capacity
  backup_retention_period       = var.backup_retention_period
  preferred_backup_window       = var.preferred_backup_window
}
