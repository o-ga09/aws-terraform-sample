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
container_port = 80

# Use ECR repository URL automatically (recommended)
use_ecr_url = true

# Option 1: Specify full image URI directly (overrides use_ecr_url)
# Example: container_image = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:latest"
container_image = ""

# Option 2: Specify image components separately
# If use_ecr_url is true and these are empty, they are auto-populated from ECR module
# You can override them here if needed (e.g., for multi-registry setup)
container_image_registry   = ""       # Auto-filled from ECR if use_ecr_url=true
container_image_repository = ""       # Auto-filled from ECR if use_ecr_url=true
container_image_tag        = "latest" # e.g., "production:abc123def456" set from CI/CD

container_name        = "app"
replica_count         = 2
task_cpu              = 512
task_memory           = 1024
log_retention_days    = 30
enable_auto_scaling   = true
ecs_task_max_capacity = 4
ecs_task_min_capacity = 2

# Optional: Container environment variables
container_environment = {
  # "ENVIRONMENT" = "production"
  # "LOG_LEVEL"   = "info"
}

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
