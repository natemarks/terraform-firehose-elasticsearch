variable "es_domain" {
  type    = string
  default = "management-events"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "management"
}

variable "custom_tags" {
  type    = map(string)
  default = {}
}


variable "index_name" {
  type    = string
  default = "events"
}

