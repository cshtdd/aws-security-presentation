# aws-security-presentation
Preparation materials for a presentation about AWS security  

*Disclaimer: The contents of this repository are for educational purposes. They may not be production grade.*  

# Outline  

AWS provides three services that can help enhance your account security with little overhead: AWS GuardDuty, AWS Config, AWS CloudTrail.  
The Basic Configuration code examples are a starting point for their configuration.  

Organizations with more than one AWS Account, or presence in multiple regions may benefit from automating certain configuration and alerting tasks.  
The Automation section of these examples contains some reference implementations of monitoring patterns.  

# Contents  

The files are grouped by three main groups.  

- `00_` **Shared Prerequisites**: Resources that will be shared across multiple service. Terraform variables. etc.  
- `10_` **Basic Configuration**: Minimal configuration to enable the described AWS services.  
- `20_` **Automation**: Automation resources to simplify the environment verification.  

## Basic Configuration  

### AWS CloudTrail  
[`10_cloudtrail.tf`](10_cloudtrail.tf)
- Create a trail and save it's output to an S3 bucket.

### AWS GuardDuty  
[`10_guardduty.tf`](10_guardduty.tf)
- Enable the GuardDuty Detector.  

### AWS Config  
[`10_config_rules.tf`](10_config_rules.tf)  

- Enable a Configuration Recorder.  
- Periodically save the compliance status to an S3 Bucket.  
- Create one AWS Config rule to detect public S3 buckets.  
- Create one AWS Config rule to detect CloudTrail encryption.  


## Automation  

### AWS Config  
[`20_config_automation_simple.tf`](20_config_automation_simple.tf)  
Create an AWS CloudWatch Event Rule that triggers an SNS Notification on any Compliance change.  

### AWS GuardDuty  
[20_guardduty_automation_simple.tf](20_guardduty_automation_simple.tf)  
Create an AWS CloudWatch Event Rule that triggers an SNS Notification on any GuardDuty finding.  

### AWS CloudTrail  

[20_cloudtrail_automation_athena.tf](20_cloudtrail_automation_athena.tf)  
- Create an S3 Bucket to save the results of our AWS Athena queries  
- Create a new AWS Athena Database  
- Create a new AWS Athena Workgroup  
- Create a new AWS Athena Table with the AWS CloudTrail data  
- Create an AWS Athena Named query to read all the IAM modifications of the previous day

[20_cloudtrail_automation_athena_schedule.tf](20_cloudtrail_automation_athena_schedule.tf)  
- Create an AWS CloudWatch Event Rule to trigger a lambda on a schedule
- Deploy an AWS Lambda to trigger all the Athena Saved Queries in the compliance Workgroup

[lambda_src/athena/main.js](lambda_src/athena/main.js)  
- Lambda code to read and trigger all the Athena Saved Queries in the compliance Workgroup  

[20_cloudtrail_automation_athena_results.tf](20_cloudtrail_automation_athena_results.tf)
- Deploy an AWS Lambda subscribed to object creation S3 events on the Ahena results bucket  

[lambda_src/s3/main.js](lambda_src/s3/main.js)  
- Lambda code to trigger an SNS Notification whenever a non-empty `.csv` is created in the Athena results bucket  

# Running the Code  

- Make sure you have `terraform` >= `0.12` installed  
- Edit the values on [`00_variables.tf`](00_variables.tf) as you seem fit. Change the `compliance_bucket_name_sufix` for it may already be taken  
- Run `terraform init`  
- Run `terraform apply`  
- Run `terraform detroy` for cleanup  
