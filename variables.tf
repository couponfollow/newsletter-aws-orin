variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "newsletter"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

# --- Domain & DNS ---

variable "domain_name" {
  description = "Domain name for receiving emails via SES"
  type        = string
  default     = "fluorineai.com"
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for the domain"
  type        = string
}

# --- S3 ---

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for storing emails"
  type        = string
  default     = "cf-newsletter-emails"
}

variable "s3_raw_prefix" {
  description = "S3 key prefix for raw MIME emails"
  type        = string
  default     = "raw/"
}

variable "s3_parsed_prefix" {
  description = "S3 key prefix for parsed JSON emails"
  type        = string
  default     = "parsed/"
}

# --- SES ---

variable "ses_rule_set_name" {
  description = "Name of the SES receipt rule set"
  type        = string
  default     = "newsletter-rule-set"
}

# --- SQS ---

variable "sqs_message_retention_seconds" {
  description = "How long SQS retains messages (seconds)"
  type        = number
  default     = 345600 # 4 days
}

variable "sqs_visibility_timeout_seconds" {
  description = "SQS visibility timeout for consumers (seconds)"
  type        = number
  default     = 60
}

# --- Lambda ---

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_memory_size" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 256
}

# --- External consumer ---

variable "external_user_name" {
  description = "IAM user name for external email consumer"
  type        = string
  default     = "newsletter-external-consumer"
}
