provider "aws" {
  region = "us-west-1"
}

# S3 Bucket to store Node.js application files
resource "aws_s3_bucket" "nodejs_app_bucket" {
  bucket        = "mintukyadav010715"  # Your unique bucket name
  force_destroy = true  # Force deletion of bucket and contents
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "nodejs_app_versioning" {
  bucket = aws_s3_bucket.nodejs_app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration for the S3 bucket
resource "aws_s3_bucket_lifecycle_configuration" "nodejs_app_lifecycle" {
  bucket = aws_s3_bucket.nodejs_app_bucket.id

  rule {
    id     = "DeleteObjects"
    status = "Enabled"

    expiration {
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      days = 1
    }
  }
}

# S3 Block Public Access settings (disable public access block)
resource "aws_s3_bucket_public_access_block" "nodejs_app_block" {
  bucket                  = aws_s3_bucket.nodejs_app_bucket.id
  block_public_acls       = false  # Allow public ACLs
  block_public_policy     = false  # Allow public policy
}

# EC2 Instance to run Node.js application
resource "aws_instance" "nodejs_ec2" {
  ami           = "ami-0657605d763ac72a8"  # Use your desired AMI ID
  instance_type = "t2.micro"
  key_name      = "mintu"  # Replace with your EC2 Key Pair name
  security_groups = ["default"]

  tags = {
    Name = "NodeJS App Server"
  }
}

# CloudFront Distribution to serve content from S3
resource "aws_cloudfront_distribution" "nodejs_cf" {
  origin {
    domain_name = aws_s3_bucket.nodejs_app_bucket.bucket_regional_domain_name
    origin_id   = "S3-mintukyadav010715"
  }

  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-mintukyadav010715"
    
    # Add forwarded values for cookies and query strings
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Viewer certificate block (to fix missing viewer certificate error)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Restrictions block (to fix missing restrictions error)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Ensure CloudFront depends on the S3 bucket
  depends_on = [aws_s3_bucket.nodejs_app_bucket]
}
