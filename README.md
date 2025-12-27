# MediTrack-infra

## Description
Infrastructure as Code pour le projet MediTrack utilisant Terraform et Ansible. Déploiement automatisé d'une infrastructure AWS sécurisée pour l'hébergement d'un site web statique via CloudFront, respectant les normes RGPD/HDS.

## Architecture
- **VPC sécurisé** avec sous-réseau public
- **Instance EC2** t2.micro avec chiffrement EBS
- **Bucket S3** pour le site statique
- **Distribution CloudFront** avec HTTPS forcé
- **Ansible** pour configuration Nginx et sécurité

## Structure du projet
- `terraform/` : Scripts Terraform pour provisionner l'infrastructure AWS (VPC, EC2, S3, CloudFront)
- `ansible/` : Playbooks Ansible pour la configuration des serveurs EC2
- `site-static/` : Fichiers statiques du site web MediTrack Online

## Prérequis
- Compte AWS avec permissions administrateur
- Terraform >= 1.2.0
- Ansible >= 2.9
- Clés d'accès AWS configurées

## Installation des outils

### Terraform
```bash
sudo apt update
sudo apt install -y terraform
terraform --version
```

### Ansible
```bash
sudo apt update
sudo apt install -y ansible
ansible --version
```

## Configuration IAM

1. Créer un utilisateur IAM avec AdministratorAccess
2. Générer des clés d'accès
3. Configurer les credentials :
```bash
mkdir ~/.aws
echo '[default]' > ~/.aws/credentials
echo 'aws_access_key_id = YOUR_ACCESS_KEY' >> ~/.aws/credentials
echo 'aws_secret_access_key = YOUR_SECRET_KEY' >> ~/.aws/credentials
echo '[default]' > ~/.aws/config
echo 'region = eu-west-3' >> ~/.aws/config
```

## Déploiement

### Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Ansible
Mettre à jour `ansible/inventory.ini` avec l'IP publique de l'instance EC2
```bash
cd ansible
ansible-playbook -i inventory.ini playbook.yml
```

## Sécurité
- Chiffrement EBS activé
- Groupe de sécurité restrictif
- Accès SSH limité à votre IP
- HTTPS forcé via CloudFront
- Principe du moindre privilège IAM

## URL du site
Après déploiement, le site sera accessible via l'URL CloudFront fournie dans les outputs Terraform.
