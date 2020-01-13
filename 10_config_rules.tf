resource "aws_config_configuration_recorder" "default_recorder" {
  role_arn = aws_iam_role.default_recorder_iam_role.arn
}

resource "aws_config_configuration_recorder_status" "default_recorder" {
  is_enabled = true
  name = aws_config_configuration_recorder.default_recorder.name
  depends_on = [aws_config_delivery_channel.default_delivery]
}

resource "aws_config_delivery_channel" "default_delivery" {
  s3_bucket_name = aws_s3_bucket.compliance_bucket.bucket
  s3_key_prefix = "default-recorder"
  snapshot_delivery_properties {
    delivery_frequency = "One_Hour"
  }
  depends_on     = [aws_config_configuration_recorder.default_recorder]
}

resource "aws_iam_role" "default_recorder_iam_role" {
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "default_recorder_policy" {
  role = aws_iam_role.default_recorder_iam_role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": [
          "config:Put*"
        ],
        "Effect": "Allow",
        "Resource": "*"
    },
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.compliance_bucket.arn}",
        "${aws_s3_bucket.compliance_bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "default_recorder_config_policy" {
  role = aws_iam_role.default_recorder_iam_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_config_rule" "public_read_s3_bucket" {
  name = "${var.shared_prefix}-public_read_s3_bucket"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  depends_on = [aws_config_configuration_recorder.default_recorder]
}

resource "aws_config_config_rule" "cloudtrail_encryption_enabled" {
  name = "${var.shared_prefix}-cloudtrail_encryption_enabled"
  source {
    owner = "AWS"
    source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder.default_recorder]
}