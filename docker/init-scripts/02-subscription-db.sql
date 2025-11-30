-- ============================================
-- SUBSCRIPTION SERVICE DATABASE INITIALIZATION
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- SUBSCRIPTION PLANS TABLE
-- Available subscription_service tiers
-- ============================================
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Plan details
    name VARCHAR(100) NOT NULL,
    description TEXT,
    tier VARCHAR(50) NOT NULL CHECK (tier IN ('free', 'premium', 'premium_plus')),
    
    -- Pricing
    price_monthly DECIMAL(10,2),
    price_yearly DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Apple IAP
    apple_product_id_monthly VARCHAR(255),
    apple_product_id_yearly VARCHAR(255),
    
    -- Google IAP
    google_product_id_monthly VARCHAR(255),
    google_product_id_yearly VARCHAR(255),
    
    -- Features
    features JSONB DEFAULT '{}'::jsonb,
    credits_per_month INTEGER DEFAULT 0,
    
    -- Status
    active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Seed plans
INSERT INTO subscription_plans (name, description, tier, price_monthly, price_yearly, features, credits_per_month) VALUES
('Free', 'Basic access', 'free', 0.00, 0.00, '{"ads_service": true, "offline_categories": 1}'::jsonb, 10),
('Premium', 'Ad-free with unlimited access', 'premium', 4.99, 49.99, '{"ads_service": false, "offline_categories": 10, "premium_content": true}'::jsonb, 0),
('Premium Plus', 'Everything + extra credits', 'premium_plus', 9.99, 99.99, '{"ads_service": false, "offline_categories": 999, "premium_content": true, "exclusive_content": true}'::jsonb, 100);

-- ============================================
-- SUBSCRIPTIONS TABLE
-- Active user subscriptions
-- ============================================
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    plan_id UUID REFERENCES subscription_plans(id),
    
    -- Platform
    platform VARCHAR(50) NOT NULL CHECK (platform IN ('apple', 'google', 'stripe', 'internal')),
    
    -- External IDs
    external_subscription_id VARCHAR(255),
    original_transaction_id VARCHAR(255),
    
    -- Status
    status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'paused', 'grace_period', 'pending')),
    
    -- Dates
    started_at TIMESTAMP NOT NULL DEFAULT NOW(),
    current_period_start TIMESTAMP NOT NULL,
    current_period_end TIMESTAMP NOT NULL,
    cancelled_at TIMESTAMP,
    expires_at TIMESTAMP,
    
    -- Billing
    billing_cycle VARCHAR(20) CHECK (billing_cycle IN ('monthly', 'yearly')),
    next_billing_date TIMESTAMP,
    auto_renew BOOLEAN DEFAULT TRUE,
    
    -- Trial
    is_trial BOOLEAN DEFAULT FALSE,
    trial_end_date TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_external_id ON subscriptions(external_subscription_id);

-- ============================================
-- SUBSCRIPTION EVENTS TABLE
-- Track all subscription_service lifecycle events
-- ============================================
CREATE TABLE subscription_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE,
    
    -- Event details
    event_type VARCHAR(100) NOT NULL,
    platform VARCHAR(50),
    
    -- Event data
    event_data JSONB DEFAULT '{}'::jsonb,
    
    -- Receipt/transaction
    receipt_data TEXT,
    
    -- Timestamp
    occurred_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_subscription_events_subscription_id ON subscription_events(subscription_id, occurred_at DESC);
CREATE INDEX idx_subscription_events_type ON subscription_events(event_type);

-- ============================================
-- USER CREDITS TABLE
-- Credit balance per user
-- ============================================
CREATE TABLE user_credits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL,
    
    -- Balance
    balance INTEGER DEFAULT 0 CHECK (balance >= 0),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_user_credits_user_id ON user_credits(user_id);

-- ============================================
-- CREDIT TRANSACTIONS TABLE
-- All credit movements
-- ============================================
CREATE TABLE credit_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    
    -- Transaction details
    type VARCHAR(50) NOT NULL CHECK (type IN ('earned', 'spent', 'refunded', 'expired', 'granted', 'purchased')),
    amount INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    
    -- Context
    reason VARCHAR(255),
    related_entity_type VARCHAR(50),
    related_entity_id UUID,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamp
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_credit_transactions_user_id ON credit_transactions(user_id, created_at DESC);
CREATE INDEX idx_credit_transactions_type ON credit_transactions(type);

-- ============================================
-- CONTENTS TABLE
-- Premium/Freemium content catalog
-- ============================================
CREATE TABLE contents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Content details
    content_type VARCHAR(50) NOT NULL,
    external_id VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    
    -- Access control
    access_level VARCHAR(50) NOT NULL DEFAULT 'free' CHECK (access_level IN ('free', 'premium', 'freemium')),
    credit_cost INTEGER DEFAULT 0 CHECK (credit_cost >= 0),
    
    -- Requirements
    required_plan_tier VARCHAR(50),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Status
    active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(content_type, external_id)
);

CREATE INDEX idx_contents_access_level ON contents(access_level);
CREATE INDEX idx_contents_type ON contents(content_type);

-- ============================================
-- UNLOCKED CONTENTS TABLE
-- Track what users have unlocked with credits
-- ============================================
CREATE TABLE unlocked_contents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    content_id UUID REFERENCES contents(id) ON DELETE CASCADE,
    
    -- Unlock details
    credits_spent INTEGER NOT NULL,
    
    -- Access
    expires_at TIMESTAMP,
    
    -- Timestamp
    unlocked_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(user_id, content_id)
);

CREATE INDEX idx_unlocked_contents_user_id ON unlocked_contents(user_id);
CREATE INDEX idx_unlocked_contents_content_id ON unlocked_contents(content_id);

-- ============================================
-- ACCESS LOGS TABLE
-- Track all content access attempts
-- ============================================
CREATE TABLE access_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    content_id UUID REFERENCES contents(id) ON DELETE SET NULL,
    
    -- Access result
    access_granted BOOLEAN NOT NULL,
    reason VARCHAR(255),
    
    -- Context
    user_plan_tier VARCHAR(50),
    user_credit_balance INTEGER,
    
    -- Timestamp
    accessed_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_access_logs_user_id ON access_logs(user_id, accessed_at DESC);
CREATE INDEX idx_access_logs_content_id ON access_logs(content_id, accessed_at DESC);

-- ============================================
-- IAP RECEIPTS TABLE
-- Store IAP receipts for verification
-- ============================================
CREATE TABLE iap_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    subscription_id UUID REFERENCES subscriptions(id),
    
    -- Platform
    platform VARCHAR(50) NOT NULL CHECK (platform IN ('apple', 'google')),
    
    -- Receipt data
    receipt_data TEXT NOT NULL,
    transaction_id VARCHAR(255) NOT NULL,
    original_transaction_id VARCHAR(255),
    
    -- Verification
    verified BOOLEAN DEFAULT FALSE,
    verification_response JSONB,
    verified_at TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(platform, transaction_id)
);

CREATE INDEX idx_iap_receipts_user_id ON iap_receipts(user_id);
CREATE INDEX idx_iap_receipts_transaction_id ON iap_receipts(transaction_id);

-- ============================================
-- WEBHOOK EVENTS TABLE
-- Store webhook events from Apple/Google
-- ============================================
CREATE TABLE webhook_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Source
    platform VARCHAR(50) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    
    -- Payload
    payload JSONB NOT NULL,
    
    -- Processing
    processed BOOLEAN DEFAULT FALSE,
    processed_at TIMESTAMP,
    error_message TEXT,
    
    -- Timestamp
    received_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_webhook_events_platform ON webhook_events(platform, received_at DESC);
CREATE INDEX idx_webhook_events_processed ON webhook_events(processed) WHERE processed = FALSE;

-- ============================================
-- TRIGGERS
-- ============================================
CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON subscription_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_credits_updated_at BEFORE UPDATE ON user_credits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contents_updated_at BEFORE UPDATE ON contents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- HELPER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$
BEGIN
    RAISE NOTICE 'Subscription database initialized successfully!';
    RAISE NOTICE 'Tables created: 10';
    RAISE NOTICE '3 subscription_service plans seeded';
END $$;
