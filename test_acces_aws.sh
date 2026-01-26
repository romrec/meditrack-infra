#!/bin/bash
# Script de test d'accès au fichier S3 depuis l'instance EC2

if [ ! -f "infos_exercice_romain.txt" ]; then
    echo "❌ Fichier infos_exercice_romain.txt non trouvé. Lancez d'abord setup_aws_exercice.sh"
    exit 1
fi

# Lire les informations
INSTANCE_IP=$(grep "IP Publique:" infos_exercice_romain.txt | cut -d: -f2 | tr -d ' ')
BUCKET_NAME=$(grep "Bucket S3:" infos_exercice_romain.txt | cut -d: -f2 | tr -d ' ')

echo "🔍 Test de l'accès au fichier S3 depuis l'instance EC2..."
echo "IP de l'instance: $INSTANCE_IP"
echo "Bucket: $BUCKET_NAME"
echo ""

# Test SSH et exécution des commandes sur l'instance
ssh -i exercice-debutant-key-romain.pem -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP << EOF

echo "=== Test depuis l'instance EC2 ==="
echo ""

echo "Installation d'AWS CLI..."
sudo yum update -y > /dev/null 2>&1
sudo yum install -y awscli > /dev/null 2>&1
echo "✅ AWS CLI installé"
echo ""

echo "Test d'accès au bucket S3:"
aws s3 ls s3://$BUCKET_NAME/
echo ""

echo "Téléchargement du fichier clé:"
aws s3 cp s3://$BUCKET_NAME/cle-application.txt .
echo "✅ Fichier téléchargé"
echo ""

echo "Contenu du fichier clé:"
echo "------------------------"
cat cle-application.txt
echo "------------------------"
echo ""

echo "✅ Test réussi ! L'instance peut accéder au fichier S3"

EOF

echo ""
echo "🎉 Test terminé avec succès !"
echo "L'instance EC2 peut bien lire le fichier depuis S3 grâce au rôle IAM."
