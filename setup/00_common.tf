provider "aws" {
  region = "us-east-2"
}

data "aws_caller_identity" "current" {}

variable "shared_prefix" {
  default = "cc"
}
