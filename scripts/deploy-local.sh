#!/bin/bash
set -e

NAMESPACE=${1:-quiz-app}

echo "🚀 Déploiement local dans le namespace: $NAMESPACE"

# Build l'image Docker
echo "📦 Build de l'image Docker..."
docker build -f docker/backend.Dockerfile -t quiz-backend:local ./backend

# Tag pour K8s local
docker tag quiz-backend:local ghcr.io/your-username/quiz-backend:local

# Redéployer
echo "♻️  Redéploiement..."
kubectl rollout restart deployment/quiz-backend -n $NAMESPACE

# Attendre le rollout
kubectl rollout status deployment/quiz-backend -n $NAMESPACE

echo "✅ Déploiement terminé !"

# Afficher les logs
kubectl logs -f -n $NAMESPACE -l app=quiz-backend --tail=50