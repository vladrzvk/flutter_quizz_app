.PHONY: help setup build test deploy clean

# Variables
NAMESPACE ?= quiz-app
DOCKER_IMAGE ?= quiz-backend
DOCKER_TAG ?= latest

help: ## Afficher cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup
setup: ## Setup initial (K8s local)
	@echo "🚀 Setup de l'environnement local..."
	@./scripts/setup-k8s-local.sh

# Build
build-backend: ## Build l'image Docker du backend
	@echo "📦 Build de l'image Docker..."
	@docker build -f docker/backend.Dockerfile -t $(DOCKER_IMAGE):$(DOCKER_TAG) ./backend

build-frontend: ## Build l'app Flutter
	@echo "📱 Build de l'app Flutter..."
	@cd frontend && flutter build apk --debug

# Tests
test-backend: ## Lancer les tests backend
	@echo "🧪 Tests backend..."
	@cd backend/quiz_core_service && cargo test

test-frontend: ## Lancer les tests frontend
	@echo "🧪 Tests frontend..."
	@cd frontend && flutter test

test: test-backend test-frontend ## Lancer tous les tests

# Deploy
deploy-local: build-backend ## Déployer localement
	@echo "🚀 Déploiement local..."
	@./scripts/deploy-local.sh $(NAMESPACE)

# Database
db-backup: ## Backup de la base de données
	@echo "💾 Backup de la DB..."
	@./scripts/backup-db.sh $(NAMESPACE)

db-restore: ## Restaurer la base de données
	@echo "📥 Restauration de la DB..."
	@./scripts/restore-db.sh $(BACKUP_FILE) $(NAMESPACE)

# Logs
logs-backend: ## Voir les logs du backend
	@kubectl logs -f -n $(NAMESPACE) -l app=quiz-backend

logs-postgres: ## Voir les logs PostgreSQL
	@kubectl logs -f -n $(NAMESPACE) postgres-0

# Monitoring
k9s: ## Lancer k9s
	@k9s -n $(NAMESPACE)

port-forward: ## Port-forward vers le backend
	@kubectl port-forward -n $(NAMESPACE) svc/quiz-backend 8080:8080

# Cleanup
clean: ## Nettoyer l'environnement
	@echo "🧹 Nettoyage..."
	@./scripts/cleanup.sh $(NAMESPACE)

clean-docker: ## Nettoyer les images Docker
	@docker system prune -a --volumes -f

# Development
dev-backend: ## Lancer le backend en mode dev
	@cd backend/quiz_core_service && cargo watch -x run

dev-frontend: ## Lancer le frontend en mode dev
	@cd frontend && flutter run -d chrome