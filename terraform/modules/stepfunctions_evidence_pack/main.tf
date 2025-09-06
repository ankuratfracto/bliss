terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
    archive = { source = "hashicorp/archive", version = ">= 2.4.0" }
  }
}

provider "aws" { region = var.region }

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda/evidence_pack"
  output_path = "${path.module}/evidence_pack.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "evidence-pack-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    actions = ["s3:PutObject", "s3:PutObjectAcl"]
    resources = ["arn:aws:s3:::${var.evidence_bucket_name}/*"]
  }
  statement {
    actions = [
      "securityhub:GetFindings",
      "securityhub:DescribeHub",
      "config:Get*",
      "config:Describe*",
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetTrailStatus"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "evidence-pack-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "collector" {
  function_name = "evidence-pack-collector"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 600

  environment {
    variables = {
      EVIDENCE_BUCKET = var.evidence_bucket_name
    }
  }
}

# Step Functions role & state machine
resource "aws_iam_role" "sfn_role" {
  name = "evidence-pack-sfn-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "states.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy_document" "sfn_policy_doc" {
  statement {
    actions = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.collector.arn]
  }
  statement {
    actions   = ["sns:Publish"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sfn_policy" {
  name   = "evidence-pack-sfn-policy"
  policy = data.aws_iam_policy_document.sfn_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "sfn_attach" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.sfn_policy.arn
}

# SNS for email summary
resource "aws_sns_topic" "summary" { name = "evidence-pack-summary" }
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.summary.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# Load the state machine definition from repo path
data "local_file" "sfn_def" {
  filename = "${path.module}/../../state_machines/evidence_pack.asl.json"
}

resource "aws_sfn_state_machine" "evidence_pack" {
  name     = "evidence-pack"
  role_arn = aws_iam_role.sfn_role.arn
  definition = replace(data.local_file.sfn_def.content, "__LAMBDA_ARN__", aws_lambda_function.collector.arn)
}

# Monthly schedule
resource "aws_cloudwatch_event_rule" "monthly" {
  name                = "run-evidence-pack-monthly"
  schedule_expression = "cron(0 5 1 * ? *)" # 05:00 UTC on the 1st of each month
}
resource "aws_cloudwatch_event_target" "monthly_target" {
  rule      = aws_cloudwatch_event_rule.monthly.name
  target_id = "sfn"
  arn       = aws_sfn_state_machine.evidence_pack.arn
}
resource "aws_lambda_permission" "events_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.collector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly.arn
}
