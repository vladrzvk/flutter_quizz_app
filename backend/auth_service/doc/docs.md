# 🔐 AUTH SERVICE - Documentation Technique Complète

**Version:** 1.0.0  
**Date:** 5 Décembre 2025  
**Stack:** Rust + Axum + PostgreSQL + mTLS

---

## 📑 Table des Matières

1. [Vue d'Ensemble](#1-vue-densemble)
2. [Architecture](#2-architecture)
3. [Sécurité mTLS](#3-sécurité-mtls)
4. [Base de Données](#4-base-de-données)
5. [API Documentation](#5-api-documentation)
6. [Authentification & Autorisation](#6-authentification--autorisation)
7. [Quotas & Rate Limiting](#7-quotas--rate-limiting)
8. [Déploiement](#8-déploiement)
9. [Monitoring](#9-monitoring)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Vue d'Ensemble

### 🎯 Objectif

Service d'authentification **autonome et réutilisable** avec sécurité maximale :
- **JWT avec rotation** (tokens à usage unique)
- **RBAC complet** (rôles et permissions granulaires)
- **mTLS service-to-service** (authentification mutuelle)
- **Protection brute force** (rate limiting, CAPTCHA, backoff)
- **Gestion quotas** (avec renouvellement idempotent)
- **Audit complet** (tracking de toutes actions critiques)

### 📊 Caractéristiques Clés

| Feature | Description | Status |
|---------|-------------|--------|
| **JWT Stateful** | Tokens révocables avec rotation | ✅ |
| **mTLS** | Authentification service-to-service | ✅ |
| **RBAC** | Rôles + Permissions granulaires | ✅ |
| **Rate Limiting** | Protection brute force avancée | ✅ |
| **Quotas** | Gestion quotas avec idempotency | ✅ |
| **Guest Accounts** | Comptes temporaires limités | ✅ |
| **Audit Logs** | Traçabilité complète | ✅ |
| **Device Tracking** | Empreintes devices (limitation guests) | ✅ |

### 🏗️ Principes Architecturaux

1. **Clean Architecture** : Domain → Application → Infrastructure → Presentation
2. **Découplage Total** : Auth service ne connaît PAS le domaine métier
3. **Sécurité First** : Toutes décisions priorisent la sécurité
4. **Idempotence** : Consommation quotas avec clés UUID
5. **Observabilité** : Logs structurés + audit trails

---

## 2. Architecture

### 🏛️ Architecture Globale

```
┌─────────────────────────────────────────────────────────────────┐
│                     EXTERNAL CLIENTS                             │
│                  (Browser, Mobile App)                           │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTPS
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│                       API GATEWAY                                │
│                  (mTLS + JWT Validation)                         │
└────────┬───────────────────────────────────┬────────────────────┘
         │ mTLS                              │ mTLS
         ↓                                   ↓
┌────────────────────┐            ┌────────────────────┐
│   AUTH SERVICE     │            │   QUIZ SERVICE     │
│   (Port 3001)      │            │   (Port 3002)      │
│                    │            │                    │
│ ┌────────────────┐ │            │ - Vérifie perms   │
│ │ AUTH           │ │            │ - Consomme quotas │
│ │ - Login        │ │            │ - Business logic  │
│ │ - Register     │ │            │                    │
│ │ - JWT          │ │            │                    │
│ └────────────────┘ │            └────────────────────┘
│ ┌────────────────┐ │                     ↓
│ │ USERS          │ │            ┌────────────────────┐
│ │ - CRUD         │ │            │   FILE SERVICE     │
│ │ - Profile      │ │            │   (Port 3003)      │
│ │ - Quotas       │ │            └────────────────────┘
│ └────────────────┘ │
│ ┌────────────────┐ │
│ │ PERMISSIONS    │ │
│ │ - RBAC         │ │
│ │ - ACL Check    │ │
│ └────────────────┘ │
└──────────┬─────────┘
           │
           ↓
┌─────────────────────┐
│   PostgreSQL        │
│   auth_db           │
└─────────────────────┘
```

### 📦 Structure du Code (Clean Architecture)

```
auth-service/
├── src/
│   ├── main.rs                      # Entry point + Server setup
│   ├── config.rs                    # Configuration (ENV vars)
│   ├── error.rs                     # Erreurs centralisées
│   │
│   ├── mtls/                        # 🔐 mTLS Module
│   │   ├── mod.rs
│   │   ├── config.rs                # Configuration mTLS
│   │   └── server.rs                # TlsAcceptor setup
│   │
│   ├── domain/                      # 🎨 Domain Layer
│   │   ├── entities.rs              # User, Role, Permission, Quota
│   │   └── dtos.rs                  # DTOs pour API
│   │
│   ├── application/                 # 🧠 Application Layer
│   │   └── services/
│   │       ├── auth_service.rs      # Login, register, refresh
│   │       ├── user_service.rs      # CRUD users + permissions
│   │       ├── quota_service.rs     # Gestion quotas
│   │       ├── jwt_service.rs       # JWT generation/validation
│   │       ├── password_service.rs  # Bcrypt hashing
│   │       └── security_service.rs  # Rate limit, CAPTCHA
│   │
│   ├── infrastructure/              # 🗄️ Infrastructure Layer
│   │   └── repositories/
│   │       ├── user_repository.rs
│   │       ├── session_repository.rs
│   │       ├── quota_repository.rs
│   │       ├── permission_repository.rs
│   │       └── security_repository.rs
│   │
│   └── presentation/                # 📡 Presentation Layer
│       ├── middleware/
│       │   ├── auth.rs              # JWT middleware
│       │   ├── rate_limit.rs        # Rate limiting
│       │   └── mtls.rs              # mTLS validation (optionnel)
│       └── routes/
│           ├── auth_routes.rs       # /auth/*
│           ├── user_routes.rs       # /users/*
│           ├── admin_routes.rs      # /admin/*
│           └── health_routes.rs     # /health, /ready
│
├── migrations/                      # SQL migrations
│   ├── 20251129000001_init_schema.sql
│   ├── 20251129000002_seed_data.sql
│   └── 20251205000003_add_mtls_tracking.sql
│
├── Dockerfile
├── Cargo.toml
└── .env.example
```

### 🔄 Flow d'une Requête

#### Authentification Client → Service

```
1. Client (Browser)
   POST /auth/login
   ↓
2. API Gateway
   - Rate limiting
   - Forward à Auth Service (mTLS)
   ↓
3. Auth Service
   - Valider credentials
   - Vérifier rate limit
   - CAPTCHA si >3 échecs
   - Générer JWT (access + refresh)
   - INSERT jwt_sessions
   - INSERT audit_logs
   ↓
4. Response
   {
     "access_token": "...",
     "refresh_token": "..." (HttpOnly cookie)
   }
```

#### Service-to-Service (mTLS)

```
1. Quiz Service veut vérifier permission
   ↓
2. mTLS Handshake
   - Quiz Service présente certificat client
   - Auth Service valide certificat via CA
   - Auth Service vérifie CN dans trusted_services
   ↓
3. Auth Service
   - Log connexion dans mtls_connections
   - Traite requête (check permission)
   - Log dans audit_logs (avec client_cert_cn)
   ↓
4. Response
   { "has_permission": true }
```

---

## 3. Sécurité mTLS

### 🔒 Qu'est-ce que mTLS ?

**Mutual TLS (mTLS)** = Authentification **bidirectionnelle** via certificats :
- Client authentifie serveur (TLS classique)
- **Serveur authentifie client** (ajout mTLS)

**Bénéfices** :
- ✅ Zero-trust entre services
- ✅ Pas besoin de API keys en clair
- ✅ Protection man-in-the-middle
- ✅ Whitelist services autorisés

### 📜 Génération des Certificats

#### 1. Créer une CA (Certificate Authority)

```bash
# Générer clé privée CA
openssl genrsa -out ca-key.pem 4096

# Générer certificat CA (auto-signé)
openssl req -new -x509 -key ca-key.pem -out ca-cert.pem -days 3650 \
  -subj "/C=FR/ST=IDF/L=Paris/O=MyOrg/OU=IT/CN=MyCA"
```

#### 2. Créer certificat serveur (Auth Service)

```bash
# Clé privée serveur
openssl genrsa -out server-key.pem 4096

# CSR (Certificate Signing Request)
openssl req -new -key server-key.pem -out server.csr \
  -subj "/C=FR/ST=IDF/L=Paris/O=MyOrg/CN=auth-service.internal"

# Signer avec CA
openssl x509 -req -in server.csr -CA ca-cert.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -days 365

# Nettoyer
rm server.csr
```

#### 3. Créer certificats clients (services)

```bash
# Quiz Service
openssl genrsa -out quiz-service-key.pem 4096
openssl req -new -key quiz-service-key.pem -out quiz-service.csr \
  -subj "/C=FR/ST=IDF/L=Paris/O=MyOrg/CN=quiz-service.internal"
openssl x509 -req -in quiz-service.csr -CA ca-cert.pem -CAkey ca-key.pem \
  -CAcreateserial -out quiz-service-cert.pem -days 365

# API Gateway
openssl genrsa -out gateway-key.pem 4096
openssl req -new -key gateway-key.pem -out gateway.csr \
  -subj "/C=FR/ST=IDF/L=Paris/O=MyOrg/CN=api-gateway.internal"
openssl x509 -req -in gateway.csr -CA ca-cert.pem -CAkey ca-key.pem \
  -CAcreateserial -out gateway-cert.pem -days 365
```

#### 4. Organisation des certificats

```
certs/
├── ca/
│   ├── ca-cert.pem      # À partager avec tous les services
│   └── ca-key.pem       # ⚠️ GARDER SECRET
├── auth-service/
│   ├── server-cert.pem
│   └── server-key.pem
├── quiz-service/
│   ├── client-cert.pem
│   └── client-key.pem
└── api-gateway/
    ├── client-cert.pem
    └── client-key.pem
```

### ⚙️ Configuration mTLS

#### Variables d'environnement (Auth Service)

```env
# mTLS Configuration
MTLS_ENABLED=true
MTLS_REQUIRE_CLIENT_CERT=true

# Certificats serveur
MTLS_SERVER_CERT=/etc/mtls/certs/server-cert.pem
MTLS_SERVER_KEY=/etc/mtls/certs/server-key.pem

# CA pour valider clients
MTLS_CLIENT_CA_CERT=/etc/mtls/certs/ca-cert.pem
```

#### Code Rust (simplifié)

```rust
// src/mtls/config.rs
pub struct MtlsConfig {
    pub enabled: bool,
    pub server_cert_path: PathBuf,
    pub server_key_path: PathBuf,
    pub client_ca_cert_path: PathBuf,
    pub require_client_cert: bool,
}

// src/mtls/server.rs
pub fn create_mtls_acceptor(config: &MtlsConfig) -> Result<TlsAcceptor> {
    // Charger certificat serveur
    let cert_chain = load_certs(&config.server_cert_path)?;
    let private_key = load_private_key(&config.server_key_path)?;
    
    // Charger CA pour valider clients
    let root_store = load_ca_certs(&config.client_ca_cert_path)?;
    
    // Configurer avec validation client obligatoire
    let config = ServerConfig::builder()
        .with_client_cert_verifier(
            WebPkiClientVerifier::builder(Arc::new(root_store)).build()?
        )
        .with_single_cert(cert_chain, private_key)?;
    
    Ok(TlsAcceptor::from(Arc::new(config)))
}
```

### 🔍 Validation & Tracking

#### 1. Middleware mTLS (optionnel)

```rust
// src/presentation/middleware/mtls.rs
pub async fn validate_mtls_client(
    Extension(tls_info): Extension<TlsConnectionInfo>,
    State(pool): State<PgPool>,
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    // Extraire CN du certificat client
    let client_cn = tls_info.peer_certificates()
        .and_then(|certs| extract_cn(&certs[0]))
        .ok_or(StatusCode::UNAUTHORIZED)?;
    
    // Vérifier dans trusted_services
    let is_trusted = sqlx::query_scalar::<_, bool>(
        "SELECT is_service_trusted($1)"
    )
    .bind(&client_cn)
    .fetch_one(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    if !is_trusted {
        // Log tentative rejetée
        log_mtls_connection(&pool, &client_cn, false, Some("Service not trusted")).await;
        return Err(StatusCode::FORBIDDEN);
    }
    
    // Log connexion réussie
    log_mtls_connection(&pool, &client_cn, true, None).await;
    
    // Injecter dans extensions pour audit
    request.extensions_mut().insert(MtlsContext { 
        client_cn: client_cn.clone() 
    });
    
    Ok(next.run(request).await)
}
```

#### 2. Tracking en base de données

```sql
-- Log automatique via fonction
SELECT log_mtls_connection(
    'quiz-service.internal',  -- CN certificat
    true,                      -- succès
    '/api/permissions/check',  -- endpoint
    '10.0.0.5'::inet           -- IP
);

-- Vue monitoring
SELECT * FROM mtls_service_stats;
-- service_name      | total_connections | success_rate_percent
-- quiz-service      | 1234              | 99.8
-- api-gateway       | 5678              | 100.0
```

### 🚀 Intégration Client (Quiz Service)

```rust
// Quiz Service appelle Auth Service via mTLS
use reqwest::Certificate;
use std::fs;

let ca_cert = fs::read("/etc/mtls/certs/ca-cert.pem")?;
let client_cert = fs::read("/etc/mtls/certs/client-cert.pem")?;
let client_key = fs::read("/etc/mtls/certs/client-key.pem")?;

let client = reqwest::Client::builder()
    .add_root_certificate(Certificate::from_pem(&ca_cert)?)
    .identity(reqwest::Identity::from_pem(&[&client_cert[..], &client_key[..]].concat())?)
    .build()?;

// Appel avec mTLS
let response = client
    .post("https://auth-service.internal:3001/api/permissions/check")
    .json(&CheckPermissionRequest { ... })
    .send()
    .await?;
```

---

## 4. Base de Données

### 📊 Schéma Complet

#### Tables Principales

```sql
-- USERS : Utilisateurs (permanents + guests)
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE,            -- NULL pour guests
    password_hash VARCHAR(255),           -- NULL pour guests
    status VARCHAR(20) NOT NULL,          -- free, premium, trial, suspended
    is_guest BOOLEAN DEFAULT false,
    display_name VARCHAR(100),
    analytics_consent BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ROLES : Rôles système
CREATE TABLE roles (
    id UUID PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,     -- guest, free, premium, admin
    priority INT DEFAULT 0,               -- Hiérarchie
    is_system BOOLEAN DEFAULT false
);

-- PERMISSIONS : Format service:action:resource
CREATE TABLE permissions (
    id UUID PRIMARY KEY,
    service VARCHAR(50) NOT NULL,         -- quiz, subscription, admin
    action VARCHAR(50) NOT NULL,          -- play, create, manage
    resource VARCHAR(100) NOT NULL,       -- free, premium, all
    name VARCHAR(100) UNIQUE NOT NULL,    -- quiz:play:premium
    UNIQUE(service, action, resource)
);

-- USER_ROLES : Many-to-Many
CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id),
    role_id UUID REFERENCES roles(id),
    expires_at TIMESTAMPTZ,               -- NULL = permanent
    PRIMARY KEY (user_id, role_id)
);

-- ROLE_PERMISSIONS : Many-to-Many
CREATE TABLE role_permissions (
    role_id UUID REFERENCES roles(id),
    permission_id UUID REFERENCES permissions(id),
    PRIMARY KEY (role_id, permission_id)
);
```

#### Tables Quotas

```sql
-- USER_QUOTAS : Quotas par utilisateur
CREATE TABLE user_quotas (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    quota_type VARCHAR(50) NOT NULL,      -- quiz_plays, file_conversions
    max_allowed INT NOT NULL,
    current_usage INT DEFAULT 0,
    period_type VARCHAR(20),              -- daily, weekly, monthly, null
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,
    can_renew BOOLEAN DEFAULT false,
    renew_action VARCHAR(50),             -- watch_ad, share, invite
    UNIQUE(user_id, quota_type)
);

-- QUOTA_CONSUMPTIONS : Idempotency
CREATE TABLE quota_consumptions (
    id UUID PRIMARY KEY,
    idempotency_key UUID UNIQUE NOT NULL,
    quota_id UUID REFERENCES user_quotas(id),
    consumed_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Tables Sécurité

```sql
-- JWT_SESSIONS : Tokens révocables
CREATE TABLE jwt_sessions (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    access_token_hash VARCHAR(255) NOT NULL,
    refresh_token_hash VARCHAR(255),
    issued_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    ip_address INET,
    user_agent TEXT,
    device_fingerprint VARCHAR(255),
    revoked_at TIMESTAMPTZ,
    client_cert_cn VARCHAR(255),          -- 🔐 mTLS tracking
    created_by_service VARCHAR(50)        -- 🔐 Service qui a créé
);

-- LOGIN_ATTEMPTS : Rate limiting
CREATE TABLE login_attempts (
    id UUID PRIMARY KEY,
    email VARCHAR(255),
    ip_address INET NOT NULL,
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(100),
    attempted_at TIMESTAMPTZ DEFAULT NOW()
);

-- DEVICE_FINGERPRINTS : Limitation guests
CREATE TABLE device_fingerprints (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    fingerprint VARCHAR(255) NOT NULL,
    first_seen_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, fingerprint)
);

-- AUDIT_LOGS : Traçabilité
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    action VARCHAR(50) NOT NULL,          -- login, register, permission_granted
    resource_type VARCHAR(50),            -- user, role, permission
    resource_id UUID,
    ip_address INET,
    old_value JSONB,
    new_value JSONB,
    client_cert_cn VARCHAR(255),          -- 🔐 Service via mTLS
    service_name VARCHAR(50),             -- 🔐 Nom du service
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### Tables mTLS 🔐

```sql
-- TRUSTED_SERVICES : Whitelist services autorisés
CREATE TABLE trusted_services (
    id UUID PRIMARY KEY,
    service_name VARCHAR(50) UNIQUE NOT NULL,  -- quiz-service, gateway
    certificate_cn VARCHAR(255) NOT NULL,      -- CN du certificat attendu
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- MTLS_CONNECTIONS : Logs connexions mTLS
CREATE TABLE mtls_connections (
    id UUID PRIMARY KEY,
    service_id UUID REFERENCES trusted_services(id),
    certificate_cn VARCHAR(255) NOT NULL,
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(100),
    endpoint VARCHAR(100),
    ip_address INET,
    connected_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 📈 Vues Utiles

```sql
-- Vue : Permissions effectives utilisateur
CREATE VIEW user_effective_permissions AS
SELECT DISTINCT
    u.id AS user_id,
    p.name AS permission_name,
    p.service, p.action, p.resource
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
JOIN role_permissions rp ON ur.role_id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE u.deleted_at IS NULL
  AND (ur.expires_at IS NULL OR ur.expires_at > NOW());

-- Vue : Sessions actives
CREATE VIEW active_sessions AS
SELECT js.*, u.email, u.status
FROM jwt_sessions js
JOIN users u ON js.user_id = u.id
WHERE js.revoked_at IS NULL
  AND js.expires_at > NOW();

-- Vue : Stats mTLS par service
CREATE VIEW mtls_service_stats AS
SELECT 
    ts.service_name,
    COUNT(mc.id) AS total_connections,
    COUNT(mc.id) FILTER (WHERE mc.success) AS successful,
    ROUND(100.0 * COUNT(mc.id) FILTER (WHERE mc.success) / COUNT(mc.id), 2) AS success_rate
FROM trusted_services ts
LEFT JOIN mtls_connections mc ON ts.id = mc.service_id
WHERE mc.connected_at > NOW() - INTERVAL '7 days'
GROUP BY ts.service_name;
```

### 🔧 Fonctions SQL Utiles

```sql
-- Vérifier si service est trusted
CREATE FUNCTION is_service_trusted(cert_cn VARCHAR(255))
RETURNS BOOLEAN AS $$
    SELECT EXISTS(
        SELECT 1 FROM trusted_services
        WHERE certificate_cn = cert_cn AND enabled = true
    );
$$ LANGUAGE sql STABLE;

-- Logger connexion mTLS
CREATE FUNCTION log_mtls_connection(
    cert_cn VARCHAR(255),
    success BOOLEAN,
    endpoint VARCHAR(100) DEFAULT NULL,
    ip INET DEFAULT NULL
) RETURNS UUID AS $$
    INSERT INTO mtls_connections (certificate_cn, success, endpoint, ip_address)
    VALUES (cert_cn, success, endpoint, ip)
    RETURNING id;
$$ LANGUAGE sql;
```

---

## 5. API Documentation

### 🔑 Authentification

#### POST `/auth/register` - Créer compte permanent

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "display_name": "John Doe",
  "locale": "fr"
}
```

**Response 201:**
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "status": "free",
    "is_guest": false,
    "display_name": "John Doe"
  },
  "tokens": {
    "access_token": "eyJhbGc...",
    "expires_in": 900
  }
}
```

**Cookies:**
- `refresh_token` (HttpOnly, Secure, SameSite=Strict)

**Errors:**
- `400` : Email invalide, mot de passe faible
- `409` : Email déjà utilisé
- `429` : Rate limit dépassé

---

#### POST `/auth/login` - Connexion

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "captcha_response": "optional-after-3-failures",
  "device_fingerprint": "abc123def456"
}
```

**Response 200:**
```json
{
  "user": { ... },
  "tokens": {
    "access_token": "eyJhbGc...",
    "expires_in": 900
  }
}
```

**Errors:**
- `401` : Credentials invalides
- `403` : Compte suspendu, CAPTCHA requis
- `429` : Trop de tentatives (15 min)

**Sécurité:**
- Après **3 échecs** : CAPTCHA obligatoire
- Après **5 échecs** : Blocage temporaire 15min
- Après **10 échecs** : Blocage compte

---

#### POST `/auth/guest` - Créer compte invité

**Request:**
```json
{
  "device_fingerprint": "abc123def456",
  "locale": "fr"
}
```

**Response 201:**
```json
{
  "user": {
    "id": "...",
    "status": "free",
    "is_guest": true,
    "quotas": {
      "quiz_plays": {
        "remaining": 3,
        "max": 3,
        "can_renew": true
      }
    }
  },
  "tokens": { ... }
}
```

**Limites:**
- Max **3 guests** par device_fingerprint
- Quotas limités (3 quiz plays/jour)

---

#### POST `/auth/refresh` - Renouveler JWT

**Request:** (Cookie `refresh_token` automatique)

**Response 200:**
```json
{
  "access_token": "eyJhbGc...",
  "expires_in": 900
}
```

**Sécurité:**
- Ancien refresh_token **révoqué** immédiatement
- Nouveau refresh_token dans cookie
- **Rotation complète** des tokens

---

#### POST `/auth/logout` - Déconnexion

**Headers:** `Authorization: Bearer <access_token>`

**Response 204:** (No Content)

**Action:**
- Révoque session courante
- Supprime cookie refresh_token

---

#### POST `/auth/logout-all` - Déconnexion partout

**Headers:** `Authorization: Bearer <access_token>`

**Response 204:**

**Action:**
- Révoque **toutes** les sessions utilisateur
- Force re-login sur tous devices

---

### 👤 Utilisateur

#### GET `/users/me` - Profil utilisateur

**Headers:** `Authorization: Bearer <access_token>`

**Response 200:**
```json
{
  "id": "...",
  "email": "user@example.com",
  "status": "premium",
  "is_guest": false,
  "display_name": "John Doe",
  "avatar_url": "https://...",
  "analytics_consent": true,
  "locale": "fr",
  "created_at": "2025-01-15T10:30:00Z"
}
```

---

#### PUT `/users/me` - Modifier profil

**Request:**
```json
{
  "display_name": "Jane Doe",
  "avatar_url": "https://...",
  "locale": "en",
  "analytics_consent": false
}
```

**Response 200:** (User complet)

**Validation:**
- `display_name` : 3-100 caractères, sanitized HTML
- `locale` : ISO 639-1 (fr, en, es, etc.)

---

#### POST `/users/me/password` - Changer mot de passe

**Request:**
```json
{
  "current_password": "OldPass123!",
  "new_password": "NewPass456!"
}
```

**Response 204:**

**Sécurité:**
- Vérifie ancien mot de passe
- Nouveau mot de passe >= 8 caractères
- Révoque **toutes** les sessions sauf courante

---

#### DELETE `/users/me` - Supprimer compte

**Headers:** `Authorization: Bearer <access_token>`

**Response 204:**

**Action:**
- Soft delete (`deleted_at`)
- Révoque toutes sessions
- Garde données audit (anonymisées)

---

#### GET `/users/me/sessions` - Liste sessions actives

**Response 200:**
```json
{
  "sessions": [
    {
      "id": "...",
      "ip_address": "192.168.1.10",
      "user_agent": "Mozilla/5.0...",
      "device_fingerprint": "abc123",
      "issued_at": "2025-12-05T10:00:00Z",
      "expires_at": "2025-12-12T10:00:00Z",
      "is_current": true
    }
  ]
}
```

---

#### DELETE `/users/me/sessions/{session_id}` - Révoquer session

**Response 204:**

**Action:**
- Révoque session spécifique
- Force re-login sur ce device

---

### 📊 Quotas

#### GET `/users/me/quotas` - Liste quotas

**Response 200:**
```json
{
  "quotas": [
    {
      "type": "quiz_plays",
      "max_allowed": 10,
      "current_usage": 7,
      "remaining": 3,
      "period_type": "daily",
      "period_end": "2025-12-06T00:00:00Z",
      "can_renew": true,
      "renew_action": "watch_ad"
    }
  ]
}
```

---

#### POST `/users/me/quotas/{quota_type}/consume` - Consommer quota

**Request:**
```json
{
  "idempotency_key": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response 200:**
```json
{
  "success": true,
  "quota": {
    "type": "quiz_plays",
    "remaining": 2
  }
}
```

**Errors:**
- `403` : Quota épuisé
- `409` : Idempotency_key déjà utilisée (retourne même résultat)

**Sécurité:**
- Transaction SQL avec `SELECT FOR UPDATE`
- Clé idempotency évite double-consommation
- Atomique et thread-safe

---

#### POST `/users/me/quotas/{quota_type}/renew` - Renouveler quota

**Request:**
```json
{
  "proof": {
    "type": "ad_watched",
    "ad_id": "550e8400-...",
    "timestamp": "2025-12-05T14:30:00Z"
  }
}
```

**Response 200:**
```json
{
  "success": true,
  "quota": {
    "type": "quiz_plays",
    "remaining": 5,
    "renewed_at": "2025-12-05T14:30:00Z"
  }
}
```

**Validations:**
- Vérifie `proof` auprès du Ads Service
- `current_usage` remis à 0
- Log dans `audit_logs`

---

### 🔐 Permissions

#### GET `/users/me/permissions` - Liste permissions effectives

**Response 200:**
```json
{
  "permissions": [
    "quiz:play:free",
    "quiz:play:premium",
    "quiz:create:own",
    "user:read:self",
    "user:update:self"
  ]
}
```

---

#### POST `/users/me/permissions/check` - Vérifier permission

**Request:**
```json
{
  "user_id": "550e8400-...",
  "permission": "quiz:play:premium"
}
```

**Response 200:**
```json
{
  "has_permission": true
}
```

**Usage (Service-to-Service via mTLS):**
```rust
// Quiz Service vérifie permission
let response = auth_client
    .check_permission(user_id, "quiz:play:premium")
    .await?;

if !response.has_permission {
    return Err(AppError::Forbidden("Premium required"));
}
```

---

### 👑 Admin

*(Requiert permission `admin:manage:*`)*

#### GET `/admin/users` - Liste utilisateurs

**Query Params:**
- `page` (default: 1)
- `per_page` (default: 20, max: 100)
- `status` (free, premium, trial, suspended)
- `search` (email, display_name)

**Response 200:**
```json
{
  "users": [ ... ],
  "pagination": {
    "current_page": 1,
    "per_page": 20,
    "total_pages": 5,
    "total_count": 95
  }
}
```

---

#### PUT `/admin/users/{user_id}/status` - Modifier statut

**Request:**
```json
{
  "status": "premium",
  "reason": "Manual upgrade by admin"
}
```

**Response 200:**

**Actions:**
- Update status
- Log dans `audit_logs`
- Notification utilisateur (optionnel)

---

### 💚 Health

#### GET `/health` - Health check

**Response 200:**
```json
{
  "status": "ok",
  "database": "connected",
  "mtls": "enabled"
}
```

---

#### GET `/ready` - Readiness probe

**Response 200/503:**
```json
{
  "ready": true,
  "checks": {
    "database": "ok",
    "migrations": "up-to-date"
  }
}
```

---

## 6. Authentification & Autorisation

### 🔑 JWT Structure

#### Access Token (15 min)

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "status": "premium",
  "is_guest": false,
  "permissions": [
    "quiz:play:free",
    "quiz:play:premium"
  ],
  "iat": 1733400000,
  "exp": 1733400900
}
```

#### Refresh Token (7 jours)

```json
{
  "sub": "550e8400-...",
  "type": "refresh",
  "session_id": "abc123-...",
  "iat": 1733400000,
  "exp": 1734004800
}
```

### 🛡️ Middleware Auth

```rust
// Extraction JWT + validation
pub async fn auth_middleware(
    State((pool, jwt_service)): State<(PgPool, JwtService)>,
    mut request: Request,
    next: Next,
) -> Result<Response, AuthError> {
    // 1. Extraire token depuis header
    let token = extract_token_from_header(&request)?;
    
    // 2. Valider JWT (signature + expiration)
    let claims = jwt_service.validate_access_token(&token)?;
    
    // 3. Vérifier session non révoquée
    let session = SessionRepository::find_by_token_hash(&pool, &token).await?;
    if session.revoked_at.is_some() {
        return Err(AuthError::SessionRevoked);
    }
    
    // 4. Injecter context dans extensions
    let context = AuthContext {
        user_id: claims.sub,
        status: claims.status,
        is_guest: claims.is_guest,
        permissions: claims.permissions,
    };
    request.extensions_mut().insert(context);
    
    Ok(next.run(request).await)
}
```

### 🎭 RBAC (Role-Based Access Control)

#### Hiérarchie des rôles

```
admin (priority: 100)
  ├─ Toutes permissions
  └─ Accès panel admin
  
premium (priority: 50)
  ├─ quiz:play:free
  ├─ quiz:play:premium
  ├─ quiz:create:own
  └─ ads:skip:interstitial

free (priority: 10)
  ├─ quiz:play:free
  └─ quiz:create:own

guest (priority: 0)
  └─ quiz:play:free (quotas limités)
```

#### Vérification permission

```rust
pub async fn check_permission(
    pool: &PgPool,
    user_id: Uuid,
    required_permission: &str,
) -> Result<bool, AppError> {
    let has_permission = sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS(
            SELECT 1 FROM user_effective_permissions
            WHERE user_id = $1 AND permission_name = $2
        )
        "#
    )
    .bind(user_id)
    .bind(required_permission)
    .fetch_one(pool)
    .await?;
    
    Ok(has_permission)
}
```

---

## 7. Quotas & Rate Limiting

### 📊 Gestion Quotas

#### Consommation atomique

```rust
pub async fn consume_quota(
    pool: &PgPool,
    user_id: Uuid,
    quota_type: &str,
    idempotency_key: Uuid,
) -> Result<QuotaConsumption, QuotaError> {
    let mut tx = pool.begin().await?;
    
    // 1. Vérifier idempotency
    if let Some(existing) = check_idempotency_key(&mut tx, idempotency_key).await? {
        return Ok(existing); // Déjà consommé, retourner même résultat
    }
    
    // 2. SELECT FOR UPDATE (lock pessimiste)
    let quota = sqlx::query_as::<_, UserQuota>(
        "SELECT * FROM user_quotas WHERE user_id = $1 AND quota_type = $2 FOR UPDATE"
    )
    .bind(user_id)
    .bind(quota_type)
    .fetch_one(&mut *tx)
    .await?;
    
    // 3. Vérifier disponibilité
    if quota.current_usage >= quota.max_allowed {
        return Err(QuotaError::Exhausted);
    }
    
    // 4. Incrémenter usage
    sqlx::query(
        "UPDATE user_quotas SET current_usage = current_usage + 1 WHERE id = $1"
    )
    .bind(quota.id)
    .execute(&mut *tx)
    .await?;
    
    // 5. Enregistrer consommation
    sqlx::query(
        "INSERT INTO quota_consumptions (idempotency_key, quota_id) VALUES ($1, $2)"
    )
    .bind(idempotency_key)
    .bind(quota.id)
    .execute(&mut *tx)
    .await?;
    
    tx.commit().await?;
    
    Ok(QuotaConsumption { ... })
}
```

#### Auto-reset périodique

```sql
-- Cron job (exécuter chaque nuit)
UPDATE user_quotas
SET current_usage = 0,
    period_start = NOW(),
    period_end = CASE period_type
        WHEN 'daily' THEN NOW() + INTERVAL '1 day'
        WHEN 'weekly' THEN NOW() + INTERVAL '7 days'
        WHEN 'monthly' THEN NOW() + INTERVAL '1 month'
    END
WHERE period_end < NOW()
  AND period_type IS NOT NULL;
```

### 🚦 Rate Limiting

#### Configuration

```env
RATE_LIMIT_RPM=60                    # 60 requêtes/minute par IP
LOGIN_ATTEMPTS_BEFORE_CAPTCHA=3      # CAPTCHA après 3 échecs
LOGIN_MAX_ATTEMPTS_BEFORE_BLOCK=5    # Blocage après 5 échecs
LOGIN_BLOCK_DURATION_MINUTES=15      # Durée blocage
```

#### Implémentation

```rust
pub async fn check_rate_limit(
    pool: &PgPool,
    ip: &IpAddr,
    window_minutes: i32,
) -> Result<(), RateLimitError> {
    let attempts = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*)
        FROM login_attempts
        WHERE ip_address = $1
          AND attempted_at > NOW() - $2 * INTERVAL '1 minute'
        "#
    )
    .bind(ip)
    .bind(window_minutes)
    .fetch_one(pool)
    .await?;
    
    if attempts >= 5 {
        return Err(RateLimitError::TooManyAttempts {
            retry_after: window_minutes * 60,
        });
    }
    
    Ok(())
}
```

#### Backoff exponentiel

| Tentative | Délai |
|-----------|-------|
| 1-2 | 0s |
| 3 | 1s |
| 4 | 2s |
| 5 | 4s |
| 6+ | 15 min |

---

## 8. Déploiement

### 🐳 Docker

#### Dockerfile

```dockerfile
FROM rust:1.75-alpine AS builder

WORKDIR /app

# Dependencies
RUN apk add --no-cache musl-dev openssl-dev

# Build
COPY Cargo.* ./
RUN cargo fetch

COPY src ./src
RUN cargo build --release

# Runtime
FROM alpine:3.19

RUN apk add --no-cache openssl ca-certificates

COPY --from=builder /app/target/release/auth-service /usr/local/bin/

# mTLS certificates (volume mount)
VOLUME ["/etc/mtls/certs"]

EXPOSE 3001

CMD ["auth-service"]
```

#### docker-compose.yml

```yaml
version: '3.8'

services:
  auth-service:
    build: .
    ports:
      - "3001:3001"
    environment:
      DATABASE_URL: postgresql://user:pass@postgres:5432/auth_db
      JWT_SECRET: ${JWT_SECRET}
      MTLS_ENABLED: "true"
      MTLS_SERVER_CERT: /etc/mtls/certs/server-cert.pem
      MTLS_SERVER_KEY: /etc/mtls/certs/server-key.pem
      MTLS_CLIENT_CA_CERT: /etc/mtls/certs/ca-cert.pem
    volumes:
      - ./certs:/etc/mtls/certs:ro
    depends_on:
      - postgres
    
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: auth_db
      POSTGRES_USER: auth_user
      POSTGRES_PASSWORD: secure_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./migrations:/docker-entrypoint-initdb.d:ro

volumes:
  postgres_data:
```

### ☸️ Kubernetes

#### Secrets

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: auth-service-secrets
type: Opaque
stringData:
  jwt-secret: "your-32-char-secret"
  jwt-refresh-secret: "your-32-char-refresh-secret"
  database-url: "postgresql://..."
  hcaptcha-secret: "your-hcaptcha-secret"
```

```yaml
# mTLS certificates (from files)
apiVersion: v1
kind: Secret
metadata:
  name: auth-service-mtls-certs
type: Opaque
data:
  server-cert.pem: <base64>
  server-key.pem: <base64>
  ca-cert.pem: <base64>
```

#### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
    spec:
      containers:
      - name: auth-service
        image: your-registry/auth-service:v1.0.0
        ports:
        - containerPort: 3001
        env:
        - name: MTLS_ENABLED
          value: "true"
        - name: MTLS_SERVER_CERT
          value: /etc/mtls/certs/server-cert.pem
        - name: MTLS_SERVER_KEY
          value: /etc/mtls/certs/server-key.pem
        - name: MTLS_CLIENT_CA_CERT
          value: /etc/mtls/certs/ca-cert.pem
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: auth-service-secrets
              key: jwt-secret
        volumeMounts:
        - name: mtls-certs
          mountPath: /etc/mtls/certs
          readOnly: true
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
            scheme: HTTPS
          initialDelaySeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: 3001
            scheme: HTTPS
          initialDelaySeconds: 10
      volumes:
      - name: mtls-certs
        secret:
          secretName: auth-service-mtls-certs
```

#### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: auth-service
spec:
  type: ClusterIP
  ports:
  - port: 3001
    targetPort: 3001
    protocol: TCP
    name: https
  selector:
    app: auth-service
```

### 🔄 CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy Auth Service

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker image
        run: docker build -t auth-service:${{ github.sha }} .
      
      - name: Push to registry
        run: |
          docker tag auth-service:${{ github.sha }} registry/auth-service:latest
          docker push registry/auth-service:latest
      
      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/auth-service \
            auth-service=registry/auth-service:${{ github.sha }}
          kubectl rollout status deployment/auth-service
```

---

## 9. Monitoring

### 📊 Métriques Clés

```rust
// À implémenter avec prometheus crate
use prometheus::{IntCounterVec, HistogramVec};

lazy_static! {
    static ref LOGIN_ATTEMPTS: IntCounterVec = IntCounterVec::new(
        Opts::new("auth_login_attempts_total", "Total login attempts"),
        &["status"] // success, failed_password, failed_captcha
    ).unwrap();
    
    static ref JWT_VALIDATIONS: HistogramVec = HistogramVec::new(
        histogram_opts!("auth_jwt_validation_duration_seconds", "JWT validation duration"),
        &["status"] // valid, invalid, expired
    ).unwrap();
    
    static ref QUOTA_CONSUMPTIONS: IntCounterVec = IntCounterVec::new(
        Opts::new("auth_quota_consumptions_total", "Quota consumptions"),
        &["quota_type", "status"] // success, exhausted, error
    ).unwrap();
    
    static ref MTLS_CONNECTIONS: IntCounterVec = IntCounterVec::new(
        Opts::new("auth_mtls_connections_total", "mTLS connections"),
        &["service", "status"] // success, rejected
    ).unwrap();
}
```

### 📈 Dashboard Grafana

**Panels recommandés:**
- Login success rate (%)
- Active sessions (gauge)
- Failed login attempts (rate)
- mTLS connections per service
- Quota consumption by type
- JWT validation latency (p50, p95, p99)
- Database connection pool usage

### 🚨 Alertes

```yaml
# Prometheus alerts
groups:
- name: auth_service
  rules:
  - alert: HighLoginFailureRate
    expr: |
      rate(auth_login_attempts_total{status="failed"}[5m]) > 10
    for: 5m
    annotations:
      summary: "High login failure rate"
      description: "More than 10 failed logins/sec in last 5min"
  
  - alert: mTLSConnectionsRejected
    expr: |
      rate(auth_mtls_connections_total{status="rejected"}[5m]) > 1
    for: 2m
    annotations:
      summary: "mTLS connections being rejected"
      description: "Service {{ $labels.service }} has rejected connections"
  
  - alert: DatabaseConnectionPoolExhausted
    expr: |
      sqlx_pool_connections_active / sqlx_pool_connections_max > 0.9
    for: 5m
    annotations:
      summary: "Database connection pool nearly exhausted"
```

### 📝 Logs Structurés

```rust
use tracing::{info, warn, error};

// Login success
info!(
    user_id = %user.id,
    email = %user.email,
    ip = %ip_address,
    "User logged in successfully"
);

// mTLS connection
info!(
    service = %service_name,
    cert_cn = %cert_cn,
    endpoint = %endpoint,
    "mTLS connection established"
);

// Quota consumed
info!(
    user_id = %user_id,
    quota_type = %quota_type,
    remaining = %remaining,
    "Quota consumed"
);

// Suspicious activity
warn!(
    ip = %ip_address,
    attempts = %attempts,
    "Rate limit threshold reached"
);
```

---

## 10. Troubleshooting

### ❌ Erreur "Invalid token"

**Causes:**
1. JWT expiré
2. JWT_SECRET différent entre services
3. Session révoquée

**Diagnostic:**
```bash
# Vérifier expiration
jwt decode <token>

# Vérifier session
psql -c "SELECT * FROM jwt_sessions WHERE access_token_hash = '...';"
```

**Solutions:**
- Refresh token
- Vérifier JWT_SECRET identique partout
- Logout/login si session révoquée

---

### ❌ Erreur "mTLS handshake failed"

**Causes:**
1. Certificat client invalide/expiré
2. CN pas dans trusted_services
3. CA certificate incorrect

**Diagnostic:**
```bash
# Tester connexion mTLS
openssl s_client -connect auth-service:3001 \
  -cert client-cert.pem -key client-key.pem \
  -CAfile ca-cert.pem

# Vérifier CN certificat
openssl x509 -in client-cert.pem -noout -subject

# Vérifier trusted_services
psql -c "SELECT * FROM trusted_services WHERE certificate_cn = 'quiz-service.internal';"
```

**Solutions:**
- Renouveler certificat si expiré
- Ajouter service dans trusted_services
- Vérifier que CA est la bonne

---

### ❌ Erreur "Too many requests"

**Causes:**
1. Rate limit IP dépassé
2. Trop de tentatives login échouées

**Diagnostic:**
```sql
-- Tentatives récentes
SELECT * FROM login_attempts
WHERE ip_address = '192.168.1.10'
  AND attempted_at > NOW() - INTERVAL '15 minutes';
```

**Solutions:**
- Attendre 15 minutes
- Utiliser CAPTCHA
- Contacter admin si blocage abusif

---

### ❌ Erreur "Quota exhausted"

**Causes:**
1. Quota consommé
2. Période non renouvelée

**Diagnostic:**
```sql
SELECT * FROM user_quotas
WHERE user_id = '...' AND quota_type = 'quiz_plays';
```

**Solutions:**
- Renouveler quota (watch ad, share, etc.)
- Attendre reset automatique (daily/weekly)
- Upgrade vers premium

---

### 🔍 Debugging Production

```bash
# Logs en temps réel
kubectl logs -f deployment/auth-service

# Logs avec filtre
kubectl logs deployment/auth-service | grep "ERROR"

# Métriques Prometheus
curl http://auth-service:3001/metrics

# État base de données
kubectl exec -it postgres-pod -- psql auth_db -c "
  SELECT
    (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL) AS total_users,
    (SELECT COUNT(*) FROM active_sessions) AS active_sessions,
    (SELECT COUNT(*) FROM mtls_connections WHERE connected_at > NOW() - INTERVAL '1 hour') AS mtls_last_hour;
"
```

---

## 📚 Références

### Technologies

- **Rust**: https://www.rust-lang.org/
- **Axum**: https://github.com/tokio-rs/axum
- **SQLx**: https://github.com/launchbadge/sqlx
- **rustls**: https://github.com/rustls/rustls
- **jsonwebtoken**: https://github.com/Keats/jsonwebtoken

### Standards

- **RFC 7519** (JWT): https://tools.ietf.org/html/rfc7519
- **RFC 6749** (OAuth2): https://tools.ietf.org/html/rfc6749
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/

### Best Practices

- **NIST Password Guidelines**: https://pages.nist.gov/800-63-3/
- **mTLS Security**: https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/

---

## 📝 Changelog

### v1.0.0 (2025-12-05)
- ✅ mTLS support complet avec tracking
- ✅ RBAC avec permissions granulaires
- ✅ Gestion quotas avec idempotency
- ✅ Rate limiting avancé (backoff + CAPTCHA)
- ✅ Audit logs complet
- ✅ Device fingerprinting pour guests
- ✅ JWT stateful avec révocation
- ✅ Clean Architecture

---

## 🤝 Support

Pour toute question :
- **Documentation**: Ce fichier
- **Issues**: GitHub Issues
- **Security**: security@example.com

---

