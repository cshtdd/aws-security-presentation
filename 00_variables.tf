variable "aws_region" {
  default = "us-east-2"
}

variable "shared_prefix" {
  default = "cc"
}

variable "compliance_bucket_name_sufix" {
  default = "ctl-2020-01-07-compliance1"
}

variable "enable_examples" {
  default = false
  type = bool
}