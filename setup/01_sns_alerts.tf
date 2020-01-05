provider "aws" {
  region = "us-east-2"
}

resource "aws_sns_topic" "alerts" {
  name = "cc-alerts"
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}