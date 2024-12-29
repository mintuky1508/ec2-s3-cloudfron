provider "aws" {
  region = "us-west-1"
}

# S3 Bucket to store Node.js application files
resource "aws_s3_bucket" "nodejs_app_bucket" {
  bucket = "mintukyadav010715"  # Your unique bucket name
}

# S3 Block Public Access settings (disable public access block)
resource "aws_s3_bucket_public_access_block" "nodejs_app_block" {
  bucket                  = aws_s3_bucket.nodejs_app_bucket.id
  block_public_acls       = false  # Allow public ACLs
  block_public_policy     = false  # Allow public policy
}

# EC2 Instance to run Node.js application (optional)
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
}
