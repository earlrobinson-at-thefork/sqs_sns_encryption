resource "aws_sqs_queue" "secure_queue" {
  name = "secure-queue"

  # Enable server-side encryption with AWS-managed key
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
  #sqs_managed_sse_enabled = true
}

output "queue_url" {
  value = aws_sqs_queue.secure_queue.url
}
