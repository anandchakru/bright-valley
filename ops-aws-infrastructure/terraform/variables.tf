variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name ()"
  type        = string
  validation {
    condition     = contains([], var.environment)
    error_message = "Environment must be one of: ."
  }
}

variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional, only for custom domain)"
  type        = string
  default     = ""
}

variable "domain_base" {
  description = "Base domain for the application (e.g., 'example.com')"
  type        = string
  default     = "rathnas.com"
}

variable "app_id" {
  description = "Application ID for subdomain"
  type        = string
  default     = "bright-valley"
}

variable "instance_type" {
  description = "EC2 instance type for the server"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 2
}

variable "database_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "database_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}