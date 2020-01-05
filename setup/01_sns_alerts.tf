resource "aws_sns_topic" "alerts" {
  name = "${var.shared_prefix}-alerts"
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}