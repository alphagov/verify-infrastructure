resource "aws_s3_bucket" "ssm_session_logs_store" {
  bucket = "gds-${var.deployment}-ssm-session-logs-store"
  acl    = "private"
  region = "eu-west-2"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_iam_policy_document" "ssm_session_logs_store" {
  statement {
    sid    = "ReadAndWriteToSSMSessionLogsStoreBucket"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "${data.aws_iam_role.instance_role.*.arn}",
      ]
    }

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.ssm_session_logs_store.arn}",
      "${aws_s3_bucket.ssm_session_logs_store.arn}/*",
    ]
  }

  statement {
    sid    = "ExplicitDeny"
    effect = "Deny"

    principals {
      type = "AWS"

      identifiers = [
        "*",
      ]
    }

    actions = [
      "s3:Delete*",
      "s3:PutBucketPolicy",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:PutAnalyticsConfiguration",
      "s3:PutBucketAcl",
      "s3:PutBucketCORS",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketRequestPayment",
      "s3:PutBucketVersioning",
      "s3:PutBucketWebsite",
      "s3:PutEncryptionConfiguration",
      "s3:PutInventoryConfiguration",
      "s3:PutReplicationConfiguration",
      "s3:ReplicateDelete",
    ]

    resources = [
      "${aws_s3_bucket.ssm_session_logs_store.arn}",
      "${aws_s3_bucket.ssm_session_logs_store.arn}/*",
    ]
  }

  statement {
    sid    = "DenyPlainTextAccess"
    effect = "Deny"

    principals {
      type = "AWS"

      identifiers = [
        "*",
      ]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListObjects",
    ]

    resources = [
      "${aws_s3_bucket.ssm_session_logs_store.arn}",
      "${aws_s3_bucket.ssm_session_logs_store.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "ssm_session_logs_store" {
  bucket = "${aws_s3_bucket.ssm_session_logs_store.bucket}"
  policy = "${data.aws_iam_policy_document.ssm_session_logs_store.json}"
}

resource "aws_ssm_document" "ssm_log" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = <<DOC
  {
    "schemaVersion": "1.0",
    "description": "Document to hold regional settings for Session Manager",
    "sessionType": "Standard_Stream",
    "inputs": {
      "s3BucketName": "${aws_s3_bucket.ssm_session_logs_store.bucket}",
      "s3KeyPrefix": "",
      "s3EncryptionEnabled": false,
      "cloudWatchLogGroupName": "",
      "cloudWatchEncryptionEnabled": false
    }
  }
DOC
}
