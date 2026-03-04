# --- Lambda S3 access ---

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "${var.project_name}-lambda-s3-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadRawEmails"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.newsletter_emails.arn}/${var.s3_raw_prefix}*"
      },
      {
        Sid      = "WriteParsedEmails"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.newsletter_emails.arn}/${var.s3_parsed_prefix}*"
      }
    ]
  })
}

# --- External consumer IAM user ---

resource "aws_iam_user" "external_consumer" {
  name = var.external_user_name

  tags = local.common_tags
}

resource "aws_iam_access_key" "external_consumer" {
  user = aws_iam_user.external_consumer.name
}

resource "aws_iam_user_policy" "external_consumer_s3" {
  name = "${var.external_user_name}-s3-read"
  user = aws_iam_user.external_consumer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetParsedEmails"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.newsletter_emails.arn}/${var.s3_parsed_prefix}*"
      },
      {
        Sid      = "ListParsedEmails"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.newsletter_emails.arn
        Condition = {
          StringLike = {
            "s3:prefix" = "${var.s3_parsed_prefix}*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_user_policy" "external_consumer_sqs" {
  name = "${var.external_user_name}-sqs-consume"
  user = aws_iam_user.external_consumer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ConsumeParsedEmailQueue"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.parsed_emails.arn
      }
    ]
  })
}
