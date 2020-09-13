output "elasticsearch_endpoint" {
  value = aws_elasticsearch_domain.es.endpoint
}

output "firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.selected.arn
}