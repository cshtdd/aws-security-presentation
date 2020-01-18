resource "aws_cloudwatch_event_rule" "athena_lambda_schedule_rule" {
  name = "${var.shared_prefix}-athena-schedule"
  schedule_expression = "cron(*/5 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "athena_lambda" {
  rule = aws_cloudwatch_event_rule.athena_lambda_schedule_rule.name
  arn = aws_lambda_function.athena_lambda.arn
}


resource "aws_lambda_permission" "guardduty_lambda_permissions" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.athena_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.athena_lambda_schedule_rule.arn
}


data "archive_file" "athena_lambda_zip" {
  type = "zip"
  source_file = "${path.module}/lambda_src/athena/main.js"
  output_path = "athena_lambda.zip"
}

resource "aws_lambda_function" "athena_lambda" {
  function_name = "${var.shared_prefix}-athena-lambda"
  filename = "athena_lambda.zip"
  source_code_hash = data.archive_file.athena_lambda_zip.output_base64sha256
  handler = "main.handler"
  runtime = "nodejs12.x"
  role = aws_iam_role.athena_lambda_iam_role.arn
  environment {
    variables = {
      ALERTS_SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
      ATHENA_WORKGROUP = aws_athena_workgroup.compliance.name
    }
  }
}

resource "aws_iam_role" "athena_lambda_iam_role" {
  name = "${var.shared_prefix}-athena-lambda-role"
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

resource "aws_iam_role_policy_attachment" "athena_lambda_basic_execution_role_policy_attachment" {
  role = aws_iam_role.athena_lambda_iam_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "athena_lambda_policy_attachment" {
  role = aws_iam_role.athena_lambda_iam_role.id
  policy_arn = aws_iam_policy.athena_lambda_policy.arn
}

resource "aws_iam_policy" "athena_lambda_policy" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.alerts.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "athena:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": "${aws_s3_bucket.bucket_athena_results.arn}"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "athena_lambda_logs" {
  name = "${aws_lambda_function.athena_lambda.function_name}-logs"
  retention_in_days = 90
}
