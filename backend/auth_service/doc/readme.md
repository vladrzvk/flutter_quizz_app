# 🔐 Auth Service - Microservice d'Authentification Sécurisé

Service d'authentification autonome et réutilisable avec sécurité maximale.

## 🎯 Caractéristiques de Sécurité

### ✅ Authentification
- **JWT avec rotation** : Tokens à usage unique, révocation automatique
- **HttpOnly Cookies** : Protection XSS
- **Bcrypt/Argon2** : Hashing sécurisé des mots de passe (cost 12+)
- **HTTPS obligatoire** : En production

### ✅ Autorisation
- **RBAC complet** : Rôles et permissions granulaires
- **Format permissions** : `service:action:resource` (ex: `quiz:play:premium`)
- **Vérification ownership** : Protection IDOR
- **Validation serveur stricte** : Pas de confiance client

### ✅ Protection Brute Force
- **Rate limiting** : 5 tentatives/15min par IP
- **Backoff exponentiel** : Délais croissants après échecs
- **CAPTCHA** : Obligatoire après 3 échecs (hCaptcha)
- **Blocage compte** : Après 10 échecs consécutifs
- **Device fingerprinting** : Limitation guests par device (max 3)

### ✅ Quotas
- **Consommation atomique** : SELECT FOR UPDATE + transactions
- **Idempotency** : Clés UUID pour éviter double-consommation
- **Renouvellement sécurisé** : Vérification proof (pub, share, invite)
- **Auto-reset** : Quotas périodiques (daily, weekly, monthly)

### ✅ Sécurité des Données
- **Sanitization HTML** : Ammonia pour inputs utilisateurs
- **Validation stricte** : validator crate
- **DTOs dédiés** : Jamais d'exposition d'entités complètes
- **Secrets masqués** : Logs avec [REDACTED]
- **SQLx avec bind params** : Protection SQL injection

### ✅ Audit & Traçabilité
- **Audit logs** : Toutes actions critiques loggées
- **Login attempts** : Tracking tentatives échecs/succès
- **Session tracking** : IP, User-Agent, Device fingerprint
- **Anomaly detection** : Alertes sur nouveaux devices/IPs

## 📋 Prérequis

- Rust 1.75+
- PostgreSQL 14+
- (Optionnel) hCaptcha account pour CAPTCHA

## 🚀 Installation

### 1. Cloner et configurer

```bash
cd auth-service
cp .env.example .env
```

### 2. Configurer les secrets

**⚠️ IMPORTANT : Changez les secrets en production !**

```bash
# Générer des secrets forts (32+ caractères)
openssl rand -base64 32  # Pour JWT_SECRET
openssl rand -base64 32  # Pour JWT_REFRESH_SECRET
```

### 3. Créer la base de données

```bash
createdb auth_db
psql auth_db < migrations/20251129000001_init_schema.sql
```

### 4. Lancer le service

```bash
cargo run --release
```

Le service démarre sur `http://0.0.0.0:3001`

## 📚 API Endpoints

### Authentification (Publiques)

```bash
# Register
POST /auth/register
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "display_name": "John Doe",
  "locale": "fr"
}

# Login
POST /auth/login
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "captcha_response": "optional-after-3-failures",
  "device_fingerprint": "optional"
}

# Refresh Token
POST /auth/refresh
# Utilise automatiquement le cookie refresh_token

# Logout
POST /auth/logout
# Requiert authentification

# Logout All Sessions
POST /auth/logout-all
# Requiert authentification

# Create Guest
POST /auth/guest
{
  "device_fingerprint": "optional",
  "locale": "fr"
}
```

### Utilisateur (Authentifiées)

```bash
# Get Profile
GET /users/me

# Update Profile
PUT /users/me
{
  "display_name": "New Name",
  "locale": "en"
}

# Change Password
POST /users/me/password
{
  "current_password": "OldPass123!",
  "new_password": "NewPass123!"
}

# Delete Account
DELETE /users/me

# List Sessions
GET /users/me/sessions

# Revoke Session
DELETE /users/me/sessions/{session_id}

# Get Quotas
GET /users/me/quotas
GET /users/me/quotas/{quota_type}

# Consume Quota
POST /users/me/quotas/{quota_type}/consume
{
  "idempotency_key": "optional-uuid"
}

# Renew Quota
POST /users/me/quotas/{quota_type}/renew
{
  "proof": {
    "type": "ad_watched",
    "ad_id": "uuid"
  }
}

# Get Permissions
GET /users/me/permissions

# Check Permission
POST /users/me/permissions/check
{
  "user_id": "uuid",
  "permission": "quiz:play:premium"
}
```

### Admin (Authentifiées + Permissions)

```bash
# List Users
GET /admin/users?page=1&per_page=20&status=free&search=john

# Get User
GET /admin/users/{user_id}

# Update User Status
PUT /admin/users/{user_id}/status
{
  "status": "premium",
  "reason": "Subscription purchased"
}

# Delete User
DELETE /admin/users/{user_id}

# Roles Management
GET /admin/roles
POST /admin/roles
GET /admin/roles/{role_id}
DELETE /admin/roles/{role_id}

# Permissions Management
GET /admin/permissions
POST /admin/permissions
GET /admin/roles/{role_id}/permissions
POST /admin/roles/{role_id}/permissions/{permission_id}
DELETE /admin/roles/{role_id}/permissions/{permission_id}

# User Roles
GET /admin/users/{user_id}/roles
POST /admin/users/{user_id}/roles
DELETE /admin/users/{user_id}/roles/{role_id}
```

## 🔒 Sécurité en Production

### Checklist Obligatoire

- [ ] JWT_SECRET et JWT_REFRESH_SECRET avec 32+ caractères aléatoires
- [ ] HTTPS activé (Secure cookies)
- [ ] CORS_ORIGINS configuré avec whitelist stricte
- [ ] BCRYPT_COST >= 12
- [ ] HCAPTCHA_ENABLED=true avec secret valide
- [ ] Database credentials sécurisées
- [ ] Logs centralisés (ne pas logger les secrets)
- [ ] Rate limiting activé
- [ ] Firewall configuré (port 3001 non public, derrière API Gateway)

### Headers de Sécurité Recommandés

```
Content-Security-Policy: default-src 'self'
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

## 🏗️ Architecture

```
auth-service/
├── src/
│   ├── main.rs                    # Entry point
│   ├── config.rs                  # Configuration
│   ├── error.rs                   # Erreurs centralisées
│   │
│   ├── domain/                    # Domain Layer (Clean Architecture)
│   │   ├── entities.rs            # Entités métier
│   │   └── dtos.rs                # DTOs API
│   │
│   ├── application/               # Application Layer
│   │   └── services/
│   │       ├── auth_service.rs    # Login, register, refresh
│   │       ├── user_service.rs    # Profil, permissions
│   │       ├── quota_service.rs   # Gestion quotas
│   │       ├── jwt_service.rs     # JWT génération/validation
│   │       ├── password_service.rs # Hashing bcrypt
│   │       └── security_service.rs # Rate limit, CAPTCHA
│   │
│   ├── infrastructure/            # Infrastructure Layer
│   │   └── repositories/
│   │       ├── user_repository.rs
│   │       ├── session_repository.rs
│   │       ├── quota_repository.rs
│   │       ├── permission_repository.rs
│   │       └── security_repository.rs
│   │
│   └── presentation/              # Presentation Layer
│       ├── middleware/
│       │   ├── auth.rs            # JWT middleware
│       │   └── rate_limit.rs     # Rate limiting
│       └── routes/
│           ├── auth_routes.rs
│           ├── user_routes.rs
│           └── admin_routes.rs
│
├── migrations/                    # SQL migrations
│   └── 20251129000001_init_schema.sql
│
├── Cargo.toml
├── .env.example
└── README.md
```

## 🧪 Tests

```bash
# Tests unitaires
cargo test

# Tests avec coverage
cargo tarpaulin --out Html

# Tests d'intégration
cargo test --test integration_tests
```

## 📊 Monitoring

### Métriques Importantes

- Nombre de tentatives login échouées / minute
- Sessions actives par utilisateur
- Quotas consommés par type
- Temps de réponse API
- Taux d'erreurs 4xx/5xx

### Logs à Surveiller

- `"Account is locked"` - Comptes bloqués
- `"Rate limit exceeded"` - Attaques potentielles
- `"Anomaly detected"` - Nouveaux devices suspects
- `"CAPTCHA verification failed"` - Bots potentiels

## 🔧 Configuration Avancée

### Performance

```env
# Connection pool
DATABASE_MAX_CONNECTIONS=10

# Bcrypt cost (trade-off sécurité/performance)
# 10 = ~100ms, 12 = ~400ms, 14 = ~1.6s
BCRYPT_COST=12
```

### Sécurité Renforcée

```env
# Rate limiting agressif
RATE_LIMIT_RPM=30
LOGIN_ATTEMPTS_BEFORE_CAPTCHA=2
LOGIN_MAX_ATTEMPTS_BEFORE_BLOCK=5

# Tokens de courte durée
JWT_ACCESS_EXPIRATION_MINUTES=5
JWT_REFRESH_EXPIRATION_DAYS=1
```

## 🐛 Troubleshooting

### Erreur "Invalid token"
- Vérifier que JWT_SECRET est identique partout
- Vérifier que le token n'est pas expiré
- Vérifier que la session n'est pas révoquée

### Erreur "Too many requests"
- Attendre 15 minutes ou augmenter RATE_LIMIT_RPM
- Vérifier que l'IP n'est pas bloquée

### Erreur "CAPTCHA required"
- Fournir captcha_response dans le payload login
- Vérifier HCAPTCHA_SECRET

## 📄 Licence

MIT

## 🤝 Contribution

Les contributions sont bienvenues ! Merci de suivre les guidelines de sécurité.

## 📞 Support

Pour toute question de sécurité, contactez : security@example.com