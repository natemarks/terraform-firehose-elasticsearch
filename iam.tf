#------------------------------------------------------------------------------
# Creates  as_iam_role.firehose_to_es is used to grant firehose access to the
# backup S3 bucket, elasticsearch and cloudwatch logging
#------------------------------------------------------------------------------
resource "aws_iam_role" "firehose_to_es" {
  name = "firehose_to_es"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "firehose_to_es" {
  name        = "firehose-policy"
  description = "Permit firehose to write to destinations and logs"

  policy = data.template_file.firehose_to_es.rendered
}

resource "aws_iam_role_policy_attachment" "firehose_to_es" {
  role       = aws_iam_role.firehose_to_es.name
  policy_arn = aws_iam_policy.firehose_to_es.arn
}

data "template_file" "firehose_to_es" {
  template = file("firehose_to_es.json")
  vars = {
    bucket_name       = local.bucket_name
    account_id        = local.account_id
    es_domain         = var.es_domain
    index_name        = var.index_name
    type_name         = var.index_name
    aws_region        = var.aws_region
    s3_log_stream_arn = aws_cloudwatch_log_stream.s3.arn
    es_log_stream_arn = aws_cloudwatch_log_stream.elasticsearch.arn
  }
}
