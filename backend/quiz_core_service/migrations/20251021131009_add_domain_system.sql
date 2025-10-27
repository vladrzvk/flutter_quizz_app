-- ============================================
-- Migration 006: Système de Domaines & Plugin
-- ============================================

-- 1. Table des domaines configurables
CREATE TABLE IF NOT EXISTS domains (
                                       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    config JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
    );

-- Insérer le domaine Geography
INSERT INTO domains (name, display_name, description, config) VALUES
    ('geography', 'Géographie', 'Quiz sur la géographie mondiale et régionale', '{"icon": "🌍", "color": "#2196F3"}'::jsonb)
    ON CONFLICT (name) DO NOTHING;

-- 2. Ajouter colonne domain aux quizzes
ALTER TABLE quizzes
    ADD COLUMN IF NOT EXISTS domain VARCHAR(50) DEFAULT 'geography' NOT NULL;

-- 3. Renommer region_scope en scope (générique)
ALTER TABLE quizzes
    RENAME COLUMN region_scope TO scope;

-- 4. Ajouter contrainte foreign key
ALTER TABLE quizzes
    ADD CONSTRAINT fk_quizzes_domain
        FOREIGN KEY (domain) REFERENCES domains(name)
            ON DELETE RESTRICT;

-- 5. Index pour performance
CREATE INDEX IF NOT EXISTS idx_quizzes_domain ON quizzes(domain);
CREATE INDEX IF NOT EXISTS idx_quizzes_domain_active ON quizzes(domain, is_active);

-- 6. Ajouter media_url aux questions (générique : image, map, video)
ALTER TABLE questions
    ADD COLUMN IF NOT EXISTS media_url TEXT;

-- 7. Renommer region_cible_id en target_id (générique)
ALTER TABLE questions
    RENAME COLUMN region_cible_id TO target_id;

-- 8. Mettre à jour les quiz existants pour avoir le domaine geography
UPDATE quizzes
SET domain = 'geography'
WHERE domain IS NULL OR domain = '';

-- 9. Commentaires pour documentation
COMMENT ON TABLE domains IS 'Domaines de quiz disponibles (geography, code_route, culture, etc.)';
COMMENT ON COLUMN quizzes.domain IS 'Domaine du quiz (geography, code_route, etc.)';
COMMENT ON COLUMN quizzes.scope IS 'Portée du quiz (europe, france, monde, etc.)';
COMMENT ON COLUMN questions.media_url IS 'URL vers média (map://, https://, file://)';
COMMENT ON COLUMN questions.target_id IS 'ID cible générique (region, panneau, etc.)';

-- 10. Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
RETURN NEW;
END;
$$ language 'plpgsql';

-- Appliquer le trigger sur domains
CREATE TRIGGER update_domains_updated_at
    BEFORE UPDATE ON domains
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();