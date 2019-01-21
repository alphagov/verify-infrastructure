locals {
  s3_origin_id = "${aws_s3_bucket.verify_frontend_assets.arn}-origin"
}

resource "aws_cloudfront_distribution" "verify_frontend_assets_distribution" {
  enabled = true

  origin {
    domain_name = "${aws_s3_bucket.verify_frontend_assets.bucket_regional_domain_name}"
    origin_id   = "${local.s3_origin_id}"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
