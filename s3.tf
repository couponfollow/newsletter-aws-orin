resource "aws_s3_bucket" "newsletter_emails" {
  bucket = var.s3_bucket_name

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "newsletter_emails" {
  bucket = aws_s3_bucket.newsletter_emails.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "newsletter_emails" {
  bucket = aws_s3_bucket.newsletter_emails.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "newsletter_emails" {
  bucket = aws_s3_bucket.newsletter_emails.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "newsletter_emails" {
  bucket = aws_s3_bucket.newsletter_emails.id

  rule {
    id     = "raw-email-lifecycle"
    status = "Enabled"

    filter {
      prefix = var.s3_raw_prefix
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "parsed-email-lifecycle"
    status = "Enabled"

    filter {
      prefix = var.s3_parsed_prefix
    }

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_notification" "email_notifications" {
  bucket = aws_s3_bucket.newsletter_emails.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.newsletter.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.s3_raw_prefix
  }

  topic {
    topic_arn     = aws_sns_topic.parsed_emails.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.s3_parsed_prefix
  }

  depends_on = [
    aws_lambda_permission.allow_s3_invoke,
    aws_sns_topic_policy.allow_s3_publish,
  ]
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id   = "AllowS3Invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.newsletter.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.newsletter_emails.arn
  source_account = local.account_id
}

resource "aws_s3_bucket_policy" "allow_ses_writes" {
  bucket = aws_s3_bucket.newsletter_emails.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSESPuts"
        Effect    = "Allow"
        Principal = { Service = "ses.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.newsletter_emails.arn}/${var.s3_raw_prefix}*"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })
}
