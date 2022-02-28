data "aws_ami" "ami" {
  owners           = ["342998638422"]
  most_recent      = true
  name_regex       = "^Centos7-Kesava"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket      = var.bucket
    key         = "vpc/${var.ENV}/terraform.tfstate"
    region      = "us-east-1"
  }
}

data "aws_secretsmanager_secret" "creds" {
  name = "roboshop"
}

data "aws_secretsmanager_secret_version" "creds" {
  secret_id = data.aws_secretsmanager_secret.creds.id
}