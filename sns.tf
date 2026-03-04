resource "aws_sns_topic" "parsed_emails" {
  name = "${var.project_name}-parsed-emails"

  tags = local.common_tags
}

resource "aws_sns_topic_policy" "allow_s3_publish" {
  arn = aws_sns_topic.parsed_emails.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Publish"
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.parsed_emails.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.newsletter_emails.arn
          }
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "sqs_subscription" {
  topic_arn            = aws_sns_topic.parsed_emails.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.parsed_emails.arn
  raw_message_delivery = true
}
