#!/bin/bash
set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║  Quiz App - Setup Kubernetes Local    ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Vérifier que Docker Desktop K8s est actif
echo -e "${BLUE}🔍 Vérification de Kubernetes...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Kubernetes n'est pas actif dans Docker Desktop${NC}"
    echo -e "${YELLOW}Activez-le dans : Docker Desktop → Settings → Kubernetes → Enable Kubernetes${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Kubernetes actif${NC}"

# Vérifier le contexte
CONTEXT=$(kubectl config current-context)
echo -e "${BLUE}📍 Contexte actuel: ${CONTEXT}${NC}"

# Créer le namespace
echo -e "${BLUE}📦 Création du namespace quiz-app${NC}"
kubectl apply -f k8s/local/namespace.yaml

# Installer NGINX Ingress Controller
echo -e "${BLUE}🔧 Installation NGINX Ingress Controller${NC}"
if kubectl get namespace ingress-nginx &> /dev/null; then
    echo -e "${YELLOW}⚠️  Ingress Controller déjà installé${NC}"
else
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

    echo -e "${BLUE}⏳ Attente du démarrage de l'Ingress Controller...${NC}"
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=120s
fi
echo -e "${GREEN}✅ Ingress Controller prêt${NC}"

# Déployer PostgreSQL
echo -e "${BLUE}🐘 Déploiement PostgreSQL${NC}"
kubectl apply -f k8s/local/postgres/

echo -e "${BLUE}⏳ Attente du démarrage de PostgreSQL...${NC}"
kubectl wait --namespace quiz-app \
  --for=condition=ready pod \
  --selector=app=postgres \
  --timeout=120s
echo -e "${GREEN}✅ PostgreSQL prêt${NC}"

# Vérifier la connexion à la DB
echo -e "${BLUE}🔄 Test de connexion à PostgreSQL...${NC}"
kubectl exec -n quiz-app postgres-0 -- psql -U quiz_user -d quiz_db -c "SELECT version();" > /dev/null
echo -e "${GREEN}✅ Connexion PostgreSQL OK${NC}"

# Déployer le backend
echo -e "${BLUE}🦀 Déploiement Backend${NC}"
kubectl apply -f k8s/local/quiz-backend/

echo -e "${BLUE}⏳ Attente du démarrage du Backend...${NC}"
kubectl wait --namespace quiz-app \
  --for=condition=ready pod \
  --selector=app=quiz-backend \
  --timeout=120s
echo -e "${GREEN}✅ Backend prêt${NC}"

# Déployer l'Ingress
echo -e "${BLUE}🌐 Configuration Ingress${NC}"
kubectl apply -f k8s/local/ingress.yaml
echo -e "${GREEN}✅ Ingress configuré${NC}"

# Ajouter au /etc/hosts
echo -e "${BLUE}🔧 Configuration /etc/hosts${NC}"
if ! grep -q "quiz-app.local" /etc/hosts; then
    echo "127.0.0.1 quiz-app.local" | sudo tee -a /etc/hosts > /dev/null
    echo -e "${GREEN}✅ Ajout de quiz-app.local dans /etc/hosts${NC}"
else
    echo -e "${YELLOW}⚠️  quiz-app.local déjà dans /etc/hosts${NC}"
fi

# Afficher le statut
echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║       ✅ Setup terminé !               ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${BLUE}🎯 Application accessible sur :${NC}"
echo "   http://quiz-app.local"
echo ""
echo -e "${BLUE}📊 Commandes utiles :${NC}"
echo "   Voir les pods        : kubectl get pods -n quiz-app"
echo "   Voir les services    : kubectl get svc -n quiz-app"
echo "   Voir les logs        : kubectl logs -f -n quiz-app -l app=quiz-backend"
echo "   Interface K9s        : k9s -n quiz-app"
echo ""
echo -e "${BLUE}🔍 Test de l'API :${NC}"
echo "   curl http://quiz-app.local/health"
echo "   curl http://quiz-app.local/api/v1/quizzes"
echo ""