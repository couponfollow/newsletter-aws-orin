resource "aws_sqs_queue" "parsed_emails" {
  name                       = "${var.project_name}-parsed-emails"
  message_retention_seconds  = var.sqs_message_retention_seconds
  visibility_timeout_seconds = var.sqs_visibility_timeout_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.parsed_emails_dlq.arn
    maxReceiveCount     = 3
  })

  tags = local.common_tags
}

resource "aws_sqs_queue" "parsed_emails_dlq" {
  name                      = "${var.project_name}-parsed-emails-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = local.common_tags
}

resource "aws_sqs_queue_policy" "allow_sns_send" {
  queue_url = aws_sqs_queue.parsed_emails.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSNSSend"
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.parsed_emails.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.parsed_emails.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq_allow" {
  queue_url = aws_sqs_queue.parsed_emails_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.parsed_emails.arn]
  })
}
