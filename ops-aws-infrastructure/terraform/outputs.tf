output "s3_bucket_name" {
  description = "Name of the S3 bucket for client assets"
  value       = aws_s3_bucket.client.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.client.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.client.domain_name
}

output "load_balancer_dns_name" {
  description = "Load balancer DNS name"
  value       = aws_lb.server.dns_name
}

output "load_balancer_zone_id" {
  description = "Load balancer zone ID"
  value       = aws_lb.server.zone_id
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = true
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.server.name
}

output "api_bucket_name" {
  description = "S3 bucket for API data, uploads, and application storage"
  value       = aws_s3_bucket.api.bucket
}

output "ops_bucket_name" {
  description = "S3 bucket for operations, deployment artifacts, JAR files, and scripts"
  value       = aws_s3_bucket.ops.bucket
}

output "ui_domain" {
  description = "UI domain name for the application"
  value       = local.ui_domain
}

output "certificate_arn" {
  description = "ACM certificate ARN (if provided)"
  value       = var.certificate_arn != "" ? var.certificate_arn : "none"
}