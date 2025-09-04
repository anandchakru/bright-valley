resource "aws_db_subnet_group" "postgres" {
  name       = "${local.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${var.environment}-db-subnet-group"
  })
}

resource "aws_db_parameter_group" "postgres" {
  family = "postgres16"
  name   = "${local.project_name}-${var.environment}-db-params"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${var.environment}-db-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = true
  # Exclude characters that RDS doesn't allow: '/', '@', '"', ' ' (space)
  override_special = "!#$%&*+-=?^_`{|}~"
}

# Database password is now part of app_secrets in security.tf

resource "aws_db_instance" "postgres" {
  identifier = "${local.project_name}-${var.environment}-db"

  allocated_storage     = var.database_allocated_storage
  max_allocated_storage = var.database_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  engine         = "postgres"
  engine_version = "16.4"
  instance_class = var.database_instance_class

  db_name  = "bright-valleydb"
  username = "bright-valleyadmin"
  password = random_password.db_password.result

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  parameter_group_name   = aws_db_parameter_group.postgres.name

  backup_retention_period = var.environment == "prod" ? 7 : 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${local.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  copy_tags_to_snapshot = true
  deletion_protection   = var.environment == "prod"

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${var.environment}-database"
  })
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${local.project_name}-${var.environment}-rds-monitoring-role"

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

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${var.environment}-rds-monitoring-role"
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}