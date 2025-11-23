# backend/quiz_core_service/Makefile
# Commandes pratiques pour le développement

.PHONY: help fmt check test test-db coverage clean db-up db-down db-reset

# Couleurs
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

##@ Aide

help: ## Afficher cette aide
	@echo "$(CYAN)Commandes disponibles :$(RESET)"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-15s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Formatage & Qualité du Code

fmt: ## Formater le code Rust
	@echo "$(CYAN) Formatage du code...$(RESET)"
	@cargo fmt
	@echo "$(GREEN) Code formaté$(RESET)"

check: ## Vérifier le formatage
	@echo "$(CYAN) Vérification du formatage...$(RESET)"
	@cargo fmt -- --check
	@echo "$(GREEN) Formatage OK$(RESET)"

clippy: ## Lancer Clippy (linter)
	@echo "$(CYAN)📎 Clippy linting...$(RESET)"
	@cargo clippy -- -D warnings
	@echo "$(GREEN) Clippy OK$(RESET)"

lint: check clippy ## Format check + Clippy

##@ Base de Données de Test

db-up: ## Démarrer la DB de test
	@echo "$(CYAN) Démarrage de la DB test...$(RESET)"
	@docker-compose -f ../docker-compose.test.yml up -d
	@echo "$(GREEN) DB test démarrée sur port 5433$(RESET)"

db-down: ## Arrêter la DB de test
	@echo "$(CYAN) Arrêt de la DB test...$(RESET)"
	@docker-compose -f ../docker-compose.test.yml down
	@echo "$(GREEN) DB test arrêtée$(RESET)"

db-reset: ## Reset complet de la DB test
	@echo "$(CYAN) Reset de la DB test...$(RESET)"
	@docker-compose -f ../docker-compose.test.yml down -v
	@docker-compose -f ../docker-compose.test.yml up -d
	@sleep 2
	@echo "$(GREEN) DB test réinitialisée$(RESET)"

db-logs: ## Voir les logs de la DB
	@docker-compose -f ../docker-compose.test.yml logs -f postgres-test

##@ Tests

test-db: db-up ## Lancer les tests (démarre DB automatiquement)
	@echo "$(CYAN) Lancement des tests...$(RESET)"
	@sleep 2
	@cargo test -- --test-threads=1
	@echo "$(GREEN) Tests terminés$(RESET)"

test: ## Lancer les tests (DB doit être démarrée)
	@echo "$(CYAN) Lancement des tests...$(RESET)"
	@cargo test --verbose
	@echo "$(GREEN) Tests terminés$(RESET)"

test-one: ## Lancer un test spécifique (usage: make test-one TEST=nom_du_test)
	@echo "$(CYAN) Test: $(TEST)$(RESET)"
	@cargo test $(TEST) -- --nocapture

test-api: ## Lancer seulement les tests API
	@echo "$(CYAN) Tests API...$(RESET)"
	@cargo test api_ --verbose

test-unit: ## Lancer seulement les tests unitaires
	@echo "$(CYAN)  Tests unitaires...$(RESET)"
	@cargo test --lib --verbose

##@ Coverage

coverage: db-up ## Générer le rapport de coverage (HTML)
	@echo "$(CYAN) Génération du coverage...$(RESET)"
	@sleep 2
	@cargo llvm-cov --html --open
	@echo "$(GREEN) Coverage généré$(RESET)"

coverage-summary: ## Afficher le résumé du coverage
	@echo "$(CYAN) Coverage summary...$(RESET)"
	@cargo llvm-cov --summary-only

coverage-json: ## Générer coverage en JSON (pour Codecov)
	@echo "$(CYAN) Génération coverage JSON...$(RESET)"
	@cargo llvm-cov --codecov --output-path codecov.json
	@echo "$(GREEN) codecov.json généré$(RESET)"

##@ Build

build: ## Compiler le projet
	@echo "$(CYAN) Compilation...$(RESET)"
	@cargo build
	@echo "$(GREEN) Build OK$(RESET)"

build-release: ## Compiler en mode release
	@echo "$(CYAN) Compilation release...$(RESET)"
	@cargo build --release
	@echo "$(GREEN) Build release OK$(RESET)"

run: ## Lancer le serveur en mode dev
	@echo "$(CYAN) Démarrage du serveur...$(RESET)"
	@cargo run

##@ Nettoyage

clean: ## Nettoyer les artifacts de build
	@echo "$(CYAN) Nettoyage...$(RESET)"
	@cargo clean
	@echo "$(GREEN) Nettoyage terminé$(RESET)"

clean-all: clean db-down ## Nettoyage complet (build + DB)
	@echo "$(GREEN) Nettoyage complet terminé$(RESET)"

##@ Workflow Complet

ci: fmt clippy test-db ## Workflow CI complet (format + lint + tests)
	@echo "$(GREEN) CI OK$(RESET)"

dev: db-up ## Setup environnement de dev
	@echo "$(CYAN)🔧 Environnement de dev prêt$(RESET)"
	@echo "$(YELLOW)DB test : postgresql://quiz_user:quiz_test@localhost:5433/quiz_db_test$(RESET)"
	@echo "$(YELLOW)Lancer tests : make test$(RESET)"
	@echo "$(YELLOW)Coverage : make coverage$(RESET)"

# Valeur par défaut
.DEFAULT_GOAL := help