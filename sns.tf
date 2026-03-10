data "aws_caller_identity" "current" {}

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

data "aws_iam_policy_document" "sns" {
  statement {
    sid    = "Allow-SNS-Send-to-SQS"
    effect = "Allow"

    principals {
      type = "*"
      identifiers = ["*"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.secure_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.secure_topic.arn]
    }
  }

  statement {
    sid    = "Allow-SNS-to-publish-SQS-KMS"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

}

resource "aws_kms_key" "sqs_cmk" {
  description = "sqs cmk secure key"
}

resource "aws_kms_alias" "sqs_cmk" {
  name = "alias/sqs_cmk_secure_key"
  target_key_id = aws_kms_key.sqs_cmk.key_id
}

resource "aws_kms_key_policy" "sqs_cmk" {
  key_id = aws_kms_key.sqs_cmk.id
  policy = data.aws_iam_policy_document.sns_use_sqs_kms.json
}

data "aws_iam_policy_document" "sns_use_sqs_kms" {
  policy_id = "default+sns"

  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions = [
      "kms:*"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowSNSService"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = ["*"]
  }
}

resource "aws_sqs_queue_policy" "sns" {
  queue_url = aws_sqs_queue.secure_queue.id
  policy    = data.aws_iam_policy_document.sns.json
}

