resource "aws_iam_role" "sample_lambda_iam_role" {
  count = var.enable_examples ? 1 : 0
  name = "${var.shared_prefix}-sample-lambda-role"
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
