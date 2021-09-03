resource "aws_s3_bucket" "hkr_sam" {
  bucket = "govukverify-hkr-${var.deployment}"
  region = data.aws_region.region.id
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Environment = var.deployment
    ManagedStackSource = "AwsSamCli"
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "hkr_sam_bucket_policy" {
  statement {
    sid    = "HKRSamBucketPolicy"
    effect = "Allow"

    principals {
      type="AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/accounts-deployer-role"
      ]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.hkr_sam.arn}", 
      "${aws_s3_bucket.hkr_sam.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "hkr_sam_policy" {
  bucket = aws_s3_bucket.hkr_sam.id
  policy = data.aws_iam_policy_document.hkr_sam_bucket_policy.json
}

resource "aws_ecr_repository" "hub_key_rotation" {
  name = "verify-hub-key-rotation"
}

resource "aws_ecr_repository_policy" "hub_key_rotation_policy" {
  repository = aws_ecr_repository.hub_key_rotation.name

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowPushPullForDeployerRole",
            "Effect": "Allow",
            "Principal": {
              "AWS": ["arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/accounts-deployer-role"]
            },
            "Action": [
              "ecr:BatchGetImage",
              "ecr:BatchCheckLayerAvailability",
              "ecr:CompleteLayerUpload",
              "ecr:GetDownloadUrlForLayer",
              "ecr:InitiateLayerUpload",
              "ecr:PutImage",
              "ecr:UploadLayerPart"
            ]
        }
    ]
  }
  EOF
}