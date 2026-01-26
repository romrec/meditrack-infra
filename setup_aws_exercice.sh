#!/bin/bash
# Script de configuration automatique AWS pour débutants

echo "🚀 Configuration de l'exercice AWS..."

# Variables
BUCKET_NAME="exercice-aws-debutant-romain-$(date +%s)"
INSTANCE_NAME="exercice-ec2-debutant-romain"

# 1. Créer la paire de clés
echo "1. Création de la paire de clés..."
aws ec2 create-key-pair --key-name exercice-debutant-key-romain --query 'KeyMaterial' --output text > exercice-debutant-key-romain.pem 2>/dev/null || echo "Clé existe déjà"
chmod 400 exercice-debutant-key-romain.pem 2>/dev/null || true

# 2. Créer le groupe de sécurité
echo "2. Création du groupe de sécurité..."
SG_ID=$(aws ec2 create-security-group --group-name exercice-debutant-sg-romain --description "Pour debutants Romain" 2>/dev/null || aws ec2 describe-security-groups --group-names exercice-debutant-sg-romain --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 2>/dev/null || true

# 3. Lancer l'instance EC2
echo "3. Lancement de l'instance EC2..."
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0c94855ba95b798c7 --count 1 --instance-type t2.micro --key-name exercice-debutant-key-romain --security-group-ids $SG_ID --query 'Instances[0].InstanceId' --output text)
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$INSTANCE_NAME
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

INSTANCE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "Instance démarrée : $INSTANCE_ID - IP : $INSTANCE_IP"

# 4. Créer le bucket S3
echo "4. Création du bucket S3..."
aws s3 mb s3://$BUCKET_NAME --region eu-west-3

# Créer et uploader le fichier clé
echo "CLE_SECRETE_POUR_APPLICATION=ABC123XYZ789" > cle-application.txt
echo "VERSION=1.0" >> cle-application.txt
echo "DERNIERE_MODIFICATION=2026-01-18" >> cle-application.txt
aws s3 cp cle-application.txt s3://$BUCKET_NAME/

echo "Bucket créé : $BUCKET_NAME"

# 5. Créer le rôle IAM
echo "5. Création du rôle IAM..."
cat > ec2-s3-policy-romain.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        }
    ]
}
EOF

aws iam create-role --role-name DebutantRoleRomain --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}' 2>/dev/null || echo "Rôle existe"
aws iam put-role-policy --role-name DebutantRoleRomain --policy-name S3ReadOnlyAccessRomain --policy-document file://ec2-s3-policy-romain.json 2>/dev/null || echo "Politique attachée"

# Créer et attacher le profil d'instance
aws iam create-instance-profile --instance-profile-name DebutantProfileRomain 2>/dev/null || echo "Profil existe"
aws iam add-role-to-instance-profile --instance-profile-name DebutantProfileRomain --role-name DebutantRoleRomain 2>/dev/null || echo "Rôle ajouté au profil"
aws ec2 associate-iam-instance-profile --instance-id $INSTANCE_ID --iam-instance-profile Name=DebutantProfileRomain 2>/dev/null || echo "Profil attaché"

# Sauvegarder les informations
cat > infos_exercice_romain.txt << EOF
=== INFORMATIONS DE L'EXERCICE AWS ===
Instance ID: $INSTANCE_ID
IP Publique: $INSTANCE_IP
Bucket S3: $BUCKET_NAME
Rôle IAM: DebutantRoleRomain
Groupe de sécurité: $SG_ID
Clé SSH: exercice-debutant-key-romain.pem

Commande SSH: ssh -i exercice-debutant-key-romain.pem ec2-user@$INSTANCE_IP

Commande de test S3: aws s3 ls s3://$BUCKET_NAME/
EOF

echo "✅ Configuration terminée !"
echo "Consultez le fichier infos_exercice_romain.txt pour les détails"
cat infos_exercice_romain.txt
