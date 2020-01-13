resource "aws_cloudwatch_event_rule" "guardduty_rule" {
  event_pattern = <<EOF
{
  "source": [
    "aws.guardduty"
  ],
  "detail-type": [
    "GuardDuty Finding"
  ]
}
EOF
}

resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  rule = aws_cloudwatch_event_rule.guardduty_rule.name
  arn = aws_sns_topic.alerts.arn
}