data "aws_caller_identity" "current" {}


locals {
  account_id = data.aws_caller_identity.current.account_id
}
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"
}

resource "aws_elasticsearch_domain" "es" {
  domain_name = var.es_domain
  elasticsearch_version = "7.7"

  cluster_config {
      instance_type = "t2.medium.elasticsearch"

  }

  ebs_options {
      ebs_enabled = true
      volume_size = 10
  }

  access_policies = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "es:*",
      "Principal": "*",
      "Effect": "Allow",
      "Resource": "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.es_domain}/*",
      "Condition": {
        "IpAddress": {"aws:SourceIp": ["47.14.25.149/32"]}
      }
    }
  ]
}
POLICY


  snapshot_options {
      automated_snapshot_start_hour = 23
  }


  tags = merge(
    {
      terraform = "true"
      terragrunt = "true"
      environment = var.environment
    },
    var.custom_tags,
  )
}



resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "terraform-kinesis-firehose-test-stream"
  destination = "elasticsearch"

  s3_configuration {
    role_arn           = aws_iam_role.firehose_to_es.arn
    bucket_arn         = aws_s3_bucket.bucket.arn
    buffer_size        = 10
    buffer_interval    = 400
    compression_format = "GZIP"
  }

  elasticsearch_configuration {
    domain_arn = aws_elasticsearch_domain.es.arn
    role_arn   = aws_iam_role.firehose_to_es.arn
    index_name = "test"
    #type_name  = "test"

  }
}