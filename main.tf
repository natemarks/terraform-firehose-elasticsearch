data "aws_caller_identity" "current" {}


locals {
  account_id  = data.aws_caller_identity.current.account_id
  bucket_name = "${local.account_id}-${var.aws_region}-${var.es_domain}-firehose-backup"
}

#------------------------------------------------------------------------------
# Creates the firehose delivery backup bucket for messages that it fails to
# send to elasticsearch
# TODO: replace this. reuse the private bucket module
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "bucket" {
  bucket = local.bucket_name
  acl    = "private"
}

#------------------------------------------------------------------------------
# Creates the elasticsearch domain with minimal configuration
#------------------------------------------------------------------------------
resource "aws_elasticsearch_domain" "es" {
  domain_name           = var.es_domain
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
      terraform   = "true"
      terragrunt  = "true"
      environment = var.environment
    },
    var.custom_tags,
  )
}


#------------------------------------------------------------------------------
# Creates the firehose delivery stream
# - sends to elasticsearch
# - failed delivery messages go to the backup s3 bucket
# - requires aws_iam_role.firehose_to_es from iam.tf
#------------------------------------------------------------------------------
resource "aws_kinesis_firehose_delivery_stream" "selected" {
  name        = "${var.es_domain}-firehose-stream"
  destination = "elasticsearch"

  s3_configuration {
    role_arn           = aws_iam_role.firehose_to_es.arn
    bucket_arn         = aws_s3_bucket.bucket.arn
    buffer_size        = 10
    buffer_interval    = 400
    compression_format = "GZIP"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.selected.name
      log_stream_name = aws_cloudwatch_log_stream.s3.name
    }
  }

  elasticsearch_configuration {
    domain_arn = aws_elasticsearch_domain.es.arn
    role_arn   = aws_iam_role.firehose_to_es.arn
    index_name = var.index_name

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.selected.name
      log_stream_name = aws_cloudwatch_log_stream.elasticsearch.name
    }

  }

}

#------------------------------------------------------------------------------
# Creates the cloudwatch log group and streams
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "selected" {
  name = "/aws/kinesisfirehose/${var.es_domain}"
}

resource "aws_cloudwatch_log_stream" "s3" {
  log_group_name = aws_cloudwatch_log_group.selected.name
  name           = "S3Delivery"
}

resource "aws_cloudwatch_log_stream" "elasticsearch" {
  log_group_name = aws_cloudwatch_log_group.selected.name
  name           = "ElasticSearchDelivery"
}