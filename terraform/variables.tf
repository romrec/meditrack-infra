variable "region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

variable "ssh_allowed_cidr" {
  description = "CIDR autorisé pour SSH (ex: 'VOTRE_IP/32' pour restreindre à votre IP)"
  type        = string
  default     = "0.0.0.0/0"  # À RESTREINDRE en production
}

variable "key_name" {
  description = "Nom de la clé SSH EC2 (sans .pem)"
  type        = string
  default     = "meditrack-key-new"
}

variable "project_name" {
  description = "Nom du projet pour les tags"
  type        = string
  default     = "MediTrack"
}

variable "environment" {
  description = "Environnement (dev, staging, production)"
  type        = string
  default     = "production"
}
