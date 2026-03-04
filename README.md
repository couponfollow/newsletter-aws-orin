# Newsletter Terraform

Infrastructure-as-code for the Newsletter email receiving pipeline. Manages AWS resources via Terraform.

## How It Works

### End-to-end flow

1. **Someone sends an email** to any address at your domain (e.g. `anything@fluorineai.com`). Their mail server does a DNS MX lookup, which returns the AWS SES inbound SMTP endpoint.

2. **SES receives the email.** The SES receipt rule matches all recipients on the domain, scans the message for spam/viruses, and writes the raw MIME content to S3 at `s3://<bucket>/raw/<message_id>`.

3. **S3 triggers the Lambda.** An S3 event notification fires on any object created under the `raw/` prefix, invoking the parser Lambda.

4. **Lambda parses the MIME email.** Using Python's stdlib `email` module, it extracts structured fields (from, to, cc, subject, date, headers, body text, body HTML, attachment metadata) and writes a JSON file to `s3://<bucket>/parsed/<to_address>/<date>_<message_id>.json`.

5. **S3 notifies SNS.** A second S3 event notification fires on any object created under the `parsed/` prefix, publishing a message to the SNS topic.

6. **SNS delivers to SQS.** The SNS topic forwards the S3 event notification (raw message delivery) to an SQS queue.

7. **External program polls SQS.** A client application — authenticated as the `newsletter-external-consumer` IAM user — polls the SQS queue for new messages. Each message contains the S3 key of the parsed JSON. The client fetches the JSON from S3, processes it, then deletes the SQS message. Failed messages retry up to 3 times before landing in the dead-letter queue.

### Parsed JSON format

```json
{
  "message_id": "<abc@example.com>",
  "from": "sender@example.com",
  "to": "recipient@fluorineai.com",
  "cc": "",
  "subject": "Subject line",
  "date": "2026-03-04T10:30:00+00:00",
  "date_raw": "Tue, 4 Mar 2026 10:30:00 +0000",
  "headers": { "From": "...", "To": "...", "..." : "..." },
  "body_text": "plain text content",
  "body_html": "<html>...</html>",
  "attachments": [
    { "filename": "doc.pdf", "content_type": "application/pdf", "size": 1234 }
  ]
}
```

## Resources

| Service | Resources | Purpose |
|---------|-----------|---------|
| **SES** | Domain identity, DKIM, receipt rule set + rule | Receive inbound email |
| **Route53** | MX record, TXT verification, 3 DKIM CNAMEs | DNS for email routing and domain verification |
| **S3** | Bucket (versioned, encrypted, lifecycle rules) | Store raw MIME and parsed JSON |
| **Lambda** | Python 3.12 function | Parse MIME into structured JSON |
| **SNS** | Topic + SQS subscription | Fan-out notifications on new parsed emails |
| **SQS** | Queue + dead-letter queue | Durable delivery to external consumers |
| **IAM** | Lambda role + policy, external consumer user | Least-privilege access control |
| **CloudWatch** | Log group (14-day retention) | Lambda observability |

## Prerequisites

- AWS account with a Route53 hosted zone for your domain
- Terraform >= 1.0
- AWS CLI configured with appropriate credentials

## Setup

1. Copy the example tfvars and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` (gitignored):
```hcl
aws_profile     = "my-profile"
domain_name     = "fluorineai.com"
route53_zone_id = "Z0123456789ABCDEF"
```

2. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

3. After apply, retrieve the external consumer credentials:

```bash
terraform output external_consumer_access_key_id
terraform output -raw external_consumer_secret_access_key
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_profile` | `default` | AWS CLI profile |
| `aws_region` | `us-east-1` | AWS region |
| `project_name` | `newsletter` | Resource naming prefix |
| `environment` | `dev` | Deployment environment |
| `domain_name` | — (required) | Domain for SES email receiving |
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

1. Send a test email to `test@<your-domain>`
2. Check raw email: `aws s3 ls s3://cf-newsletter-emails/raw/`
3. Check parsed JSON: `aws s3 ls s3://cf-newsletter-emails/parsed/`
4. Check SQS: `aws sqs receive-message --queue-url $(terraform output -raw sqs_queue_url)`
