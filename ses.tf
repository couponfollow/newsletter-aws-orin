resource "aws_ses_domain_identity" "newsletter" {
  domain = var.domain_name
}

resource "aws_ses_domain_identity_verification" "newsletter" {
  domain = aws_ses_domain_identity.newsletter.id

  depends_on = [aws_route53_record.ses_verification]
}

resource "aws_ses_domain_dkim" "newsletter" {
  domain = aws_ses_domain_identity.newsletter.domain
}

resource "aws_ses_receipt_rule_set" "newsletter" {
  rule_set_name = var.ses_rule_set_name
}

resource "aws_ses_active_receipt_rule_set" "newsletter" {
  rule_set_name = aws_ses_receipt_rule_set.newsletter.rule_set_name
}

resource "aws_ses_receipt_rule" "store_to_s3" {
  name          = "${var.project_name}-store-to-s3"
  rule_set_name = aws_ses_receipt_rule_set.newsletter.rule_set_name
  recipients    = [var.domain_name]
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name       = aws_s3_bucket.newsletter_emails.id
    object_key_prefix = var.s3_raw_prefix
    position          = 1
  }

  depends_on = [aws_s3_bucket_policy.allow_ses_writes]
}
