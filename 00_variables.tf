variable "aws_region" {
  default = "us-east-2"
}

variable "shared_prefix" {
  default = "cc"
}

//https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_sns.html
variable "guardduty_announcements_topic_arn" {
  default = "arn:aws:sns:us-east-2:118283430703:GuardDutyAnnouncements"
}
