locals {
  compliance_bucket_name = "${var.shared_prefix}-${var.compliance_bucket_name_sufix}"
}

resource "aws_s3_bucket" "compliance_bucket" {
  bucket = local.compliance_bucket_name

  lifecycle_rule {
    enabled = true

    expiration {
      days = 90
    }
  }

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

output "s3_bucket_compliance" {
  value = aws_s3_bucket.compliance_bucket.id
}