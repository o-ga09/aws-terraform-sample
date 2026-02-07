# ================================
# S3 Bucket for Terraform State
# ================================
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  tags = {
    Name    = "terraform-state"
    Purpose = "Store Terraform state files"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable logging
resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state_logs.id
  target_prefix = "state-logs/"
}

# ================================
# S3 Bucket for Logging
# ================================
resource "aws_s3_bucket" "terraform_state_logs" {
  bucket = "terraform-state-logs-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  tags = {
    Name    = "terraform-state-logs"
    Purpose = "Store logs for Terraform state bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_logs" {
  bucket = aws_s3_bucket.terraform_state_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ================================
# DynamoDB Table for State Lock
# ================================
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "terraform-lock"
    Purpose = "Store Terraform state locks"
  }
}

# ================================
# Data source for AWS Account ID
# ================================
data "aws_caller_identity" "current" {}
