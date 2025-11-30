-- ============================================
-- AUTH SERVICE DATABASE INITIALIZATION
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- APPLICATIONS TABLE
-- Stores registered applications that can use the auth_service service
-- ============================================
CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    bundle_id VARCHAR(255) UNIQUE NOT NULL,
    api_key VARCHAR(255) UNIQUE NOT NULL,
    
    -- OAuth configurations
    oauth_providers JSONB DEFAULT '{}'::jsonb,
    
    -- IAP configurations
    iap_config JSONB DEFAULT '{}'::jsonb,
    
    -- Services enabled
    services_enabled JSONB DEFAULT '{"auth_service": true}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Seed default application for development
INSERT INTO applications (name, bundle_id, api_key, services_enabled) 
VALUES (
    'Quiz Geography Dev',
    'com.petits.quizz.de.geo.dev',
    'dev_api_key_change_in_production',
    '{"auth_service": true, "subscription_service": true, "offline": true, "ads_service": true}'::jsonb
);

-- ============================================
-- USERS TABLE
-- Main user accounts
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    app_id UUID REFERENCES applications(id) ON DELETE CASCADE,
    
    -- Authentication identifiers
    email VARCHAR(255),
    email_verified BOOLEAN DEFAULT FALSE,
    apple_id VARCHAR(255) UNIQUE,
    google_id VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255),
    
    -- Auth method
    auth_provider VARCHAR(50) NOT NULL CHECK (auth_provider IN ('apple', 'google', 'email', 'guest')),
    
    -- User status
    status VARCHAR(50) DEFAULT 'free' CHECK (status IN ('free', 'premium', 'guest', 'suspended')),
    
    -- Guest specific
    is_guest BOOLEAN DEFAULT FALSE,
    guest_expires_at TIMESTAMP,
    
    -- Security
    login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    last_password_change TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP,
    
    -- Constraints
    UNIQUE(app_id, email),
    CHECK (
        (auth_provider = 'email' AND email IS NOT NULL AND password_hash IS NOT NULL) OR
        (auth_provider = 'google' AND google_id IS NOT NULL) OR
        (auth_provider = 'apple' AND apple_id IS NOT NULL) OR
        (auth_provider = 'guest' AND is_guest = TRUE)
    )
);

-- Indexes for performance
CREATE INDEX idx_users_app_id ON users(app_id);
CREATE INDEX idx_users_email ON users(email) WHERE email IS NOT NULL;
CREATE INDEX idx_users_google_id ON users(google_id) WHERE google_id IS NOT NULL;
CREATE INDEX idx_users_apple_id ON users(apple_id) WHERE apple_id IS NOT NULL;
CREATE INDEX idx_users_status ON users(status);

-- ============================================
-- OAUTH CONNECTIONS TABLE
-- Stores OAuth provider connections
-- ============================================
CREATE TABLE oauth_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Provider info
    provider VARCHAR(50) NOT NULL CHECK (provider IN ('apple', 'google')),
    provider_user_id VARCHAR(255) NOT NULL,
    
    -- Tokens (encrypted in production)
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TIMESTAMP,
    
    -- Profile data
    profile_data JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    connected_at TIMESTAMP DEFAULT NOW(),
    last_used TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(user_id, provider)
);

CREATE INDEX idx_oauth_user_id ON oauth_connections(user_id);
CREATE INDEX idx_oauth_provider ON oauth_connections(provider, provider_user_id);

-- ============================================
-- REFRESH TOKENS TABLE
-- Stores valid refresh tokens
-- ============================================
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Token (hashed)
    token_hash VARCHAR(255) NOT NULL,
    
    -- Device info
    device_info JSONB DEFAULT '{}'::jsonb,
    
    -- Status
    revoked BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(token_hash)
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash) WHERE revoked = FALSE;

-- ============================================
-- PRIVACY SETTINGS TABLE
-- User privacy preferences
-- ============================================
CREATE TABLE privacy_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    
    -- Consents
    consent_analytics BOOLEAN DEFAULT FALSE,
    consent_third_party BOOLEAN DEFAULT FALSE,
    consent_geolocation BOOLEAN DEFAULT FALSE,
    consent_personalized_ads BOOLEAN DEFAULT FALSE,
    consent_notifications BOOLEAN DEFAULT FALSE,
    consent_game_center BOOLEAN DEFAULT FALSE,
    
    -- Data deletion
    delete_requested BOOLEAN DEFAULT FALSE,
    delete_scheduled_at TIMESTAMP,
    delete_reason TEXT,
    
    -- Data exports
    data_export_requests INTEGER DEFAULT 0,
    last_export_at TIMESTAMP,
    
    -- Timestamps
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_privacy_user_id ON privacy_settings(user_id);

-- ============================================
-- AUDIT LOGS TABLE
-- Track all authentication events
-- ============================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    app_id UUID REFERENCES applications(id) ON DELETE CASCADE,
    
    -- Event details
    action VARCHAR(100) NOT NULL,
    result VARCHAR(50) NOT NULL CHECK (result IN ('success', 'failure')),
    
    -- Request context
    ip_address INET,
    user_agent TEXT,
    
    -- Additional details
    details JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamp
    timestamp TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id, timestamp DESC);
CREATE INDEX idx_audit_logs_app_id ON audit_logs(app_id, timestamp DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action, timestamp DESC);

-- ============================================
-- GAME CENTER CONNECTIONS TABLE
-- Apple Game Center integration
-- ============================================
CREATE TABLE game_center_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    
    -- Game Center info
    player_id VARCHAR(255) UNIQUE NOT NULL,
    alias VARCHAR(255),
    
    -- Sync data
    sync_data JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    linked_at TIMESTAMP DEFAULT NOW(),
    last_sync TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_game_center_player_id ON game_center_connections(player_id);

-- ============================================
-- EMAIL VERIFICATION TOKENS TABLE
-- For email verification flow
-- ============================================
CREATE TABLE email_verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Token
    token VARCHAR(255) UNIQUE NOT NULL,
    
    -- Status
    used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP NOT NULL,
    
    -- Timestamp
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_email_tokens_token ON email_verification_tokens(token) WHERE used = FALSE;

-- ============================================
-- PASSWORD RESET TOKENS TABLE
-- For password reset flow
-- ============================================
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Token
    token VARCHAR(255) UNIQUE NOT NULL,
    
    -- Status
    used BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP NOT NULL,
    
    -- Timestamp
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_password_tokens_token ON password_reset_tokens(token) WHERE used = FALSE;

-- ============================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to tables with updated_at
CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_privacy_settings_updated_at BEFORE UPDATE ON privacy_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE 'Auth database initialized successfully!';
    RAISE NOTICE 'Tables created: 10';
    RAISE NOTICE 'Default application created for development';
END $$;
