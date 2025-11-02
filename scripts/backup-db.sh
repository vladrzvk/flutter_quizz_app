#!/bin/bash
set -e

NAMESPACE=${1:-quiz-app}
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="quiz_db_${TIMESTAMP}.dump"

echo "💾 Backup de la base de données..."

# Créer le dossier de backup
mkdir -p $BACKUP_DIR

# Exécuter pg_dump
kubectl exec -n $NAMESPACE postgres-0 -- \
  pg_dump -U quiz_user -Fc quiz_db > "${BACKUP_DIR}/${BACKUP_FILE}"

echo "✅ Backup créé: ${BACKUP_DIR}/${BACKUP_FILE}"
echo "📊 Taille: $(du -h ${BACKUP_DIR}/${BACKUP_FILE} | cut -f1)"

# Garder seulement les 7 derniers backups
echo "🧹 Nettoyage des anciens backups..."
ls -t ${BACKUP_DIR}/quiz_db_*.dump | tail -n +8 | xargs -r rm -f

echo "✅ Backup terminé !"