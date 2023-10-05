output "lambda_function_name" {
  description = "The name of the created Lambda function"
  value       = aws_lambda_function.create_pr_to_master.function_name
}

output "cloudwatch_event_rule_name" {
  description = "The name of the CloudWatch Event Rule"
  value       = aws_cloudwatch_event_rule.pr_created.name
}

output "log_group_name" {
  description = "The name of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}
