#!/bin/bash
# Script de nettoyage des ressources AWS

if [ ! -f "infos_exercice_romain.txt" ]; then
    echo "❌ Fichier infos_exercice_romain.txt non trouvé."
    exit 1
fi

echo "🧹 Nettoyage des ressources AWS..."

# Lire les informations
INSTANCE_ID=$(grep "Instance ID:" infos_exercice_romain.txt | cut -d: -f2 | tr -d ' ')
BUCKET_NAME=$(grep "Bucket S3:" infos_exercice_romain.txt | cut -d: -f2 | tr -d ' ')
SG_ID=$(grep "Groupe de sécurité:" infos_exercice_romain.txt | cut -d: -f2 | tr -d ' ')

# Terminer l'instance
echo "Suppression de l'instance EC2..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID 2>/dev/null || true
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID 2>/dev/null || true
echo "✅ Instance supprimée"

# Supprimer le bucket
echo "Suppression du bucket S3..."
aws s3 rm s3://$BUCKET_NAME/ --recursive 2>/dev/null || true
aws s3 rb s3://$BUCKET_NAME/ 2>/dev/null || true
echo "✅ Bucket supprimé"

# Nettoyage IAM
echo "Nettoyage IAM..."
aws iam remove-role-from-instance-profile --instance-profile-name DebutantProfileRomain --role-name DebutantRoleRomain 2>/dev/null || true
aws iam delete-instance-profile --instance-profile-name DebutantProfileRomain 2>/dev/null || true
aws iam delete-role-policy --role-name DebutantRoleRomain --policy-name S3ReadOnlyAccessRomain 2>/dev/null || true
aws iam delete-role --role-name DebutantRoleRomain 2>/dev/null || true
echo "✅ Rôles IAM supprimés"

# Supprimer le groupe de sécurité
echo "Suppression du groupe de sécurité..."
aws ec2 delete-security-group --group-id $SG_ID 2>/dev/null || true
echo "✅ Groupe de sécurité supprimé"

# Supprimer la clé
echo "Suppression de la paire de clés..."
aws ec2 delete-key-pair --key-name exercice-debutant-key-romain 2>/dev/null || true
echo "✅ Clé SSH supprimée"

# Nettoyer les fichiers locaux
rm -f exercice-debutant-key-romain.pem cle-application.txt ec2-s3-policy-romain.json infos_exercice_romain.txt

echo ""
echo "✅ Nettoyage terminé ! Toutes les ressources AWS ont été supprimées."
echo "Vous ne serez plus facturé pour ces ressources."
