provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  compliance_bucket_name = "${var.shared_prefix}-ctl-2020-01-07-compliance1"
}

resource "aws_s3_bucket" "compliance_bucket" {
  bucket = local.compliance_bucket_name
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSComplianceBucketAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": [
                "cloudtrail.amazonaws.com",
                "config.amazonaws.com"
              ]
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${local.compliance_bucket_name}"
        },
        {
            "Sid": "AWSComplianceBucketWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": [
                "cloudtrail.amazonaws.com",
                "config.amazonaws.com"
              ]
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${local.compliance_bucket_name}/*",
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