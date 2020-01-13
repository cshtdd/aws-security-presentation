resource "aws_cloudwatch_event_rule" "config_rule" {
  name = "${var.shared_prefix}-config"
  event_pattern = <<EOF
{
  "source": [
    "aws.config"
  ],
  "detail-type": [
    "Config Rules Compliance Change"
  ]
}
EOF
}

resource "aws_cloudwatch_event_target" "config_to_sns" {
  rule = aws_cloudwatch_event_rule.config_rule.name
  arn = aws_sns_topic.alerts.arn
}