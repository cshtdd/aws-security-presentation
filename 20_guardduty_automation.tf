resource "aws_sns_topic_subscription" "guardduty_announcements_lambda_subscription" {
  endpoint = aws_lambda_function.guardduty_lambda.arn
  protocol = "lambda"
  topic_arn = var.guardduty_announcements_topic_arn
  endpoint_auto_confirms = true
}

data "archive_file" "guardduty_lambda_zip" {
  type = "zip"
  source_file = "${path.module}/lambda_src/guardduty/main.js"
  output_path = "guardduty_lambda.zip"
}

resource "aws_lambda_function" "guardduty_lambda" {
  function_name = "${var.shared_prefix}-guardduty-lambda"
  filename = "guardduty_lambda.zip"
  source_code_hash = data.archive_file.guardduty_lambda_zip.output_base64sha256
  handler = "main.handler"
  runtime = "nodejs12.x"
  role = aws_iam_role.guardduty_lambda_iam_role.arn
  environment {
    variables = {
      ALERTS_SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}

resource "aws_iam_role" "guardduty_lambda_iam_role" {
  name = "${var.shared_prefix}-guardduty-lambda-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}