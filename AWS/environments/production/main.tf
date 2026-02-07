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
  description = "ALB security group for ${var.project_name}"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend-ecs-sg"
  description = "Security group for frontend ECS tasks"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name        = "${var.project_name}-frontend-ecs-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "frontend_ingress" {
  type                     = "ingress"
  from_port                = var.frontend_container_port
  to_port                  = var.frontend_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.frontend.id
}

resource "aws_security_group_rule" "frontend_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend.id
}

resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-ecs-sg"
  description = "Security group for backend ECS tasks (internal only)"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name        = "${var.project_name}-backend-ecs-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "backend_ingress" {
  type                     = "ingress"
  from_port                = var.backend_container_port
  to_port                  = var.backend_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend.id
  security_group_id        = aws_security_group.backend.id
}

resource "aws_security_group_rule" "backend_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend.id
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name        = "${var.project_name}-rds-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "rds_ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = aws_security_group.rds.id
}

resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
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
# Local Variables for ECS/RDS Configuration
# ================================
locals {
  # Frontend container image configuration
  frontend_container_image = var.frontend_container_image != "" ? var.frontend_container_image : (
    var.frontend_use_ecr_url ? "${split("/", module.ecr.repository_url)[0]}/${module.ecr.repository_name}:${var.frontend_container_image_tag}" : "nginx:latest"
  )
}


# ================================
# Frontend ECS Service
# ================================
module "ecs_frontend" {
  source = "../../modules/ecs"

  project_name               = "${var.project_name}-frontend"
  environment                = var.environment
  container_port             = var.frontend_container_port
  container_image            = local.frontend_container_image
  container_image_registry   = ""
  container_image_repository = ""
  container_image_tag        = ""
  container_name             = var.frontend_container_name
  replica_count              = var.frontend_replica_count
  task_cpu                   = var.frontend_task_cpu
  task_memory                = var.frontend_task_memory
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  ecs_security_group_id      = aws_security_group.frontend.id
  target_group_arn           = module.alb.target_group_arn
  container_environment      = var.frontend_container_environment
  log_retention_days         = var.log_retention_days
  enable_auto_scaling        = var.frontend_enable_auto_scaling
  max_capacity               = var.frontend_ecs_task_max_capacity
  min_capacity               = var.frontend_ecs_task_min_capacity
}

# ================================
# Backend ECS Service
# ================================
module "ecs_backend" {
  source = "../../modules/ecs"

  project_name               = "${var.project_name}-backend"
  environment                = var.environment
  container_port             = var.backend_container_port
  container_image            = var.backend_container_image
  container_image_registry   = ""
  container_image_repository = ""
  container_image_tag        = var.backend_container_image_tag
  container_name             = var.backend_container_name
  replica_count              = var.backend_replica_count
  task_cpu                   = var.backend_task_cpu
  task_memory                = var.backend_task_memory
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  ecs_security_group_id      = aws_security_group.backend.id
  target_group_arn           = ""
  container_environment      = var.backend_container_environment
  log_retention_days         = var.log_retention_days
  enable_auto_scaling        = var.backend_enable_auto_scaling
  max_capacity               = var.backend_ecs_task_max_capacity
  min_capacity               = var.backend_ecs_task_min_capacity
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
  rds_min_capacity              = var.rds_min_capacity
  rds_max_capacity              = var.rds_max_capacity
  backup_retention_period       = var.backup_retention_period
  preferred_backup_window       = var.preferred_backup_window
}
