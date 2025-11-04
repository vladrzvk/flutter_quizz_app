#!/bin/bash
set -e

NAMESPACE=${1:-quiz-app}

echo "🧹 Nettoyage du namespace: $NAMESPACE"

# Supprimer tous les déploiements
kubectl delete all --all -n $NAMESPACE

# Supprimer les ConfigMaps et Secrets
kubectl delete configmap --all -n $NAMESPACE
kubectl delete secret --all -n $NAMESPACE

# Supprimer les PVCs
kubectl delete pvc --all -n $NAMESPACE

# Supprimer l'Ingress
kubectl delete ingress --all -n $NAMESPACE

echo "✅ Nettoyage terminé !"