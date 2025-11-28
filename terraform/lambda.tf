terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "alert-lambda"
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = "alert-queue"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  sensitive   = true
  default     = ""
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_architecture" {
  description = "Lambda function architecture (arm64 or x86_64)"
  type        = string
  default     = "arm64"
}

# SQS Queue
resource "aws_sqs_queue" "alert_queue" {
  name                      = var.sqs_queue_name
  delay_seconds             = 0
  max_message_size          = 262144  # 256 KB
  message_retention_seconds = 345600  # 4 days
  receive_wait_time_seconds = 10      # Long polling
  visibility_timeout_seconds = 60

  # Dead Letter Queue için redrive policy
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.alert_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = var.sqs_queue_name
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Dead Letter Queue (DLQ)
resource "aws_sqs_queue" "alert_dlq" {
  name                      = "${var.sqs_queue_name}-dlq"
  message_retention_seconds = 1209600  # 14 days

  tags = {
    Name        = "${var.sqs_queue_name}-dlq"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.lambda_function_name}-role"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# IAM Policy for Lambda to access SQS and CloudWatch
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.lambda_function_name}-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.alert_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.lambda_function_name}:*"
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.lambda_function_name}-logs"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Lambda Function
resource "aws_lambda_function" "alert_lambda" {
  filename         = "../build/alert-lambda.zip"
  function_name    = var.lambda_function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "bootstrap"
  source_code_hash = filebase64sha256("../build/alert-lambda.zip")
  runtime         = "provided.al2023"
  architectures   = [var.lambda_architecture]
  memory_size     = var.lambda_memory
  timeout         = var.lambda_timeout

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group,
    aws_iam_role_policy.lambda_policy
  ]

  tags = {
    Name        = var.lambda_function_name
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Lambda Event Source Mapping (SQS -> Lambda)
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.alert_queue.arn
  function_name    = aws_lambda_function.alert_lambda.arn
  batch_size       = 10
  enabled          = true

  # Partial batch response için
  function_response_types = ["ReportBatchItemFailures"]

  depends_on = [
    aws_iam_role_policy.lambda_policy
  ]
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.lambda_function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "This metric monitors Lambda function errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.alert_lambda.function_name
  }

  tags = {
    Name        = "${var.lambda_function_name}-errors-alarm"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Outputs
output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.alert_lambda.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.alert_lambda.function_name
}

output "sqs_queue_url" {
  description = "URL of the SQS queue"
  value       = aws_sqs_queue.alert_queue.url
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.alert_queue.arn
}

output "dlq_queue_url" {
  description = "URL of the Dead Letter Queue"
  value       = aws_sqs_queue.alert_dlq.url
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}

