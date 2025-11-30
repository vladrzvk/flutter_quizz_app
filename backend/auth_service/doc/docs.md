Plan d'Implémentation Auth Service - Version Adaptée
🎯 Vision Globale
Service Auth autonome et réutilisable qui peut se greffer sur N'IMPORTE QUEL projet, avec un système de permissions granulaire et gestion avancée des guests.

🏗️ Architecture du Service Auth
Principe de Découplage
┌─────────────────────────────────────────────────────────────┐
│                    AUTH SERVICE (Port 3001)                  │
│                  (Autonome & Réutilisable)                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │     AUTH     │  │    USERS     │  │ PERMISSIONS  │     │
│  │              │  │              │  │              │     │
│  │ - Login      │  │ - CRUD       │  │ - RBAC       │     │
│  │ - Register   │  │ - Profile    │  │ - ACL        │     │
│  │ - JWT        │  │ - Quotas     │  │ - Grants     │     │
│  │ - Refresh    │  │ - Guests     │  │ - Rules      │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
│                           │
│ JWT + Headers             │ Vérification permissions
↓                           ↓
┌──────────────────┐         ┌──────────────────┐
│   API GATEWAY    │ ──────→ │  QUIZ SERVICE    │
│                  │         │                  │
│ X-User-Id        │         │ user_id (UUID)   │
│ X-Status         │         │ quiz_id          │
│ X-Permissions    │         │ session_id       │
└──────────────────┘         └──────────────────┘
Règle fondamentale :

Auth Service NE CONNAÎT PAS le domaine métier (quiz, files, etc.)
Il gère uniquement : Users + Auth + Permissions génériques
Les services métier interrogent Auth pour vérifier les droits


📊 Modèle de Données Complet
Base de données : auth_db
sql-- ============================================
-- USERS : Utilisateurs du système
-- ============================================
CREATE TABLE users (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Authentification
    email VARCHAR(255) UNIQUE,              -- Null pour guests
    password_hash VARCHAR(255),             -- Null pour guests
    
    -- Statut & Type
    status VARCHAR(20) NOT NULL             -- 'free', 'premium', 'trial'
        CHECK (status IN ('free', 'premium', 'trial', 'suspended')),
    is_guest BOOLEAN DEFAULT false,
    
    -- Profil
    display_name VARCHAR(100),
    avatar_url TEXT,
    
    -- Consentements & Préférences
    analytics_consent BOOLEAN DEFAULT false,
    marketing_consent BOOLEAN DEFAULT false,
    locale VARCHAR(10) DEFAULT 'fr',
    
    -- Quotas (pour guests notamment)
    quota_data JSONB DEFAULT '{}'::jsonb,   -- Stockage flexible des quotas
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    
    -- Soft delete
    deleted_at TIMESTAMPTZ
);

-- Index
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_is_guest ON users(is_guest);


-- ============================================
-- ROLES : Rôles utilisateurs
-- ============================================
CREATE TABLE roles (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
name VARCHAR(50) UNIQUE NOT NULL,       -- 'guest', 'free', 'premium', 'admin'
description TEXT,
priority INT DEFAULT 0,                 -- Ordre hiérarchique (0 = lowest)

    -- Configuration
    is_system BOOLEAN DEFAULT false,        -- Rôles système non supprimables
    metadata JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================
-- PERMISSIONS : Permissions granulaires
-- ============================================
CREATE TABLE permissions (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Format: "service:action:resource"
    service VARCHAR(50) NOT NULL,           -- 'quiz', 'subscription', 'ads'
    action VARCHAR(50) NOT NULL,            -- 'play', 'create', 'view', 'skip'
    resource VARCHAR(100) NOT NULL,         -- 'free', 'premium', 'own', '*'
    
    -- Description
    name VARCHAR(100) UNIQUE NOT NULL,      -- 'quiz:play:premium'
    description TEXT,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(service, action, resource)
);


-- ============================================
-- ASSOCIATIONS : Many-to-Many
-- ============================================
CREATE TABLE user_roles (
user_id UUID REFERENCES users(id) ON DELETE CASCADE,
role_id UUID REFERENCES roles(id) ON DELETE CASCADE,

    -- Metadata (ex: date d'expiration pour trial)
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb,
    
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE role_permissions (
role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,

    granted_at TIMESTAMPTZ DEFAULT NOW(),
    
    PRIMARY KEY (role_id, permission_id)
);


-- ============================================
-- QUOTAS : Gestion des quotas utilisateurs
-- ============================================
CREATE TABLE user_quotas (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    -- Type de quota
    quota_type VARCHAR(50) NOT NULL,        -- 'quiz_plays', 'file_conversions', etc.
    
    -- Limites
    max_allowed INT NOT NULL,               -- Limite maximale
    current_usage INT DEFAULT 0,            -- Utilisation actuelle
    
    -- Période de renouvellement
    period_type VARCHAR(20),                -- 'daily', 'weekly', 'monthly', null
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,
    
    -- Renouvellement (ex: regarder une pub)
    can_renew BOOLEAN DEFAULT false,
    renew_action VARCHAR(50),               -- 'watch_ad', 'share', 'invite'
    
    metadata JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, quota_type)
);


-- ============================================
-- SESSIONS JWT : Gestion des tokens (optionnel mais recommandé)
-- ============================================
CREATE TABLE jwt_sessions (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    -- Token
    token_hash VARCHAR(255) NOT NULL,       -- Hash du JWT pour révocation
    refresh_token_hash VARCHAR(255),
    
    -- Validité
    issued_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    
    -- Tracking
    ip_address INET,
    user_agent TEXT,
    
    -- Révocation
    revoked_at TIMESTAMPTZ,
    revoke_reason VARCHAR(100),
    
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_jwt_sessions_user ON jwt_sessions(user_id);
CREATE INDEX idx_jwt_sessions_token_hash ON jwt_sessions(token_hash);
CREATE INDEX idx_jwt_sessions_expires ON jwt_sessions(expires_at)
WHERE revoked_at IS NULL;


-- ============================================
-- AUDIT LOG : Traçabilité des actions critiques
-- ============================================
CREATE TABLE audit_logs (
id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID,                           -- Null si action système
    action VARCHAR(50) NOT NULL,            -- 'login', 'register', 'permission_granted'
    resource_type VARCHAR(50),              -- 'user', 'role', 'permission'
    resource_id UUID,
    
    -- Contexte
    ip_address INET,
    user_agent TEXT,
    
    -- Détails
    old_value JSONB,
    new_value JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);

🎨 Modèle Domaine (Clean Architecture)
Entities
rust// domain/entities/user.rs
pub struct User {
pub id: Uuid,
pub email: Option<String>,
pub password_hash: Option<String>,
pub status: UserStatus,
pub is_guest: bool,
pub display_name: Option<String>,
pub avatar_url: Option<String>,
pub analytics_consent: bool,
pub marketing_consent: bool,
pub locale: String,
pub quota_data: serde_json::Value,
pub metadata: serde_json::Value,
pub created_at: DateTime<Utc>,
pub updated_at: DateTime<Utc>,
pub last_login_at: Option<DateTime<Utc>>,
}

// domain/entities/role.rs
pub struct Role {
pub id: Uuid,
pub name: String,
pub description: Option<String>,
pub priority: i32,
pub is_system: bool,
pub permissions: Vec<Permission>,  // Chargé via join
}

// domain/entities/permission.rs
pub struct Permission {
pub id: Uuid,
pub service: String,
pub action: String,
pub resource: String,
pub name: String,  // Format: "service:action:resource"
pub description: Option<String>,
}

// domain/entities/quota.rs
pub struct UserQuota {
pub id: Uuid,
pub user_id: Uuid,
pub quota_type: String,
pub max_allowed: i32,
pub current_usage: i32,
pub period_type: Option<PeriodType>,
pub period_start: Option<DateTime<Utc>>,
pub period_end: Option<DateTime<Utc>>,
pub can_renew: bool,
pub renew_action: Option<String>,
}

pub enum PeriodType {
Daily,
Weekly,
Monthly,
}
```

---

## 🔄 Flux d'Utilisation Détaillés

### **1. Création Guest avec Quotas**
```
Mobile App → Auth Service:
POST /auth/guest
{
"device_id": "abc123",
"locale": "fr"
}

Auth Service crée:
1. users (is_guest=true, status='free')
2. user_roles (role='guest')
3. user_quotas (quota_type='quiz_plays', max=5, can_renew=true, renew_action='watch_ad')

Response:
{
"access_token": "JWT...",
"refresh_token": "JWT...",
"user": {
"id": "...",
"is_guest": true,
"status": "free",
"quotas": [
{
"type": "quiz_plays",
"remaining": 5,
"can_renew": true,
"renew_action": "watch_ad"
}
]
}
}
```

### **2. Vérification Permission Avant Action**
```
Quiz Service → Auth Service:
POST /permissions/check
{
"user_id": "...",
"permission": "quiz:play:premium",
"context": {
"quiz_id": "..."
}
}

Auth Service vérifie:
1. Récupère user + roles
2. Récupère permissions via role_permissions
3. Vérifie si "quiz:play:premium" dans la liste
4. Vérifie quotas si applicable

Response:
{
"allowed": false,
"reason": "insufficient_permissions",
"required": ["premium"],
"current": ["free"]
}
```

### **3. Renouvellement Quota (Pub regardée)**
```
Ads Service → Auth Service:
POST /users/{user_id}/quotas/renew
{
"quota_type": "quiz_plays",
"renew_action": "watch_ad",
"ad_id": "..."
}

Auth Service:
1. Vérifie que can_renew=true
2. Vérifie que renew_action='watch_ad'
3. Reset current_usage=0
4. Log dans audit_logs

Response:
{
"success": true,
"quota": {
"type": "quiz_plays",
"remaining": 5,
"renewed_at": "2025-11-29T..."
}
}
```

### **4. Promotion Guest → User Permanent**
```
App → Auth Service:
POST /users/{guest_id}/convert
{
"email": "user@example.com",
"password": "...",
"keep_data": true
}

Auth Service:
1. UPDATE users SET is_guest=false, email=..., password_hash=...
2. Préserve les quotas/sessions existants
3. Optionnel: upgrade role 'guest' → 'free'

Response:
{
"success": true,
"user": { ... },
"new_tokens": { ... }
}
```

---

## 📡 API Endpoints Complets

### **Module Auth**
```
POST   /auth/register          # Créer compte permanent
POST   /auth/login             # Connexion
POST   /auth/guest             # Créer guest
POST   /auth/refresh           # Renouveler JWT
POST   /auth/logout            # Révoquer session
POST   /auth/verify            # Vérifier JWT (pour gateway)
```

### **Module Users**
```
GET    /users/{id}             # Récupérer profil
PUT    /users/{id}             # Modifier profil
DELETE /users/{id}             # Supprimer compte
POST   /users/{id}/convert     # Guest → Permanent

GET    /users/{id}/quotas      # Liste quotas
POST   /users/{id}/quotas/renew # Renouveler quota
```

### **Module Permissions**
```
GET    /permissions            # Liste permissions disponibles
POST   /permissions/check      # Vérifier permission user

GET    /roles                  # Liste rôles
GET    /roles/{id}/permissions # Permissions d'un rôle

POST   /users/{id}/roles       # Assigner rôle
DELETE /users/{id}/roles/{role_id} # Retirer rôle

🔧 Adaptations Nécessaires
API Gateway (Modifications)
rust// middleware/auth.rs - Enrichir Claims
pub struct Claims {
pub sub: String,
pub is_guest: bool,
pub status: String,
pub analytics_consent: bool,
pub permissions: Vec<String>,  // ✅ NOUVEAU
pub quotas: serde_json::Value, // ✅ NOUVEAU
pub exp: i64,
}

// Enrichir headers pour services
fn enrich_request_headers(request: &mut Request, claims: &Claims) {
headers.insert("X-User-Id", claims.sub);
headers.insert("X-Status", claims.status);
headers.insert("X-Is-Guest", claims.is_guest.to_string());
headers.insert("X-Permissions", claims.permissions.join(",")); // ✅ NOUVEAU
}
Quiz Service (Modifications)
rust// services/session_service.rs
pub async fn start_session(
pool: &PgPool,
quiz_id: Uuid,
request: StartSessionRequest,
) -> Result<SessionQuiz, AppError> {
let quiz = QuizRepository::find_by_id(pool, quiz_id).await?;

    // ✅ NOUVEAU : Vérifier permission
    if quiz.access_level == AccessLevel::Premium {
        let has_permission = auth_client
            .check_permission(
                request.user_id,
                "quiz:play:premium"
            )
            .await?;
        
        if !has_permission {
            return Err(AppError::Forbidden(
                "Premium subscription required"
            ));
        }
    }
    
    // ✅ NOUVEAU : Vérifier & consommer quota
    if quiz.consumes_quota {
        auth_client
            .consume_quota(request.user_id, "quiz_plays")
            .await?;
    }
    
    // ... reste du code
}

📅 Plan de Migration & Implémentation
Phase 1 : Fondations (Semaine 1-2)
Objectif : Service fonctionnel avec auth basique
Livrables :

✅ Structure Clean Architecture complète
✅ Tables : users, roles, permissions, user_roles, role_permissions
✅ Entities + Repositories + Services
✅ Endpoints : /auth/register, /auth/login, /auth/guest, /auth/refresh
✅ JWT generation/validation
✅ Seed data : Rôles système (guest, free, premium, admin)

Tests :

Créer guest
Créer user permanent
Login
Refresh token


Phase 2 : Gestion Utilisateurs (Semaine 2-3)
Objectif : CRUD utilisateurs + conversion guest
Livrables :

✅ Endpoints CRUD users
✅ Conversion guest → permanent
✅ Gestion profil (display_name, avatar, locale)
✅ Consentements (analytics, marketing)
✅ Soft delete

Tests :

Modifier profil
Convertir guest
Supprimer compte


Phase 3 : Système de Permissions (Semaine 3-4)
Objectif : RBAC complet + ACL
Livrables :

✅ Table permissions avec seed data
✅ Endpoint /permissions/check
✅ Assignation rôles dynamique
✅ Vérification permissions granulaires
✅ Middleware RBAC

Seed Permissions :
sql-- Quiz
INSERT INTO permissions (service, action, resource, name) VALUES
('quiz', 'play', 'free', 'quiz:play:free'),
('quiz', 'play', 'premium', 'quiz:play:premium'),
('quiz', 'create', 'own', 'quiz:create:own');

-- Subscription
INSERT INTO permissions (service, action, resource, name) VALUES
('subscription', 'view', 'plans', 'subscription:view:plans'),
('subscription', 'purchase', '*', 'subscription:purchase:*');

-- Ads
INSERT INTO permissions (service, action, resource, name) VALUES
('ads', 'skip', 'interstitial', 'ads:skip:interstitial');
Tests :

Vérifier permission free vs premium
Assigner/retirer rôle
Tester ACL complexe


Phase 4 : Quotas & Renouvellement (Semaine 4-5)
Objectif : Gestion quotas + renouvellement par pub
Livrables :

✅ Table user_quotas
✅ Création quotas automatique (guest)
✅ Endpoint /users/{id}/quotas/renew
✅ Vérification + consommation quota
✅ Intégration avec Ads Service

Tests :

Consommer quota
Renouveler après pub
Expiration quotas périodiques


Phase 5 : Intégration Complète (Semaine 5-6)
Objectif : Connecter tous les services
Livrables :

✅ Modifier API Gateway (headers + permissions)
✅ Modifier Quiz Service (vérification permissions)
✅ Client HTTP Auth dans chaque service
✅ Audit logs
✅ Gestion sessions JWT (révocation)

Tests :

Flow complet : Guest → Quiz → Pub → Quota renouvelé
Flow : User premium → Quiz premium
Flow : User free → Quiz premium BLOCKED


🎯 Seed Data Initial
sql-- Rôles système
INSERT INTO roles (name, description, priority, is_system) VALUES
('admin', 'Administrateur système', 100, true),
('premium', 'Utilisateur premium', 50, true),
('free', 'Utilisateur gratuit', 10, true),
('guest', 'Utilisateur invité', 0, true);

-- Permissions Quiz
INSERT INTO permissions (service, action, resource, name, description) VALUES
('quiz', 'play', 'free', 'quiz:play:free', 'Jouer aux quiz gratuits'),
('quiz', 'play', 'premium', 'quiz:play:premium', 'Jouer aux quiz premium'),
('quiz', 'create', 'own', 'quiz:create:own', 'Créer ses propres quiz');

-- Assignations rôles/permissions
-- Guest
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'guest' AND p.name = 'quiz:play:free';

-- Free (hérite guest + extras)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'free' AND p.name IN ('quiz:play:free');

-- Premium (tout)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'premium';