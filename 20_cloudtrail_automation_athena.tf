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

locals {
  athena_query_results_location = "s3://${aws_s3_bucket.bucket_athena_results.id}/cw/"
}

resource "aws_athena_workgroup" "compliance" {
  name = "${var.shared_prefix}_compliance"

  configuration {
    result_configuration {
      output_location = local.athena_query_results_location
    }
  }
}

locals {
  athena_table_creation_script = <<EOF
CREATE EXTERNAL TABLE IF NOT EXISTS cloudtrail_logs (
eventversion STRING,
useridentity STRUCT<
               type:STRING,
               principalid:STRING,
               arn:STRING,
               accountid:STRING,
               invokedby:STRING,
               accesskeyid:STRING,
               userName:STRING,
sessioncontext:STRUCT<
attributes:STRUCT<
               mfaauthenticated:STRING,
               creationdate:STRING>,
sessionissuer:STRUCT<
               type:STRING,
               principalId:STRING,
               arn:STRING,
               accountId:STRING,
               userName:STRING>>>,
eventtime STRING,
eventsource STRING,
eventname STRING,
awsregion STRING,
sourceipaddress STRING,
useragent STRING,
errorcode STRING,
errormessage STRING,
requestparameters STRING,
responseelements STRING,
additionaleventdata STRING,
requestid STRING,
eventid STRING,
resources ARRAY<STRUCT<
               ARN:STRING,
               accountId:STRING,
               type:STRING>>,
eventtype STRING,
apiversion STRING,
readonly STRING,
recipientaccountid STRING,
serviceeventdetails STRING,
sharedeventid STRING,
vpcendpointid STRING
)
ROW FORMAT SERDE 'com.amazon.emr.hive.serde.CloudTrailSerde'
STORED AS INPUTFORMAT 'com.amazon.emr.cloudtrail.CloudTrailInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://${aws_s3_bucket.compliance_bucket.id}/default-trail/AWSLogs/${data.aws_caller_identity.current.account_id}/CloudTrail';
EOF
}

locals {
  athena_table_destruction_cmd = "aws athena start-query-execution --query-string \"DROP TABLE IF EXISTS cloudtrail_logs;\" --query-execution-context \"Database=${aws_athena_database.compliance_db.name}\" --work-group \"${aws_athena_workgroup.compliance.name}\" --result-configuration \"OutputLocation=${local.athena_query_results_location}\""
  athena_table_creation_cmd = "aws athena start-query-execution --query-string \"${local.athena_table_creation_script}\" --query-execution-context \"Database=${aws_athena_database.compliance_db.name}\" --work-group \"${aws_athena_workgroup.compliance.name}\" --result-configuration \"OutputLocation=${local.athena_query_results_location}\""
}

resource "null_resource" "athena_table_destruction" {
  triggers = {
    command_hash = md5(local.athena_table_creation_cmd)
  }

  provisioner "local-exec" {
    command = local.athena_table_destruction_cmd
  }

  depends_on = [aws_athena_workgroup.compliance]
}

resource "null_resource" "athena_table_creation" {
  triggers = {
    command_hash = md5(local.athena_table_creation_cmd)
  }

  provisioner "local-exec" {
    command = local.athena_table_creation_cmd
  }

  depends_on = [
    aws_athena_workgroup.compliance,
    null_resource.athena_table_destruction
  ]
}

resource "aws_athena_named_query" "cloudtrail_iam_modifications" {
  name      = "${var.shared_prefix}_iam_modifications"
  workgroup = aws_athena_workgroup.compliance.id
  database  = aws_athena_database.compliance_db.name
  query     = <<EOF
SELECT *
FROM cloudtrail_logs
WHERE
   eventtime >= date_format(current_date - interval '1' day, '%Y-%m-%d') AND
   eventtime < date_format(current_date, '%Y-%m-%d') AND
   eventsource = 'iam.amazonaws.com' AND
   (
     eventname NOT LIKE 'Get%' AND
     eventname NOT LIKE 'List%' AND
     eventname NOT LIKE 'Describe%'
   )
EOF

  depends_on = [null_resource.athena_table_creation]
}

output "athena_query_iam_modifications" {
  value = aws_athena_named_query.cloudtrail_iam_modifications.id
}