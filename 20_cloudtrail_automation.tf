resource "aws_cloudwatch_event_rule" "cloudtrail_rule" {
  name = "${var.shared_prefix}-cloudtrail"
  event_pattern = <<EOF
{
  "source": [
    "aws.cloudtrail"
  ]
}
EOF
}

resource "aws_cloudwatch_event_target" "cloudtrail_to_lambda" {
  rule = aws_cloudwatch_event_rule.cloudtrail_rule.name
  arn = aws_lambda_function.cloudtrail_lambda.arn
}

resource "aws_lambda_permission" "cloudtrail_lambda_permissions" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudtrail_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.cloudtrail_rule.arn
}

resource "aws_lambda_function" "cloudtrail_lambda" {
  function_name = "${var.shared_prefix}-cloudtrail-lambda"
  filename = "cloudtrail_lambda.zip"
  source_code_hash = data.archive_file.cloudtrail_lambda_zip.output_base64sha256
  handler = "main.handler"
  runtime = "nodejs12.x"
  role = aws_iam_role.cloudtrail_lambda_iam_role.arn
  environment {
    variables = {
      ALERTS_SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}

data "archive_file" "cloudtrail_lambda_zip" {
  type = "zip"
  source_file = "${path.module}/lambda_src/cloudtrail/main.js"
  output_path = "cloudtrail_lambda.zip"
}

resource "aws_iam_role" "cloudtrail_lambda_iam_role" {
  name = "${var.shared_prefix}-cloudtrail-lambda-role"
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

resource "aws_iam_role_policy_attachment" "cloudtrail_lambda_basic_execution_role_policy_attachment" {
  role = aws_iam_role.cloudtrail_lambda_iam_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cloudtrail_lambda_policy_attachment" {
  role = aws_iam_role.cloudtrail_lambda_iam_role.id
  policy_arn = aws_iam_policy.cloudtrail_lambda_policy.arn
}

resource "aws_iam_policy" "cloudtrail_lambda_policy" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.alerts.arn}"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "cloudtrail_lambda_logs" {
  name = "/aws/lambda/${aws_lambda_function.cloudtrail_lambda.function_name}"
  retention_in_days = 90
}
