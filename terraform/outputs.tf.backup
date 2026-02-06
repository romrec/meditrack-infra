output "ec2_public_ip" {
  description = "IP publique de l'instance EC2"
  value       = aws_instance.meditrack_web_server.public_ip
}

output "cloudfront_url" {
  description = "URL de la distribution CloudFront"
  value       = "https://${aws_cloudfront_distribution.meditrack_distribution.domain_name}"
}

output "s3_bucket_name" {
  description = "Nom du bucket S3"
  value       = aws_s3_bucket.meditrack_website.bucket
}

output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.meditrack_vpc.id
}

output "subnet_id" {
  description = "ID du sous-réseau public"
  value       = aws_subnet.meditrack_public_subnet.id
}
