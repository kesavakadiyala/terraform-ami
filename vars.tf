variable "component" {}
variable "bucket" {}
variable "ENV" {}
variable "availability-zones" {}
variable "PAT" {
  default = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)["PAT"]
}