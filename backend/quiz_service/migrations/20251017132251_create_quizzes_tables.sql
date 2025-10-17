-- Add migration script here
-- Create extension for UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Quizzes table
CREATE TABLE quizzes (
                         id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                         titre VARCHAR(255) NOT NULL,
                         description TEXT,

                         niveau_difficulte VARCHAR(20) NOT NULL CHECK (
                             niveau_difficulte IN ('facile', 'moyen', 'difficile')
                             ),
                         version_app VARCHAR(10) NOT NULL CHECK (
                             version_app IN ('v0', 'v1', 'v2', 'v3')
                             ),
                         region_scope VARCHAR(50) NOT NULL,
                         mode VARCHAR(20) NOT NULL CHECK (
                             mode IN ('texte', 'carte_interactive', 'mixte')
                             ),

                         collection_id UUID,

                         nb_questions INTEGER NOT NULL DEFAULT 10,
                         temps_limite_sec INTEGER,
                         score_minimum_success INTEGER NOT NULL DEFAULT 50,

                         is_active BOOLEAN DEFAULT true,
                         is_public BOOLEAN DEFAULT true,

                         metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

                         total_attempts INTEGER DEFAULT 0,
                         average_score DECIMAL(5, 2),

                         created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                         updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                         created_by UUID
);

-- Index
CREATE INDEX idx_quizzes_version ON quizzes(version_app);
CREATE INDEX idx_quizzes_scope ON quizzes(region_scope);
CREATE INDEX idx_quizzes_active ON quizzes(is_active);
CREATE INDEX idx_quizzes_mode ON quizzes(mode);

-- Trigger pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_quizzes_updated_at
    BEFORE UPDATE ON quizzes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();