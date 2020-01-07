resource "random_string" "bucket_name" {
  length = 10
  special = false
  number = false
  upper = false
}

locals {
  cloudtrail_logs_bucket_name = "${var.shared_prefix}-ctl-2020-${random_string.bucket_name.result}"
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = local.cloudtrail_logs_bucket_name
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${local.cloudtrail_logs_bucket_name}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${local.cloudtrail_logs_bucket_name}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudtrail" "default" {
  name                          = "${var.shared_prefix}-default-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  s3_key_prefix                 = "default-trail"
//  cloud_watch_logs_group_arn
}

output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.cloudtrail_logs.id
}