# Newsletter Terraform

Infrastructure-as-code for the Newsletter email receiving pipeline. Manages AWS resources via Terraform.

## Architecture

```
Email → SES Receipt Rule → S3 raw/<message_id>
                               ↓ (S3 event)
                           Lambda (parse MIME)
                               ↓
                           S3 parsed/<to_address>/<date>_<message_id>.json
                               ↓ (S3 event)
                           SNS → SQS ← External program (IAM user)
```

## Resources

- **SES** — Domain identity + receipt rules for `fluorineai.com` inbound email
- **Route53** — MX, verification TXT, and DKIM CNAME records
- **S3** — Bucket for raw MIME and parsed JSON emails (versioned, encrypted, lifecycle rules)
- **Lambda** — Python 3.12 MIME parser triggered by S3 raw/ uploads
- **SNS** — Topic notified on parsed/ object creation
- **SQS** — Queue (+ DLQ) subscribed to SNS for external consumption
- **IAM** — Lambda execution role, S3 access policy, external consumer user with S3/SQS permissions
- **CloudWatch** — Lambda log group with 14-day retention

## Prerequisites

- AWS account with Route53 hosted zone for `fluorineai.com`
- Terraform >= 1.0
- AWS CLI configured with appropriate credentials

## Usage

```bash
terraform init
terraform plan -var="route53_zone_id=YOUR_ZONE_ID"
terraform apply -var="route53_zone_id=YOUR_ZONE_ID"
```

Or create a `terraform.tfvars` file:

```hcl
route53_zone_id = "Z0123456789ABCDEF"
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_profile` | `default` | AWS CLI profile |
| `aws_region` | `us-east-1` | AWS region |
| `project_name` | `newsletter` | Resource naming prefix |
| `environment` | `dev` | Deployment environment |
| `domain_name` | `fluorineai.com` | Domain for SES email receiving |
| `route53_zone_id` | — (required) | Route53 hosted zone ID |
| `s3_bucket_name` | `cf-newsletter-emails` | S3 bucket name |
| `s3_raw_prefix` | `raw/` | S3 prefix for raw MIME emails |
| `s3_parsed_prefix` | `parsed/` | S3 prefix for parsed JSON |
| `ses_rule_set_name` | `newsletter-rule-set` | SES receipt rule set name |
| `sqs_message_retention_seconds` | `345600` (4 days) | SQS message retention |
| `sqs_visibility_timeout_seconds` | `60` | SQS visibility timeout |
| `lambda_timeout` | `60` | Lambda timeout (seconds) |
| `lambda_memory_size` | `256` | Lambda memory (MB) |
| `external_user_name` | `newsletter-external-consumer` | IAM user for external access |

## Outputs

| Output | Description |
|--------|-------------|
| `lambda_function_name` | Lambda function name |
| `lambda_function_arn` | Lambda function ARN |
| `lambda_role_arn` | Lambda IAM role ARN |
| `s3_bucket_name` | S3 bucket name |
| `s3_bucket_arn` | S3 bucket ARN |
| `ses_domain_identity_arn` | SES domain identity ARN |
| `ses_domain_verification_status` | SES verification token |
| `sns_topic_arn` | Parsed emails SNS topic ARN |
| `sqs_queue_url` | Parsed emails SQS queue URL |
| `sqs_queue_arn` | Parsed emails SQS queue ARN |
| `sqs_dlq_url` | Dead-letter queue URL |
| `external_consumer_access_key_id` | External consumer access key |
| `external_consumer_secret_access_key` | External consumer secret (sensitive) |

## Verification

After applying:

1. Send a test email to `test@fluorineai.com`
2. Check raw email: `aws s3 ls s3://cf-newsletter-emails/raw/`
3. Check parsed JSON: `aws s3 ls s3://cf-newsletter-emails/parsed/`
4. Check SQS: `aws sqs receive-message --queue-url <sqs_queue_url>`
