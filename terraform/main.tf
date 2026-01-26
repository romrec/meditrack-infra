# main.tf


resource "random_id" "suffix" {
  byte_length = 4
}

# VPC
resource "aws_vpc" "meditrack_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MediTrack-vpc"
  }
}

# Sous-réseau public
resource "aws_subnet" "meditrack_public_subnet" {
  vpc_id            = aws_vpc.meditrack_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-3a"
  tags = {
    Name = "MediTrack-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "meditrack_igw" {
  vpc_id = aws_vpc.meditrack_vpc.id
  tags = {
    Name = "MediTrack-igw"
  }
}

# Table de routage
resource "aws_route_table" "meditrack_public_rt" {
  vpc_id = aws_vpc.meditrack_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.meditrack_igw.id
  }

  tags = {
    Name = "MediTrack-public-rt"
  }
}

# Association table de routage
resource "aws_route_table_association" "meditrack_public_rta" {
  subnet_id      = aws_subnet.meditrack_public_subnet.id
  route_table_id = aws_route_table.meditrack_public_rt.id
}

# Groupe de sécurité
resource "aws_security_group" "meditrack_sg" {
  name        = "meditrack-sg"
  description = "Security group for MediTrack"
  vpc_id      = aws_vpc.meditrack_vpc.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # À restreindre en production
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MediTrack-sg"
  }
}

# Instance EC2
resource "aws_instance" "meditrack_web_server" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.meditrack_public_subnet.id
  vpc_security_group_ids = [aws_security_group.meditrack_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "MediTrack-web-server"
  }

  root_block_device {
    encrypted = true  # Chiffrement pour RGPD/HDS
  }

  lifecycle {
    prevent_destroy = false  # Autorise la suppression si nécessaire
    ignore_changes  = [ami]  # Ignore les changements d'AMI
  }
}

# Créer un bucket S3 pour le site statique
resource "aws_s3_bucket" "meditrack_website" {
  bucket = "meditrack-website-cfb77422"
  tags = {
    Name = "MediTrack Website"
  }
}

# Désactiver le blocage d'accès public pour le bucket (requis pour CloudFront)
resource "aws_s3_bucket_public_access_block" "meditrack_website" {
  bucket = aws_s3_bucket.meditrack_website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Créer une identité d'accès d'origine CloudFront
resource "aws_cloudfront_origin_access_identity" "meditrack_oai" {
  comment = "OAI for MediTrack website"
}

# Politique de bucket S3 pour autoriser CloudFront
resource "aws_s3_bucket_policy" "meditrack_website_policy" {
  bucket = aws_s3_bucket.meditrack_website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.meditrack_oai.id}"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.meditrack_website.arn}/*"
      }
    ]
  })
}

# Uploader les fichiers statiques dans le bucket S3
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.meditrack_website.id
  key          = "index.html"
  source       = "../site-static/index.html"
  content_type = "text/html"
  etag         = filemd5("../site-static/index.html")
}

resource "aws_s3_object" "style_css" {
  bucket       = aws_s3_bucket.meditrack_website.id
  key          = "style.css"
  source       = "../site-static/style.css"
  content_type = "text/css"
  etag         = filemd5("../site-static/style.css")
}

# Créer une distribution CloudFront
resource "aws_cloudfront_distribution" "meditrack_distribution" {
  origin {
    domain_name = aws_s3_bucket.meditrack_website.bucket_regional_domain_name
    origin_id   = "S3-meditrack-website"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.meditrack_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "MediTrack website distribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-meditrack-website"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "MediTrack Distribution"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-3"
}
