# Provider
provider "aws" {
  region = "us-east-1"
}

locals {
  s3_origin_id = "charityS3Origin"
  my_domain    = "charity.com"
}

data "aws_acm_certificate" "my_domain" {
  region   = "us-east-1"
  domain   = "*.${local.my_domain}"
  statuses = ["ISSUED"]
}

# This is expected to generate a large amount of viewers from around the world
resource "aws_s3_bucket" "static_world_site" {
    bucket = "staic-world-site"
  
    tags = {
      Name = "static_world_site"
    }
}

data "aws_iam_policy_document" "origin_bucket_policy" {
    statement {
      sid    = "AllowCloudFrontServicePrincipalReadWrite"
      effect = "Allow"

      principals {
        type        = "Service"
        identifiers = ["cloudfront.amazonaws.com"]
      }

      actions = [
        "s3:GetObject",
        "s3:PutObject",
      ]

      resources = [
        "${aws_s3_bucket.static_world_site.arn}/*",
      ]

      condition {
        test     = "StringEquals"
        variable = "AWS:SourceArn"
        values   = [ aws_cloudfront_distribution.s3_distribution.arn ]
      }
    }
}

resource "aws_cloudfront_origin_access_control" "oac" {
    name                              = "my-oac"
    origin_access_control_origin_type = "s3"
    signing_behavior                  = "always"
    signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.static_world_site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                =  local.s3_origin_id
  }

  enabled = true
  is_ipv6_enabled = true
  comment = "Charity free"
  default_root_object = "index.html"

  aliases = ["mysite.${local.my_domain}", "yoursite.${local.my_domain}"]

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "POST", "PUT"]
    cached_methods = [ "GET", "HEAD" ]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations = [ "US", "CA", "GB", "DE" ]
    }
  }

  viewer_certificate {
    acm_certificate_arn = data.aws_acm_certificate.my_domain.arn
    ssl_support_method = "sni-only"
  }
}

# Create Route53 records for the CloudFront distribution aliases
data "aws_route53_zone" "my_domain" {
  name = local.my_domain
}


resource "aws_route53_record" "cloudfront" {
  for_each = aws_cloudfront_distribution.s3_distribution.aliases
  zone_id  = data.aws_route53_zone.my_domain.zone_id
  name     = each.value
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}