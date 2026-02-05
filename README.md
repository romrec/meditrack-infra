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
- AWS CLI v2
- Docker (pour Ansible sur Windows)
- Clés d'accès AWS configurées

## Installation des outils

### Terraform (Windows)
```powershell
# Installation via winget
winget install Hashicorp.Terraform

# Vérification de l'installation
terraform --version

# Ou installation manuelle depuis le zip dans tools/
Expand-Archive -Path "tools/terraform_1.9.5_windows_amd64.zip" -DestinationPath "C:\terraform"
[Environment]::SetEnvironmentVariable("PATH", "$env:PATH;C:\terraform", "User")
```

### AWS CLI v2 (Windows)
```powershell
# Installation via winget
winget install --id=Amazon.AWSCLI

# Ou installation manuelle depuis le zip dans tools/
msiexec.exe /i "tools/awscliv2.zip" /quiet

# Vérification de l'installation
aws --version
```

### Ansible (via Docker - recommandé pour Windows)
```bash
# Vérification de Docker
docker --version

# Construire l'image Ansible
docker-compose -f docker-compose.ansible.yml build

# Tester Ansible
docker-compose -f docker-compose.ansible.yml run --rm ansible ansible-playbook --version

# Exécuter le playbook
docker-compose -f docker-compose.ansible.yml run --rm ansible ansible-playbook -i inventory.ini playbook.yml
```

### Ansible (alternative via pip - Linux/macOS)
```bash
# Installation via pip
pip install ansible-core

# Vérification de l'installation
ansible-playbook --version
```

## Configuration IAM

### 1. Créer un utilisateur IAM avec AdministratorAccess
1. Se connecter à la console AWS
2. Aller dans IAM > Users > Add user
3. Nom : `meditrack-dev`
4. Permissions : "Attach existing policies directly" > `AdministratorAccess`
5. Créer l'utilisateur

### 2. Générer des clés d'accès
1. Dans la console IAM, sélectionner l'utilisateur `meditrack-dev`
2. Aller dans l'onglet "Security credentials"
3. Cliquer sur "Create access key"
4. Copier `Access key ID` et `Secret access key`

### 3. Configurer les credentials (Windows)
```powershell
# Créer le répertoire AWS
New-Item -ItemType Directory -Path "$env:USERPROFILE\.aws" -Force

# Créer le fichier credentials
@"
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
"@ | Set-Content -Path "$env:USERPROFILE\.aws\credentials"

# Créer le fichier config
@"
[default]
region = eu-west-3
output = json
"@ | Set-Content -Path "$env:USERPROFILE\.aws\config"
```

### 3. Configurer les credentials (Linux/macOS)
```bash
# Créer le répertoire AWS
mkdir -p ~/.aws

# Créer le fichier credentials
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
EOF

# Créer le fichier config
cat > ~/.aws/config << EOF
[default]
region = eu-west-3
output = json
EOF
```

### 4. Vérification de la configuration
```bash
# Tester la connexion AWS
aws sts get-caller-identity

# Lister les régions disponibles
aws ec2 describe-regions --output table
```

## Déploiement

### 1. Initialisation de l'environnement
```bash
# Vérifier les outils installés
terraform --version
aws --version
docker --version

# Vérifier la connexion AWS
aws sts get-caller-identity
```

### 2. Provisionnement Terraform
```bash
# Se placer dans le répertoire Terraform
cd terraform

# Initialiser le backend et les providers
terraform init

# Vérifier la syntaxe
terraform validate

# Planifier les changements (affiche ce qui sera créé)
terraform plan

# Appliquer les changements (crée l'infrastructure)
terraform apply

# Appuyer sur 'yes' pour confirmer
```

### 3. Récupérer les outputs Terraform
```bash
# Afficher les outputs après le déploiement
terraform output

# Récupérer l'IP publique de l'instance EC2
terraform output ec2_public_ip
```

### 4. Configuration Ansible
```bash
# Se placer dans le répertoire Ansible
cd ../ansible

# Mettre à jour l'inventaire avec l'IP de l'instance
# Modifier ansible/inventory.ini avec l'IP récupérée
```

### 5. Configuration Ansible (Windows via Docker)
```bash
# Vérifier que Docker est installé
docker --version

# Construire l'image Ansible
docker-compose -f docker-compose.ansible.yml build

# Lancer le playbook Ansible
docker-compose -f docker-compose.ansible.yml run --rm ansible ansible-playbook -i inventory.ini playbook.yml
```

### 5. Configuration Ansible (Linux/macOS via pip)
```bash
# Lancer le playbook Ansible
ansible-playbook -i inventory.ini playbook.yml
```

### 6. Vérification du déploiement
```bash
# Tester l'accès au site via CloudFront
# URL fournie dans les outputs Terraform : cloudfront_url

# Tester l'accès SSH à l'instance (optionnel)
ssh -i ~/.ssh/meditrack-key.pem ec2-user@IP_PUBLIQUE
```

### 7. Nettoyage (optionnel)
```bash
# Pour détruire toute l'infrastructure
cd terraform
terraform destroy

# Confirmer avec 'yes'
```

## Sécurité

### Infrastructure AWS
- **Chiffrement EBS** activé sur l'instance EC2 (RGPD/HDS)
- **Groupe de sécurité** restrictif (ports 22, 80, 443 uniquement)
- **HTTPS forcé** via CloudFront
- **Bucket S3** avec accès public limité (CloudFront uniquement)

### Accès SSH
- **Clé SSH** générée sans passphrase (environnement de test)
- **Utilisateur dédié** `meditrack` avec privilèges sudo
- **Accès root direct** désactivé

### Ansible
- **Headers de sécurité** Nginx (X-Frame-Options, CSP)
- **Compression Gzip** activée
- **Firewall UFW** configuré

## URL du site
Après déploiement, le site sera accessible via l'URL CloudFront fournie dans les outputs Terraform.

## Résolution des problèmes

### Problèmes courants

#### Terraform
```bash
# Erreur d'authentification AWS
aws sts get-caller-identity
# Vérifier les credentials dans ~/.aws/credentials

# Erreur de région
aws configure
# Vérifier que la région est eu-west-3

# Erreur de backend
rm -rf .terraform
terraform init
```

#### Ansible
```bash
# Erreur de connexion SSH
ssh -i ~/.ssh/meditrack-key.pem ec2-user@IP_PUBLIQUE
# Vérifier que l'instance est démarrée et accessible

# Erreur Docker (Windows)
docker --version
# Vérifier que Docker Desktop est installé et démarré

# Erreur playbook
ansible-playbook -i inventory.ini playbook.yml --check
# Exécuter en mode vérification
```

#### AWS CLI
```bash
# Vérifier la configuration
aws configure list

# Vérifier les permissions
aws iam get-user

# Vérifier la région
aws configure get region
```

### Logs et debugging
- **Terraform** : Logs dans `terraform_apply.log` et `terraform_plan.log`
- **Ansible** : Ajouter `-v` pour plus de verbosité
- **AWS** : Consulter les logs CloudWatch pour l'instance EC2

## Support
Pour toute question ou problème, consulter :
- La documentation AWS IAM et EC2
- La documentation Terraform
- La documentation Ansible
- Les logs d'erreurs générés pendant le déploiement
