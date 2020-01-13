resource "aws_sns_topic" "alerts" {
  name = "${var.shared_prefix}-alerts"
}

resource "aws_sns_topic_policy" "alerts_policy" {
  arn = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.alerts_policy.json
}

data "aws_iam_policy_document" "alerts_policy" {
  statement {
    effect = "Allow"
    actions = ["SNS:Publish"]
    resources = [aws_sns_topic.alerts.arn]
    principals {
      identifiers = [
        "events.amazonaws.com",
        "lambda.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}