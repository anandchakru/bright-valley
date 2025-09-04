resource "aws_security_group" "alb" {
  name_prefix = "${local.project_name}-${var.environment}-alb-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${var.environment}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "ec2" {
  name_prefix = "${local.project_name}-${var.environment}-ec2-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${var.environment}-ec2-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${local.project_name}-${var.environment}-rds-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${var.environment}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Fetch SSH public key from S3 using external data source (more reliable than aws_s3_object)
data "external" "ssh_public_key" {
  program = ["sh", "-c", "aws s3 cp s3://${local.project_name}-terraform-state/ssh/${var.environment}_key.pub - | jq -Rs '{key: .}'"]
}

# Create a local to validate and process the SSH key
locals {
  ssh_public_key = try(trimspace(data.external.ssh_public_key.result.key), null)
}

resource "aws_key_pair" "server" {
  key_name   = "${local.project_name}-${var.environment}-key"
  public_key = local.ssh_public_key

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${var.environment}-keypair"
  })

  lifecycle {
    precondition {
      condition     = local.ssh_public_key != null && local.ssh_public_key != ""
      error_message = "SSH public key must be available in S3 before creating key pair."
    }
  }
}

# Application secrets for additional configuration
resource "aws_secretsmanager_secret" "app_secrets" {
  name                           = "${local.project_name}-${var.environment}-app-secrets"
  description                    = "Application secrets for ${local.project_name} ${var.environment}"
  recovery_window_in_days        = 0 # Force immediate deletion to avoid conflicts
  force_overwrite_replica_secret = true

  tags = merge(local.common_tags, {
    Name = "${local.project_name}-${var.environment}-app-secrets"
  })
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    # Application secrets
    JWT_SECRET_KEY = "eP97z7mC580VXn9piTDpcpPteP97z7mC580VXn9piTDpcpPtJLLC513NtvQRi61c"
    API_KEY        = "rC6M5e7HIX8lD8ksWdc2DzyGdO3ApqAN5l1Bxa0cerJixDyE23397DhuHXwmhMBe"
    ENCRYPTION_KEY = "3m4NKW712yh8bk75qSv1Zbvji841gJM8z2YD2pQde3MGotAET1h3fJ179dz0D5BV"

    # Database secrets
    DB_USERNAME = "bright-valleyadmin"
    DB_PASSWORD = random_password.db_password.result
    DB_ENGINE   = "postgres"
    DB_HOST     = aws_db_instance.postgres.address
    DB_PORT     = aws_db_instance.postgres.port
    DB_NAME     = aws_db_instance.postgres.db_name
  })
}