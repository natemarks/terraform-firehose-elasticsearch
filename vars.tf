variable "es_domain" {
  type = string
  default = "management-events"
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "environment" {
  type = string
  default = "management"
}

variable "custom_tags" {
  type = map(string)
  default = {}
}


variable "bucket_name" {
  type = string
  default = "natemarks-tf-test-bucket"
}

variable "index_name" {
  type = string
  default = "management-events"
}


variable "type_name" {
  type = string
  default = "management-events"
}