output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.newsletter.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.newsletter.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}

# --- S3 ---

output "s3_bucket_name" {
  description = "Name of the newsletter emails S3 bucket"
  value       = aws_s3_bucket.newsletter_emails.id
}

output "s3_bucket_arn" {
  description = "ARN of the newsletter emails S3 bucket"
  value       = aws_s3_bucket.newsletter_emails.arn
}

# --- SES ---

output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.newsletter.arn
}

output "ses_domain_verification_status" {
  description = "SES domain verification token (check DNS propagation)"
  value       = aws_ses_domain_identity.newsletter.verification_token
}

# --- SNS ---

output "sns_topic_arn" {
  description = "ARN of the parsed emails SNS topic"
  value       = aws_sns_topic.parsed_emails.arn
}

# --- SQS ---

output "sqs_queue_url" {
  description = "URL of the parsed emails SQS queue"
  value       = aws_sqs_queue.parsed_emails.url
}

output "sqs_queue_arn" {
  description = "ARN of the parsed emails SQS queue"
  value       = aws_sqs_queue.parsed_emails.arn
}

output "sqs_dlq_url" {
  description = "URL of the dead-letter queue"
  value       = aws_sqs_queue.parsed_emails_dlq.url
}

# --- External consumer ---

output "external_consumer_user_name" {
  description = "IAM user name for external consumer"
  value       = aws_iam_user.external_consumer.name
}

output "external_consumer_access_key_id" {
  description = "Access key ID for external consumer"
  value       = aws_iam_access_key.external_consumer.id
}

output "external_consumer_secret_access_key" {
  description = "Secret access key for external consumer"
  value       = aws_iam_access_key.external_consumer.secret
  sensitive   = true
}
