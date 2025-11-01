-- ============================================
-- MIGRATION INITIALE - Schéma complet V0
-- ============================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLE: domains
-- ============================================
CREATE TABLE domains (
                         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                         name VARCHAR(50) UNIQUE NOT NULL,
                         display_name VARCHAR(100) NOT NULL,
                         description TEXT,
                         is_active BOOLEAN DEFAULT true,
                         config JSONB DEFAULT '{}'::jsonb,
                         created_at TIMESTAMPTZ DEFAULT NOW(),
                         updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed domain Geography
INSERT INTO domains (name, display_name, description, config) VALUES
    ('geography', 'Géographie', 'Quiz sur la géographie mondiale et régionale', '{"icon": "🌍", "color": "#2196F3"}'::jsonb);

-- ============================================
-- TABLE: quizzes
-- ============================================
CREATE TABLE quizzes (
                         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identification du domaine
                         domain VARCHAR(50) NOT NULL REFERENCES domains(name) ON DELETE RESTRICT,

    -- Informations de base
                         titre VARCHAR(255) NOT NULL,
                         description TEXT,

    -- Configuration
                         niveau_difficulte VARCHAR(20) NOT NULL CHECK (
                             niveau_difficulte IN ('facile', 'moyen', 'difficile')
                             ),
                         version_app VARCHAR(10) NOT NULL DEFAULT '1.0.0',
                         scope VARCHAR(50) NOT NULL, -- 'france', 'europe', 'monde', etc.
                         mode VARCHAR(30) NOT NULL CHECK (
                             mode IN ('decouverte', 'entrainement', 'examen', 'competition')
                             ),

    -- Optionnel: collection
                         collection_id UUID,

    -- Paramètres du quiz
                         nb_questions INTEGER NOT NULL DEFAULT 10,
                         temps_limite_sec INTEGER,
                         score_minimum_success INTEGER NOT NULL DEFAULT 50,

    -- Visibilité
                         is_active BOOLEAN DEFAULT true,
                         is_public BOOLEAN DEFAULT true,

    -- Métadonnées
                         metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Statistiques
                         total_attempts INTEGER DEFAULT 0,
                         average_score DOUBLE PRECISION,

    -- Timestamps
                         created_at TIMESTAMPTZ DEFAULT NOW(),
                         updated_at TIMESTAMPTZ DEFAULT NOW(),
                         created_by UUID
);

-- Index quizzes
CREATE INDEX idx_quizzes_domain ON quizzes(domain);
CREATE INDEX idx_quizzes_domain_active ON quizzes(domain, is_active);
CREATE INDEX idx_quizzes_scope ON quizzes(scope);
CREATE INDEX idx_quizzes_active ON quizzes(is_active);
CREATE INDEX idx_quizzes_mode ON quizzes(mode);

-- ============================================
-- TABLE: questions
-- ============================================
CREATE TABLE questions (
                           id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                           quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,

                           ordre INTEGER NOT NULL,

    -- Type de question
                           type_question VARCHAR(50) NOT NULL CHECK (
                               type_question IN (
                                                 'qcm',
                                                 'vrai_faux',
                                                 'saisie_texte',
                                                 'carte_cliquable',
                                                 'ordre',
                                                 'association'
                                   )
                               ),

    -- Contenu de la question
                           question_data JSONB NOT NULL,

    -- Média associé (optionnel)
                           media_url TEXT,

    -- Cible générique (région, pays, etc.)
                           target_id UUID,

    -- Catégorisation
                           category VARCHAR(100),
                           subcategory VARCHAR(100),

    -- Scoring
                           points INTEGER NOT NULL DEFAULT 10,
                           temps_limite_sec INTEGER,

    -- Aide
                           hint TEXT,
                           explanation TEXT,

    -- Métadonnées
                           metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    -- Statistiques
                           total_attempts INTEGER DEFAULT 0,
                           correct_attempts INTEGER DEFAULT 0,

    -- Timestamps
                           created_at TIMESTAMPTZ DEFAULT NOW(),
                           updated_at TIMESTAMPTZ DEFAULT NOW(),

                           UNIQUE(quiz_id, ordre)
);

-- Index questions
CREATE INDEX idx_questions_quiz ON questions(quiz_id);
CREATE INDEX idx_questions_type ON questions(type_question);
CREATE INDEX idx_questions_target ON questions(target_id);
CREATE INDEX idx_questions_ordre ON questions(quiz_id, ordre);
CREATE INDEX idx_questions_category ON questions(category);
CREATE INDEX idx_questions_category_subcategory ON questions(category, subcategory);

-- ============================================
-- TABLE: reponses
-- ============================================
CREATE TABLE reponses (
                          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                          question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,

    -- Valeur textuelle de la réponse
                          valeur TEXT,

    -- Coordonnées géographiques (pour V1)
                          coordinates_point POINT,

    -- Référence à une région (pour V1)
                          region_id UUID,

    -- Validation
                          is_correct BOOLEAN NOT NULL,

    -- Ordre d'affichage (pour QCM)
                          ordre INTEGER DEFAULT 0,

    -- Tolérance pour questions géographiques (en mètres)
                          tolerance_meters INTEGER,

    -- Métadonnées
                          metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

                          created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index reponses
CREATE INDEX idx_reponses_question ON reponses(question_id);
CREATE INDEX idx_reponses_correct ON reponses(is_correct);
CREATE INDEX idx_reponses_region ON reponses(region_id);

-- ============================================
-- TABLE: sessions_quiz
-- ============================================
CREATE TABLE sessions_quiz (
                               id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

                               user_id UUID NOT NULL,
                               quiz_id UUID NOT NULL REFERENCES quizzes(id),

    -- Score
                               score INTEGER NOT NULL DEFAULT 0,
                               score_max INTEGER NOT NULL,
                               pourcentage DOUBLE PRECISION,

    -- Temps
                               temps_total_sec INTEGER,
                               date_debut TIMESTAMPTZ NOT NULL,
                               date_fin TIMESTAMPTZ,

    -- Status
                               status VARCHAR(20) NOT NULL CHECK (
                                   status IN ('en_cours', 'termine', 'abandonne')
                                   ) DEFAULT 'en_cours',

    -- Détails des réponses
                               reponses_detaillees JSONB NOT NULL DEFAULT '[]'::jsonb,

    -- Métadonnées
                               metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

                               created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index sessions
CREATE INDEX idx_sessions_user ON sessions_quiz(user_id);
CREATE INDEX idx_sessions_quiz ON sessions_quiz(quiz_id);
CREATE INDEX idx_sessions_status ON sessions_quiz(status);
CREATE INDEX idx_sessions_date ON sessions_quiz(date_debut);

-- ============================================
-- TABLE: reponses_utilisateur
-- ============================================
CREATE TABLE reponses_utilisateur (
                                      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

                                      session_id UUID NOT NULL REFERENCES sessions_quiz(id) ON DELETE CASCADE,
                                      question_id UUID NOT NULL REFERENCES questions(id),
                                      reponse_id UUID REFERENCES reponses(id),

    -- Réponse de l'utilisateur
                                      valeur_saisie TEXT,
                                      coordinates_cliquees POINT,

    -- Validation
                                      is_correct BOOLEAN NOT NULL,
                                      points_obtenus INTEGER NOT NULL DEFAULT 0,

    -- Temps
                                      temps_reponse_sec INTEGER NOT NULL,

    -- Métadonnées
                                      metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

                                      created_at TIMESTAMPTZ DEFAULT NOW(),

                                      UNIQUE(session_id, question_id)
);

-- Index reponses_utilisateur
CREATE INDEX idx_reponses_user_session ON reponses_utilisateur(session_id);
CREATE INDEX idx_reponses_user_question ON reponses_utilisateur(question_id);
CREATE INDEX idx_reponses_user_correct ON reponses_utilisateur(is_correct);

-- ============================================
-- TRIGGERS
-- ============================================

-- Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger sur quizzes
CREATE TRIGGER update_quizzes_updated_at
    BEFORE UPDATE ON quizzes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger sur questions
CREATE TRIGGER update_questions_updated_at
    BEFORE UPDATE ON questions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger sur domains
CREATE TRIGGER update_domains_updated_at
    BEFORE UPDATE ON domains
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Fonction pour calculer le pourcentage automatiquement
CREATE OR REPLACE FUNCTION update_session_pourcentage()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.score_max > 0 THEN
        NEW.pourcentage = (NEW.score::DOUBLE PRECISION / NEW.score_max::DOUBLE PRECISION) * 100;
ELSE
        NEW.pourcentage = 0;
END IF;
RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger sur sessions
CREATE TRIGGER update_sessions_pourcentage
    BEFORE INSERT OR UPDATE ON sessions_quiz
                         FOR EACH ROW
                         EXECUTE FUNCTION update_session_pourcentage();

-- ============================================
-- COMMENTAIRES
-- ============================================
COMMENT ON TABLE domains IS 'Domaines de quiz disponibles (geography, code_route, culture, etc.)';
COMMENT ON COLUMN quizzes.domain IS 'Domaine du quiz (geography, code_route, etc.)';
COMMENT ON COLUMN quizzes.scope IS 'Portée du quiz (europe, france, monde, etc.)';
COMMENT ON COLUMN quizzes.mode IS 'Mode de quiz (decouverte, entrainement, examen, competition)';
COMMENT ON COLUMN questions.media_url IS 'URL vers média (map://, https://, file://)';
COMMENT ON COLUMN questions.target_id IS 'ID cible générique (region, panneau, etc.)';
COMMENT ON COLUMN questions.category IS 'Catégorie principale (fleuves, reliefs, pays_regions, capitales, etc.)';
COMMENT ON COLUMN questions.subcategory IS 'Sous-catégorie optionnelle (hydrographie, montagnes, administration, etc.)';