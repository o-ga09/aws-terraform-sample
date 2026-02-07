# ================================
# General Configuration
# ================================
aws_region   = "ap-northeast-1"
project_name = "aws-terraform-sample"
environment  = "production"

# ================================
# Terraform State Configuration
# ================================
# NOTE: S3バックエンド設定
# 以下の手順でS3にStateを管理します：
# 1. bootstrap/ディレクトリで `terraform apply` を実行してS3バケットとDynamoDBを作成
# 2. bootstrap実行後、以下のコマンドで各環境を初期化：
#    cd environments/production
#    terraform init -backend-config="bucket=terraform-state-ACCOUNT_ID-ap-northeast-1"
#    ACCOUNT_ID はAWSアカウントIDに置き換えてください
# 3. その後、通常通り terraform plan/apply を実行

# ================================
# VPC Configuration
# ================================
vpc_cidr                = "10.0.0.0/16"
public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs    = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones      = ["ap-northeast-1a", "ap-northeast-1c"]
db_subnet_cidrs         = ["10.0.20.0/24", "10.0.21.0/24"]
management_subnet_cidrs = ["10.0.30.0/24", "10.0.31.0/24"]

# ================================
# ALB Configuration
# ================================
enable_https               = false # Set to true when you have a certificate
certificate_arn            = ""    # Update with your certificate ARN
enable_deletion_protection = true
enable_access_logs         = false # Set to true for production
access_logs_s3_bucket      = ""    # Update with your S3 bucket

# ================================
# ECR Configuration
# ================================
repository_name         = "aws-terraform-sample-repo"
image_tag_mutability    = "MUTABLE"
scan_on_push            = true
enable_lifecycle_policy = true
image_retention_count   = 10
encryption_type         = "AES256"

# ================================
# ECS Configuration
# ================================
# Frontend ECS Service
frontend_container_port        = 3000
frontend_container_name        = "frontend"
frontend_container_image       = "" # Leave empty to use ECR repository (recommended)
frontend_container_image_tag   = "latest"
frontend_use_ecr_url           = true
frontend_replica_count         = 2
frontend_task_cpu              = 512
frontend_task_memory           = 1024
frontend_enable_auto_scaling   = true
frontend_ecs_task_max_capacity = 4
frontend_ecs_task_min_capacity = 2
frontend_container_environment = {}

# Backend ECS Service  
backend_container_port        = 8080
backend_container_name        = "backend"
backend_container_image       = "" # Leave empty to use ECR repository (recommended)
backend_container_image_tag   = "latest"
backend_replica_count         = 2
backend_task_cpu              = 512
backend_task_memory           = 1024
backend_enable_auto_scaling   = true
backend_ecs_task_max_capacity = 4
backend_ecs_task_min_capacity = 2
backend_container_environment = {}

log_retention_days = 30

# ================================
# RDS Configuration
# ================================
database_name   = "awsterraformsampledb"
master_username = "terraform_sample_user"

# Option 1: Use plain text password (NOT RECOMMENDED for production)
# Uncomment and set a strong password if not using secrets management
# master_password = "ChangeMe!2024"

# Option 2: Use AWS Systems Manager Parameter Store (RECOMMENDED)
use_parameter_store           = true                               # Set to true to use Parameter Store
parameter_store_password_name = "/database/production/db_password" # e.g., "/database/production/password"

# Option 3: Use AWS Secrets Manager (RECOMMENDED)
use_secrets_manager         = false # Set to true to use Secrets Manager
secrets_manager_secret_name = null  # e.g., "rds/production/password"

engine_version          = "8.0.mysql_aurora.3.04.0"
is_serverless           = true # Set to true for Serverless v2
rds_min_capacity        = 1    # Serverless v2 minimum is 1.0
rds_max_capacity        = 2    # Adjust based on your workload
instance_class          = "db.t4g.small"
cluster_size            = 2
backup_retention_period = 30
preferred_backup_window = "03:00-04:00"
