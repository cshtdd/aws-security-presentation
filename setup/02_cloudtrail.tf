resource "aws_cloudtrail" "default" {
  name                          = "${var.shared_prefix}-default-trail"
  s3_bucket_name                = aws_s3_bucket.compliance_bucket.id
  s3_key_prefix                 = "default-trail"
}

output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.compliance_bucket.id
}