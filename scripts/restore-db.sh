#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <backup-file>"
    echo "Exemple: $0 backups/quiz_db_20251101_123456.dump"
    exit 1
fi

BACKUP_FILE=$1
NAMESPACE=${2:-quiz-app}

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Fichier introuvable: $BACKUP_FILE"
    exit 1
fi

echo "⚠️  Attention: Cette opération va écraser la base de données actuelle !"
read -p "Continuer? (yes/no) " -n 3 -r
echo
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Annulé."
    exit 1
fi

echo "📥 Restauration de: $BACKUP_FILE"

# Copier le fichier dans le pod
kubectl cp $BACKUP_FILE $NAMESPACE/postgres-0:/tmp/restore.dump

# Restaurer
kubectl exec -n $NAMESPACE postgres-0 -- \
  pg_restore -U quiz_user -d quiz_db --clean --if-exists /tmp/restore.dump

# Nettoyer
kubectl exec -n $NAMESPACE postgres-0 -- rm /tmp/restore.dump

echo "✅ Restauration terminée !"