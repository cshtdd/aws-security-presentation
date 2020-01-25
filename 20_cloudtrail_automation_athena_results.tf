resource "aws_s3_bucket_notification" "s3_athena_results_notification" {
  bucket = aws_s3_bucket.bucket_athena_results.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "cw/"
    filter_suffix       = ".csv"
  }
}

resource "aws_lambda_permission" "s3_lambda_permissions" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_lambda.function_name
  principal = "s3.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
  source_arn = aws_s3_bucket.bucket_athena_results.arn
}

data "archive_file" "s3_lambda_zip" {
  type = "zip"
  source_file = "${path.module}/lambda_src/s3/main.js"
  output_path = "s3_lambda.zip"
}

resource "aws_lambda_function" "s3_lambda" {
  function_name = "${var.shared_prefix}-s3-lambda"
  filename = "s3_lambda.zip"
  source_code_hash = data.archive_file.s3_lambda_zip.output_base64sha256
  handler = "main.handler"
  runtime = "nodejs12.x"
  role = aws_iam_role.s3_lambda_iam_role.arn
  timeout = 900
  environment {
    variables = {
      ALERTS_SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
    }
  }
}

resource "aws_iam_role" "s3_lambda_iam_role" {
  name = "${var.shared_prefix}-s3-lambda-role"
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

resource "aws_iam_role_policy_attachment" "s3_lambda_basic_execution_role_policy_attachment" {
  role = aws_iam_role.s3_lambda_iam_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3_lambda_policy_attachment" {
  role = aws_iam_role.s3_lambda_iam_role.id
  policy_arn = aws_iam_policy.s3_lambda_policy.arn
}

resource "aws_iam_policy" "s3_lambda_policy" {
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
      "Action": [
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.bucket_athena_results.arn}",
        "${aws_s3_bucket.bucket_athena_results.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "s3_lambda_logs" {
  name = "/aws/lambda/${aws_lambda_function.s3_lambda.function_name}"
  retention_in_days = 90
}
