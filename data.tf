data "aws_ami" "ami" {
  owners           = ["342998638422"]
  most_recent      = true
  name_regex       = "^Kesava Centos-7"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket      = var.bucket
    key         = "vpc/${var.ENV}/terraform.tfstate"
    region      = "us-east-1"
  }
}