resource "aws_sns_topic" "secure_topic" {
  name = "secure-topic"

  # Enable server-side encryption with AWS-managed key
  #kms_master_key_id                 = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.secure_topic.arn
  protocol = "sqs"
  endpoint = aws_sqs_queue.secure_queue.arn
}

output "topic_arn" {
  value = aws_sns_topic.secure_topic.arn
}
