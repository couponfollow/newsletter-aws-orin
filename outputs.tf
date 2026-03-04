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
