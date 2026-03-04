# Newsletter Terraform

Infrastructure-as-code for the Newsletter project. Manages AWS resources via Terraform.

## Resources

- **AWS Lambda** — Python 3.12 function for newsletter processing
- **IAM Role** — Least-privilege execution role with `AWSLambdaBasicExecutionRole`
- **CloudWatch Logs** — Log group with 14-day retention

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_profile` | `default` | AWS CLI profile |
| `aws_region` | `us-east-1` | AWS region |
| `project_name` | `newsletter` | Resource naming prefix |
| `environment` | `dev` | Deployment environment |

## Outputs

- `lambda_function_name` — Name of the Lambda function
- `lambda_function_arn` — ARN of the Lambda function
- `lambda_role_arn` — ARN of the Lambda IAM role
