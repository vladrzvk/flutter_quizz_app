-- ============================================
-- AUTH SERVICE - Database Schema
-- Sécurité maximale avec toutes les mesures
-- ============================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- USERS : Utilisateurs du système
-- ============================================
CREATE TABLE users (
                       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Authentification
                       email VARCHAR(255) UNIQUE,              -- Null pour guests
                       password_hash VARCHAR(255),             -- Null pour guests (bcrypt/argon2)

    -- Statut & Type
                       status VARCHAR(20) NOT NULL DEFAULT 'free'
                           CHECK (status IN ('free', 'premium', 'trial', 'suspended')),
                       is_guest BOOLEAN DEFAULT false,

    -- Profil
                       display_name VARCHAR(100),
                       avatar_url TEXT,

    -- Consentements & Préférences
                       analytics_consent BOOLEAN DEFAULT false,
                       marketing_consent BOOLEAN DEFAULT false,
                       locale VARCHAR(10) DEFAULT 'fr',

    -- Metadata (flexible JSON storage)
                       metadata JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
                       created_at TIMESTAMPTZ DEFAULT NOW(),
                       updated_at TIMESTAMPTZ DEFAULT NOW(),
                       last_login_at TIMESTAMPTZ,

    -- Soft delete
                       deleted_at TIMESTAMPTZ,

    -- Security constraints
                       CONSTRAINT email_format_check CHECK (
                           email IS NULL OR email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
),
    CONSTRAINT guest_no_email CHECK (
        (is_guest = true AND email IS NULL) OR
        (is_guest = false AND email IS NOT NULL)
    )
);

-- Index
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL AND deleted_at IS NULL;
CREATE INDEX idx_users_status ON users(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_is_guest ON users(is_guest) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_deleted ON users(deleted_at) WHERE deleted_at IS NOT NULL;

-- ============================================
-- ROLES : Rôles utilisateurs
-- ============================================
CREATE TABLE roles (
                       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                       name VARCHAR(50) UNIQUE NOT NULL,
                       description TEXT,
                       priority INT DEFAULT 0,                 -- Ordre hiérarchique (0 = lowest)

    -- Système
                       is_system BOOLEAN DEFAULT false,        -- Rôles système non supprimables
                       metadata JSONB DEFAULT '{}'::jsonb,

                       created_at TIMESTAMPTZ DEFAULT NOW(),
                       updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_roles_priority ON roles(priority DESC);

-- ============================================
-- PERMISSIONS : Permissions granulaires
-- ============================================
CREATE TABLE permissions (
                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Format: "service:action:resource"
                             service VARCHAR(50) NOT NULL,
                             action VARCHAR(50) NOT NULL,
                             resource VARCHAR(100) NOT NULL,

    -- Description
                             name VARCHAR(100) UNIQUE NOT NULL,
                             description TEXT,

    -- Metadata
                             metadata JSONB DEFAULT '{}'::jsonb,

                             created_at TIMESTAMPTZ DEFAULT NOW(),

                             UNIQUE(service, action, resource)
);

-- Index
CREATE INDEX idx_permissions_service ON permissions(service);
CREATE INDEX idx_permissions_name ON permissions(name);

-- ============================================
-- USER_ROLES : Association Users <-> Roles
-- ============================================
CREATE TABLE user_roles (
                            user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                            role_id UUID REFERENCES roles(id) ON DELETE CASCADE,

    -- Metadata
                            granted_at TIMESTAMPTZ DEFAULT NOW(),
                            granted_by UUID REFERENCES users(id),
                            expires_at TIMESTAMPTZ,
                            metadata JSONB DEFAULT '{}'::jsonb,

                            PRIMARY KEY (user_id, role_id)
);

-- Index
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_expires ON user_roles(expires_at) WHERE expires_at IS NOT NULL;

-- ============================================
-- ROLE_PERMISSIONS : Association Roles <-> Permissions
-- ============================================
CREATE TABLE role_permissions (
                                  role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
                                  permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,

                                  granted_at TIMESTAMPTZ DEFAULT NOW(),

                                  PRIMARY KEY (role_id, permission_id)
);

-- Index
CREATE INDEX idx_role_permissions_role ON role_permissions(role_id);

-- ============================================
-- USER_QUOTAS : Gestion des quotas utilisateurs
-- ============================================
CREATE TABLE user_quotas (
                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                             user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    -- Type de quota (générique pour réutilisabilité)
                             quota_type VARCHAR(50) NOT NULL,        -- 'quiz_plays', 'file_conversions', etc.

    -- Limites
                             max_allowed INT NOT NULL,
                             current_usage INT DEFAULT 0 CHECK (current_usage >= 0),

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

                             UNIQUE(user_id, quota_type),

    -- Contraintes métier
                             CONSTRAINT quota_usage_valid CHECK (current_usage <= max_allowed),
                             CONSTRAINT period_dates_valid CHECK (
                                 (period_start IS NULL AND period_end IS NULL) OR
                                 (period_start IS NOT NULL AND period_end IS NOT NULL AND period_end > period_start)
                                 )
);

-- Index
CREATE INDEX idx_user_quotas_user ON user_quotas(user_id);
CREATE INDEX idx_user_quotas_type ON user_quotas(quota_type);
CREATE INDEX idx_user_quotas_period_end ON user_quotas(period_end) WHERE period_end IS NOT NULL;

-- ============================================
-- QUOTA_CONSUMPTIONS : Idempotency pour quotas
-- ============================================
CREATE TABLE quota_consumptions (
                                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                    idempotency_key UUID UNIQUE NOT NULL,
                                    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                                    quota_type VARCHAR(50) NOT NULL,

                                    consumed_at TIMESTAMPTZ DEFAULT NOW(),

    -- Nettoyage après 7 jours
                                    CONSTRAINT consumption_recent CHECK (consumed_at > NOW() - INTERVAL '7 days')
    );

-- Index
CREATE INDEX idx_quota_consumptions_key ON quota_consumptions(idempotency_key);
CREATE INDEX idx_quota_consumptions_user ON quota_consumptions(user_id);

-- ============================================
-- JWT_SESSIONS : Gestion des sessions JWT
-- ============================================
CREATE TABLE jwt_sessions (
                              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                              user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    -- Token hashes (pour révocation)
                              access_token_hash VARCHAR(255) NOT NULL,
                              refresh_token_hash VARCHAR(255) NOT NULL,

    -- Validité
                              issued_at TIMESTAMPTZ DEFAULT NOW(),
                              expires_at TIMESTAMPTZ NOT NULL,
                              last_used_at TIMESTAMPTZ DEFAULT NOW(),

    -- Device tracking
                              ip_address INET,
                              user_agent TEXT,
                              device_fingerprint VARCHAR(255),

    -- Révocation
                              revoked_at TIMESTAMPTZ,
                              revoke_reason VARCHAR(100),

                              metadata JSONB DEFAULT '{}'::jsonb,

                              CONSTRAINT session_dates_valid CHECK (expires_at > issued_at)
);

-- Index
CREATE INDEX idx_jwt_sessions_user ON jwt_sessions(user_id);
CREATE INDEX idx_jwt_sessions_access_token ON jwt_sessions(access_token_hash) WHERE revoked_at IS NULL;
CREATE INDEX idx_jwt_sessions_refresh_token ON jwt_sessions(refresh_token_hash) WHERE revoked_at IS NULL;
CREATE INDEX idx_jwt_sessions_expires ON jwt_sessions(expires_at) WHERE revoked_at IS NULL;
CREATE INDEX idx_jwt_sessions_device ON jwt_sessions(device_fingerprint) WHERE device_fingerprint IS NOT NULL;

-- ============================================
-- LOGIN_ATTEMPTS : Tracking des tentatives de login (Rate Limiting)
-- ============================================
CREATE TABLE login_attempts (
                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identification
                                email VARCHAR(255),                     -- Peut être null si user n'existe pas
                                ip_address INET NOT NULL,

    -- Résultat
                                success BOOLEAN NOT NULL,
                                failure_reason VARCHAR(100),

    -- Device
                                user_agent TEXT,
                                device_fingerprint VARCHAR(255),

                                attempted_at TIMESTAMPTZ DEFAULT NOW(),

    -- Nettoyage après 24h
                                CONSTRAINT attempt_recent CHECK (attempted_at > NOW() - INTERVAL '24 hours')
    );

-- Index
CREATE INDEX idx_login_attempts_ip ON login_attempts(ip_address, attempted_at DESC);
CREATE INDEX idx_login_attempts_email ON login_attempts(email, attempted_at DESC) WHERE email IS NOT NULL;
CREATE INDEX idx_login_attempts_device ON login_attempts(device_fingerprint, attempted_at DESC) WHERE device_fingerprint IS NOT NULL;

-- ============================================
-- DEVICE_FINGERPRINTS : Gestion des devices (Guest limitation)
-- ============================================
CREATE TABLE device_fingerprints (
                                     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                     user_id UUID REFERENCES users(id) ON DELETE CASCADE,

                                     fingerprint VARCHAR(255) NOT NULL,

    -- Metadata
                                     first_seen_at TIMESTAMPTZ DEFAULT NOW(),
                                     last_seen_at TIMESTAMPTZ DEFAULT NOW(),

                                     metadata JSONB DEFAULT '{}'::jsonb,

                                     UNIQUE(user_id, fingerprint)
);

-- Index
CREATE INDEX idx_device_fingerprints_fingerprint ON device_fingerprints(fingerprint);
CREATE INDEX idx_device_fingerprints_user ON device_fingerprints(user_id);

-- ============================================
-- AUDIT_LOGS : Traçabilité des actions critiques
-- ============================================
CREATE TABLE audit_logs (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Acteur
                            user_id UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Action
                            action VARCHAR(50) NOT NULL,            -- 'login', 'register', 'permission_granted', etc.
                            resource_type VARCHAR(50),              -- 'user', 'role', 'permission', 'quota'
                            resource_id UUID,

    -- Contexte
                            ip_address INET,
                            user_agent TEXT,

    -- Détails
                            old_value JSONB,
                            new_value JSONB,
                            metadata JSONB DEFAULT '{}'::jsonb,

                            created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id) WHERE resource_id IS NOT NULL;

-- ============================================
-- TRIGGERS : Automatic updates
-- ============================================

-- Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers sur les tables avec updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_roles_updated_at
    BEFORE UPDATE ON roles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_quotas_updated_at
    BEFORE UPDATE ON user_quotas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEWS : Vues utiles pour queries complexes
-- ============================================

-- Vue : Permissions effectives d'un utilisateur
CREATE VIEW user_effective_permissions AS
SELECT DISTINCT
    u.id AS user_id,
    u.email,
    u.status,
    u.is_guest,
    p.id AS permission_id,
    p.name AS permission_name,
    p.service,
    p.action,
    p.resource
FROM users u
         JOIN user_roles ur ON u.id = ur.user_id
         JOIN role_permissions rp ON ur.role_id = rp.role_id
         JOIN permissions p ON rp.permission_id = p.id
WHERE u.deleted_at IS NULL
  AND (ur.expires_at IS NULL OR ur.expires_at > NOW());

-- Vue : Sessions actives
CREATE VIEW active_sessions AS
SELECT
    js.*,
    u.email,
    u.status,
    u.is_guest
FROM jwt_sessions js
         JOIN users u ON js.user_id = u.id
WHERE js.revoked_at IS NULL
  AND js.expires_at > NOW()
  AND u.deleted_at IS NULL;

-- ============================================
-- COMMENTAIRES
-- ============================================
COMMENT ON TABLE users IS 'Utilisateurs du système (permanents et guests)';
COMMENT ON TABLE roles IS 'Rôles avec hiérarchie (guest < free < premium < admin)';
COMMENT ON TABLE permissions IS 'Permissions granulaires au format service:action:resource';
COMMENT ON TABLE user_quotas IS 'Quotas utilisateurs avec renouvellement possible (pub, etc.)';
COMMENT ON TABLE jwt_sessions IS 'Sessions JWT avec révocation et device tracking';
COMMENT ON TABLE login_attempts IS 'Tentatives de login pour rate limiting et détection brute force';
COMMENT ON TABLE device_fingerprints IS 'Empreintes devices pour limitation guests';
COMMENT ON TABLE audit_logs IS 'Logs d\'audit pour traçabilité actions critiques';

COMMENT ON COLUMN users.email IS 'Email unique (NULL pour guests)';
COMMENT ON COLUMN users.password_hash IS 'Hash bcrypt/argon2 du mot de passe (NULL pour guests)';
COMMENT ON COLUMN users.status IS 'Statut utilisateur: free, premium, trial, suspended';
COMMENT ON COLUMN users.is_guest IS 'true = compte temporaire sans email/password';

COMMENT ON COLUMN permissions.name IS 'Format: service:action:resource (ex: quiz:play:premium)';

COMMENT ON COLUMN user_quotas.quota_type IS 'Type générique: quiz_plays, file_conversions, etc.';
COMMENT ON COLUMN user_quotas.can_renew IS 'Peut renouveler via action (ex: regarder pub)';
COMMENT ON COLUMN user_quotas.renew_action IS 'Action requise pour renouvellement: watch_ad, share, etc.';