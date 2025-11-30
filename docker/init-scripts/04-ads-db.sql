-- ============================================
-- ADS SERVICE DATABASE INITIALIZATION
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USER AD SETTINGS TABLE
-- User ad preferences and consent
-- ============================================
CREATE TABLE user_ad_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL,
    
    -- Consent (GDPR/ATT)
    gdpr_consent BOOLEAN DEFAULT FALSE,
    gdpr_consent_date TIMESTAMP,
    att_status VARCHAR(50) CHECK (att_status IN ('not_determined', 'restricted', 'denied', 'authorized')),
    att_requested_date TIMESTAMP,
    
    -- Personalization
    personalized_ads_enabled BOOLEAN DEFAULT FALSE,
    
    -- Frequency capping
    max_interstitials_per_day INTEGER DEFAULT 10,
    max_rewarded_per_day INTEGER DEFAULT 20,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_user_ad_settings_user_id ON user_ad_settings(user_id);

-- ============================================
-- AD PLACEMENTS TABLE
-- Define where ads_service can be shown
-- ============================================
CREATE TABLE ad_placements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Placement details
    placement_id VARCHAR(100) UNIQUE NOT NULL,
    placement_name VARCHAR(255) NOT NULL,
    placement_type VARCHAR(50) NOT NULL CHECK (placement_type IN ('interstitial', 'rewarded', 'banner', 'native')),
    
    -- Location in app
    screen VARCHAR(100),
    trigger_event VARCHAR(100),
    
    -- AdMob IDs
    admob_unit_id_android VARCHAR(255),
    admob_unit_id_ios VARCHAR(255),
    
    -- Frequency
    min_interval_seconds INTEGER DEFAULT 180,  -- 3 minutes between same placement
    
    -- Status
    active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ad_placements_type ON ad_placements(placement_type);

-- Seed common placements
INSERT INTO ad_placements (placement_id, placement_name, placement_type, screen, trigger_event, min_interval_seconds) VALUES
('post_quiz_interstitial', 'After Quiz Completion', 'interstitial', 'quiz_results', 'quiz_completed', 300),
('unlock_content_rewarded', 'Unlock Premium Content', 'rewarded', 'content_lock', 'unlock_attempt', 0),
('extra_credits_rewarded', 'Earn Extra Credits', 'rewarded', 'store', 'watch_ad_button', 0),
('app_open_interstitial', 'App Open', 'interstitial', 'home', 'app_launched', 600),
('level_up_rewarded', 'Level Up Bonus', 'rewarded', 'level_up', 'level_achieved', 0);

-- ============================================
-- AD IMPRESSIONS TABLE
-- Track every ad shown
-- ============================================
CREATE TABLE ad_impressions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    placement_id UUID REFERENCES ad_placements(id),
    
    -- Ad details
    ad_network VARCHAR(50) DEFAULT 'admob',
    ad_unit_id VARCHAR(255),
    ad_format VARCHAR(50),
    
    -- Session
    session_id UUID,
    
    -- Status
    impression_status VARCHAR(50) NOT NULL CHECK (impression_status IN ('requested', 'loaded', 'shown', 'failed', 'clicked', 'closed', 'rewarded')),
    
    -- Timing
    request_time TIMESTAMP,
    load_time TIMESTAMP,
    show_time TIMESTAMP,
    close_time TIMESTAMP,
    
    -- Reward (for rewarded ads_service)
    reward_granted BOOLEAN DEFAULT FALSE,
    reward_type VARCHAR(50),
    reward_amount INTEGER,
    
    -- Error
    error_code VARCHAR(50),
    error_message TEXT,
    
    -- Revenue (eCPM estimation)
    estimated_revenue_usd DECIMAL(10,6),
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamp
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ad_impressions_user_id ON ad_impressions(user_id, created_at DESC);
CREATE INDEX idx_ad_impressions_placement_id ON ad_impressions(placement_id);
CREATE INDEX idx_ad_impressions_status ON ad_impressions(impression_status);
CREATE INDEX idx_ad_impressions_rewarded ON ad_impressions(reward_granted) WHERE reward_granted = TRUE;

-- ============================================
-- AD FREQUENCY CAPS TABLE
-- Track user ad exposure for frequency capping
-- ============================================
CREATE TABLE ad_frequency_caps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    placement_id UUID REFERENCES ad_placements(id),
    
    -- Counters
    impressions_today INTEGER DEFAULT 0,
    last_impression TIMESTAMP,
    
    -- Date tracking
    current_date DATE DEFAULT CURRENT_DATE,
    
    UNIQUE(user_id, placement_id, current_date)
);

CREATE INDEX idx_ad_frequency_caps_user_id ON ad_frequency_caps(user_id);
CREATE INDEX idx_ad_frequency_caps_date ON ad_frequency_caps(current_date);

-- ============================================
-- FREEMIUM CAMPAIGNS TABLE
-- Campaigns to convert free users to premium
-- ============================================
CREATE TABLE freemium_campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Campaign details
    campaign_id VARCHAR(100) UNIQUE NOT NULL,
    campaign_name VARCHAR(255) NOT NULL,
    campaign_type VARCHAR(50) CHECK (campaign_type IN ('discount', 'trial', 'feature_unlock', 'credit_bonus')),
    
    -- Trigger conditions
    trigger_conditions JSONB NOT NULL,
    
    -- Offer details
    offer_description TEXT,
    discount_percentage INTEGER,
    free_trial_days INTEGER,
    bonus_credits INTEGER,
    
    -- Timing
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    
    -- Targeting
    target_segments JSONB DEFAULT '[]'::jsonb,
    
    -- Status
    active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_freemium_campaigns_active ON freemium_campaigns(active) WHERE active = TRUE;

-- ============================================
-- CAMPAIGN EXPOSURES TABLE
-- Track which users saw which campaigns
-- ============================================
CREATE TABLE campaign_exposures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    campaign_id UUID REFERENCES freemium_campaigns(id),
    
    -- Exposure details
    shown_count INTEGER DEFAULT 1,
    
    -- Interaction
    clicked BOOLEAN DEFAULT FALSE,
    clicked_at TIMESTAMP,
    converted BOOLEAN DEFAULT FALSE,
    converted_at TIMESTAMP,
    
    -- Dismissal
    dismissed BOOLEAN DEFAULT FALSE,
    dismissed_at TIMESTAMP,
    dont_show_again BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    first_shown TIMESTAMP DEFAULT NOW(),
    last_shown TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_campaign_exposures_user_id ON campaign_exposures(user_id);
CREATE INDEX idx_campaign_exposures_campaign_id ON campaign_exposures(campaign_id);

-- ============================================
-- AD REVENUE TABLE
-- Aggregate revenue tracking
-- ============================================
CREATE TABLE ad_revenue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Date
    revenue_date DATE NOT NULL,
    
    -- Breakdown
    ad_network VARCHAR(50) NOT NULL,
    ad_format VARCHAR(50) NOT NULL,
    country VARCHAR(3),
    
    -- Metrics
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    rewarded_views INTEGER DEFAULT 0,
    
    -- Revenue
    estimated_revenue_usd DECIMAL(10,2) DEFAULT 0.0,
    
    -- Calculated
    ecpm DECIMAL(10,2),
    ctr DECIMAL(5,4),
    
    -- Timestamp
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(revenue_date, ad_network, ad_format, country)
);

CREATE INDEX idx_ad_revenue_date ON ad_revenue(revenue_date DESC);
CREATE INDEX idx_ad_revenue_network ON ad_revenue(ad_network);

-- ============================================
-- TRIGGERS
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_ad_settings_updated_at BEFORE UPDATE ON user_ad_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ad_placements_updated_at BEFORE UPDATE ON ad_placements
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_freemium_campaigns_updated_at BEFORE UPDATE ON freemium_campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Check if user can see interstitial ad
CREATE OR REPLACE FUNCTION can_show_interstitial(
    p_user_id UUID,
    p_placement_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_impressions_today INTEGER;
    v_max_per_day INTEGER;
    v_last_impression TIMESTAMP;
    v_min_interval INTEGER;
BEGIN
    -- Get user settings
    SELECT max_interstitials_per_day INTO v_max_per_day
    FROM user_ad_settings
    WHERE user_id = p_user_id;
    
    IF v_max_per_day IS NULL THEN
        v_max_per_day := 10;  -- Default
    END IF;
    
    -- Get today's impression count
    SELECT COALESCE(impressions_today, 0), last_impression
    INTO v_impressions_today, v_last_impression
    FROM ad_frequency_caps
    WHERE user_id = p_user_id 
      AND placement_id = p_placement_id
      AND current_date = CURRENT_DATE;
    
    -- Check daily cap
    IF v_impressions_today >= v_max_per_day THEN
        RETURN FALSE;
    END IF;
    
    -- Get minimum interval
    SELECT min_interval_seconds INTO v_min_interval
    FROM ad_placements
    WHERE id = p_placement_id;
    
    -- Check time since last impression
    IF v_last_impression IS NOT NULL AND 
       EXTRACT(EPOCH FROM (NOW() - v_last_impression)) < v_min_interval THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Record ad impression and update frequency cap
CREATE OR REPLACE FUNCTION record_ad_impression(
    p_user_id UUID,
    p_placement_id UUID
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO ad_frequency_caps (user_id, placement_id, impressions_today, last_impression, current_date)
    VALUES (p_user_id, p_placement_id, 1, NOW(), CURRENT_DATE)
    ON CONFLICT (user_id, placement_id, current_date)
    DO UPDATE SET
        impressions_today = ad_frequency_caps.impressions_today + 1,
        last_impression = NOW();
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    RAISE NOTICE 'Ads database initialized successfully!';
    RAISE NOTICE 'Tables created: 7';
    RAISE NOTICE '5 ad placements seeded';
END $$;
