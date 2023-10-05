locals {
  common_tags = {
    Terraform   = "true"
    Environment = "dev"
  }
  lambda_function_name = "${var.identifier}-createPrToMaster"
  log_group_name       = "/aws/lambda/${local.lambda_function_name}"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_cloudwatch_event_rule" "pr_created" {
  name        = "${var.identifier}-pr-created-rule"
  description = "Trigger when a PR is created on CodeCommit"

  event_pattern = jsonencode({
    "detail-type": ["CodeCommit Pull Request State Change"],
    "source": ["aws.codecommit"],
    "account": [data.aws_caller_identity.current.account_id],
    "region": [data.aws_region.current.name],
    "resources": [for repo_name in var.repository_names : format("arn:aws:codecommit:%s:%s:%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id, repo_name)],
    "detail": {
      "event": ["pullRequestCreated"],
      "pullRequestStatus": ["Open"],
      "repositoryNames": var.repository_names,
      "destinationReference": ["refs/heads/${var.staging_branch}"],
    },
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/files/lambda/create_pr.py"
  output_path = "${path.module}/files/lambda/create_pr.zip"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
  
  tags = local.common_tags
}

resource "aws_lambda_function" "create_pr_to_master" {
  function_name     = local.lambda_function_name
  handler           = "create_pr.handler"
  runtime           = "python3.9"
  role              = aws_iam_role.lambda_exec.arn
  filename          = data.archive_file.lambda_zip.output_path
  source_code_hash  = data.archive_file.lambda_zip.output_base64sha256

  tags = local.common_tags

  environment {
    variables = {
      STAGING_BRANCH = var.staging_branch
      MASTER_BRANCH  = var.master_branch
    }
  }
}

resource "aws_lambda_permission" "allow_event_bridge" {
  statement_id  = "AllowEventBridgeToInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_pr_to_master.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.pr_created.arn
}

resource "aws_cloudwatch_event_target" "pr_created_target" {
  rule      = aws_cloudwatch_event_rule.pr_created.name
  target_id = "${var.identifier}-CreatePrToMaster"
  arn       = aws_lambda_function.create_pr_to_master.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.identifier}-auto-create-pr-lambda-exec-role"

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
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  name = "${var.identifier}-auto-create-pr-lambda-exec-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "codecommit:CreatePullRequest",
          "codecommit:GetRepository",
          "codecommit:UpdatePullRequestTitle",
        ],
        Effect   = "Allow",
        Resource = "*",
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}:*",
      },
    ],
  })
}

