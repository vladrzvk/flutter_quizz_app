API GATEWAY - Récapitulatif
Ce qui a été créé
Un API Gateway complet en Rust avec Axum qui:

Route automatiquement vers les 5 microservices
Valide les JWT (auth optionnelle)
Logue toutes les requêtes
Gère les timeouts et erreurs
Prêt pour Docker

Fichiers créés (11 fichiers)
Tous les fichiers sont téléchargeables et placés dans:

backend/api_gateway/ (10 fichiers source)
docker/gateway.Dockerfile (1 fichier)

Guide d'installation
Lire: API-GATEWAY-INSTALLATION.md
Ce guide contient:

Liste des 11 fichiers avec liens de téléchargement
Commandes complètes de placement
Configuration workspace
Tests locaux et Docker
Troubleshooting

Architecture
Client (Flutter App)
↓
API Gateway (8000)
↓
┌───────┬──────────┬──────────┬─────────┐
│       │          │          │         │
Auth  Quiz    Subscription  Offline  Ads
3001  8080      3002        3003    3004
Fonctionnalités

Routage Automatique

Détecte le service cible depuis le path
Proxie la requête complète (headers + body)


Middleware JWT

Extrait et valide le token
Injecte X-User-Id pour services downstream
Auth optionnelle (continue sans token)


Logging

Toutes requêtes loggées
Durée mesurée
Erreurs tracées


CORS

Configuré pour accepter toutes origines (dev)
À restreindre en production


Health Check

GET /health → Status du gateway



Test Rapide
bash# 1. Build
cd backend
cargo build --package api_gateway

# 2. Run
cd api_gateway
cargo run

# 3. Test
curl http://localhost:8000/health
Prochaine Étape
Créer Auth Service et le tester via le Gateway.
Commandes:
bash# Test auth via gateway (après auth service créé)
curl http://localhost:8000/auth/health
curl -X POST http://localhost:8000/auth/register \
-H "Content-Type: application/json" \
-d '{"provider":"email","credentials":{"email":"test@test.com","password":"pass123"}}'
Points d'Attention

JWT_SECRET: Doit être identique entre Gateway et Auth Service
Service URLs: Utiliser noms Docker (ex: http://auth-service:3001) en production
Timeouts: Ajustables via REQUEST_TIMEOUT_SECONDS
CORS: À restreindre en production

