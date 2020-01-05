resource "aws_s3_bucket" "cloudtrail_logs" {}

resource "aws_cloudtrail" "default" {
  name                          = "${var.shared_prefix}-default-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  s3_key_prefix                 = "default-trail"
//  cloud_watch_logs_group_arn
}