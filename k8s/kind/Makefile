# k8s/kind/Makefile
# Makefile pour gestion cluster kind

.PHONY: help check-kubectl check-docker create-cluster install-ingress build-image deploy verify clean

# Couleurs (Windows PowerShell)
CYAN := "\033[36m"
GREEN := "\033[32m"
YELLOW := "\033[33m"
RED := "\033[31m"
RESET := "\033[0m"

##@ Aide

help: ## Afficher cette aide
	@echo "Commandes disponibles pour kind cluster :"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup

check-kubectl: ## Verifier kubectl
	@echo "Verification kubectl..."
	@kubectl version --client || (echo "ERREUR: kubectl non trouve. Installez avec: choco install kubernetes-cli" && exit 1)

check-docker: ## Verifier Docker Desktop
	@echo "Verification Docker Desktop..."
	@docker ps > nul 2>&1 || (echo "ERREUR: Docker Desktop non lance" && exit 1)

create-cluster: check-kubectl check-docker ## Creer cluster kind via Docker Desktop
	@echo ""
	@echo "=========================================="
	@echo "Creation cluster kind"
	@echo "=========================================="
	@echo ""
	@echo "IMPORTANT: Creez le cluster via Docker Desktop UI"
	@echo ""
	@echo "Etapes:"
	@echo "  1. Ouvrir Docker Desktop"
	@echo "  2. Aller dans Kubernetes"
	@echo "  3. Cliquer 'Create' ou '+'"
	@echo "  4. Selectionner 'kind'"
	@echo "  5. Regler nodes : 3"
	@echo "  6. Cliquer 'Create'"
	@echo "  7. Attendre 2-3 minutes"
	@echo ""
	@echo "Appuyez sur Entree quand termine..."
	@pause
	@echo ""
	@echo "Verification cluster..."
	@kubectl get nodes
	@echo ""

install-ingress: ## Installer NGINX Ingress Controller
	@echo "Installation NGINX Ingress..."
	#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/kind/deploy.yaml
	kubectl apply -f k8s/kind/manifests/000-my-ingress.yaml
	@echo "Attente demarrage (30s)..."
	@timeout /t 30 /nobreak > nul
	kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
	@echo "Ingress Controller pret"

##@ Build & Deploy

build-image: ## Build image backend
	@echo "Build image backend..."
	cd ..\..\backend && docker build -t quiz-backend:local -f ..\..\docker\backend-dev.Dockerfile .
	@echo "Image prete (automatiquement disponible dans kind)"

deploy: ## Deployer application
	@echo "Deploiement application..."
	kubectl apply -f manifests/
	@echo ""
	@echo "Attente PostgreSQL..."
	kubectl wait --for=condition=ready pod -l app=postgres -n quiz-app --timeout=120s
	@echo ""
	@echo "Application deployee"

##@ Verification

verify: ## Verifier deploiement
	@echo "Verification deploiement..."
	@echo ""
	@echo "=== Nodes ==="
	kubectl get nodes
	@echo ""
	@echo "=== Pods ==="
	kubectl get pods -n quiz-app
	@echo ""
	@echo "=== Services ==="
	kubectl get svc -n quiz-app
	@echo ""
	@echo "=== Ingress ==="
	kubectl get ingress -n quiz-app
	@echo ""

status: ## Status complet
	kubectl get all -n quiz-app

logs-backend: ## Logs backend
	kubectl logs -f deployment/quiz-backend -n quiz-app

logs-postgres: ## Logs PostgreSQL
	kubectl logs -f statefulset/postgres -n quiz-app

##@ Tests

test-health: ## Test health endpoint
	@echo "Test health check..."
	curl http://quiz-app.local/health

test-api: ## Test API
	@echo "Test API..."
	curl http://quiz-app.local/api/v1/quizzes

shell-backend: ## Shell dans pod backend
	kubectl exec -it deployment/quiz-backend -n quiz-app -- sh

shell-postgres: ## Shell dans PostgreSQL
	kubectl exec -it statefulset/postgres -n quiz-app -- sh

##@ Nettoyage

clean-app: ## Supprimer application seulement
	kubectl delete namespace quiz-app

clean-ingress: ## Supprimer Ingress Controller
	kubectl delete namespace ingress-nginx

clean: ## Supprimer tout (app + ingress)
	kubectl delete namespace quiz-app ingress-nginx

##@ Workflow Complet

setup: check-kubectl check-docker create-cluster install-ingress ## Setup complet (sans build)
	@echo ""
	@echo "=========================================="
	@echo "Setup termine"
	@echo "=========================================="
	@echo ""
	@echo "Prochaines etapes:"
	@echo "  make build-image"
	@echo "  make deploy"
	@echo "  make verify"
	@echo ""

all: setup build-image deploy verify ## Workflow complet
	@echo ""
	@echo "=========================================="
	@echo "Deploiement termine"
	@echo "=========================================="
	@echo ""
	@echo "Testez avec:"
	@echo "  curl http://quiz-app.local/health"
	@echo ""

# Valeur par defaut
.DEFAULT_GOAL := help