# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = merge(
    {
      Name        = "${var.project_name}-db-subnet-group"
      Environment = var.environment
    },
    var.tags
  )
}

# Retrieve password from Secrets Manager if specified
data "aws_secretsmanager_secret_version" "db_password" {
  count         = var.use_secrets_manager ? 1 : 0
  secret_id     = var.secrets_manager_secret_name
  version_stage = "AWSCURRENT"
}

# Retrieve password from Parameter Store if specified
data "aws_ssm_parameter" "db_password" {
  count           = var.use_parameter_store ? 1 : 0
  name            = var.parameter_store_password_name
  with_decryption = true
}

# DB Parameter Group
resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.project_name}-params-${var.environment}"
  family      = var.db_parameter_group_family
  description = "Cluster parameter group for ${var.project_name}"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "immediate"
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-parameter-group"
      Environment = var.environment
    },
    var.tags
  )
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "aurora" {
  for_each = toset(var.enable_cloudwatch_logs)

  name              = "/aws/rds/cluster/${var.project_name}-${var.environment}/${each.value}"
  retention_in_days = var.log_retention_days

  tags = merge(
    {
      Name        = "${var.project_name}-aurora-${each.value}-logs"
      Environment = var.environment
    },
    var.tags
  )
}

# Aurora DB Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier              = "${var.project_name}-cluster-${var.environment}"
  engine                          = "aurora-mysql"
  engine_version                  = var.engine_version
  engine_mode                     = var.is_serverless ? "provisioned" : "provisioned"
  database_name                   = var.database_name
  master_username                 = var.master_username
  master_password                 = var.use_secrets_manager ? try(jsondecode(data.aws_secretsmanager_secret_version.db_password[0].secret_string)["password"], null) : (var.use_parameter_store ? data.aws_ssm_parameter.db_password[0].value : var.master_password)
  db_subnet_group_name            = aws_db_subnet_group.main.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  vpc_security_group_ids          = [var.db_security_group_id]

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  storage_encrypted = var.storage_encrypted

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-cluster-${var.environment}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  enabled_cloudwatch_logs_exports = var.enable_cloudwatch_logs

  enable_http_endpoint = var.enable_http_endpoint

  # Aurora Serverless v2 specific settings
  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.is_serverless ? [1] : []
    content {
      max_capacity = var.rds_max_capacity
      min_capacity = var.rds_min_capacity
    }
  }

  tags = merge(
    {
      Name        = "${var.project_name}-cluster"
      Environment = var.environment
    },
    var.tags
  )

  depends_on = [aws_cloudwatch_log_group.aurora]
}

# Aurora DB Cluster Instance
resource "aws_rds_cluster_instance" "main" {
  count              = var.is_serverless ? 0 : var.cluster_size
  identifier         = "${var.project_name}-instance-${var.environment}-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  publicly_accessible = false

  auto_minor_version_upgrade = true
  monitoring_interval        = 60
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn

  tags = merge(
    {
      Name        = "${var.project_name}-instance-${count.index + 1}"
      Environment = var.environment
    },
    var.tags
  )
}

# Aurora Serverless v2 Instance
resource "aws_rds_cluster_instance" "serverless" {
  count              = var.is_serverless ? 1 : 0
  identifier         = "${var.project_name}-instance-${var.environment}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  publicly_accessible = false

  tags = merge(
    {
      Name        = "${var.project_name}-instance"
      Environment = var.environment
    },
    var.tags
  )
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project_name}-rds-monitoring-role"
      Environment = var.environment
    },
    var.tags
  )
}

# Attach monitoring policy
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
