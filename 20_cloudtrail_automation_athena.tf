resource "aws_s3_bucket" "bucket_athena_results" {
  bucket = "${local.compliance_bucket_name}-athena-results"

  lifecycle_rule {
    enabled = true

    expiration {
      days = 90
    }
  }
}

resource "aws_athena_database" "compliance_db" {
  name   = "${var.shared_prefix}_compliance_db"
  bucket = aws_s3_bucket.compliance_bucket.id
}

output "s3_bucket_athena_results" {
  value = aws_s3_bucket.bucket_athena_results.id
}

resource "aws_athena_workgroup" "compliance" {
  name = "${var.shared_prefix}_compliance"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.bucket_athena_results.id}/cw/"
    }
  }
}

locals {
  athena_table_creation_script = ""
}

resource "null_resource" "athena_table_creation" {
  triggers = {
    table_creation_hash = md5(local.athena_table_creation_script)
  }

  provisioner "local-exec" {
    command =  "aws iam get-user"
  }

  depends_on = [aws_athena_workgroup.compliance]
}

resource "aws_athena_named_query" "cloudtrail_iam_modifications" {
  name      = "${var.shared_prefix}_iam_modifications"
  workgroup = aws_athena_workgroup.compliance.id
  database  = aws_athena_database.compliance_db.name
  query     = <<EOF
SELECT *
FROM cloudtrail_logs
WHERE
   eventtime >= '2020-01-13T18:30:00' AND eventtime < '2020-01-14T00:00:00' AND
   eventsource = 'iam.amazonaws.com' AND
   (
     eventname NOT LIKE 'Get%' AND
     eventname NOT LIKE 'List%' AND
     eventname NOT LIKE 'Describe%'
   )
EOF

  depends_on = [null_resource.athena_table_creation]
}