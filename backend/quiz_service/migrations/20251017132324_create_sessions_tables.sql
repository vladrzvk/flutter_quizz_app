-- Add migration script here
-- Sessions table
CREATE TABLE sessions_quiz (
                               id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                               user_id UUID NOT NULL,
                               quiz_id UUID NOT NULL REFERENCES quizzes(id),

                               score INTEGER NOT NULL DEFAULT 0,
                               score_max INTEGER NOT NULL,
                               pourcentage DECIMAL(5, 2),

                               temps_total_sec INTEGER,
                               date_debut TIMESTAMP WITH TIME ZONE NOT NULL,
                               date_fin TIMESTAMP WITH TIME ZONE,

                               status VARCHAR(20) NOT NULL CHECK (
                                   status IN ('en_cours', 'termine', 'abandonne')
                                   ) DEFAULT 'en_cours',

                               reponses_detaillees JSONB NOT NULL DEFAULT '[]'::jsonb,

                               metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

                               created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX idx_sessions_user ON sessions_quiz(user_id);
CREATE INDEX idx_sessions_quiz ON sessions_quiz(quiz_id);
CREATE INDEX idx_sessions_status ON sessions_quiz(status);
CREATE INDEX idx_sessions_date ON sessions_quiz(date_debut);

-- Reponses utilisateur table
CREATE TABLE reponses_utilisateur (
                                      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

                                      session_id UUID NOT NULL REFERENCES sessions_quiz(id) ON DELETE CASCADE,
                                      question_id UUID NOT NULL REFERENCES questions(id),
                                      reponse_id UUID REFERENCES reponses(id),

                                      valeur_saisie TEXT,
                                      coordinates_cliquees POINT,

                                      is_correct BOOLEAN NOT NULL,
                                      points_obtenus INTEGER NOT NULL DEFAULT 0,

                                      temps_reponse_sec INTEGER NOT NULL,

                                      metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

                                      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

                                      UNIQUE(session_id, question_id)
);

-- Index
CREATE INDEX idx_reponses_user_session ON reponses_utilisateur(session_id);
CREATE INDEX idx_reponses_user_question ON reponses_utilisateur(question_id);
CREATE INDEX idx_reponses_user_correct ON reponses_utilisateur(is_correct);

-- Fonction pour calculer le pourcentage automatiquement
CREATE OR REPLACE FUNCTION update_session_pourcentage()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.score_max > 0 THEN
        NEW.pourcentage = (NEW.score::DECIMAL / NEW.score_max::DECIMAL) * 100;
ELSE
        NEW.pourcentage = 0;
END IF;
RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_sessions_pourcentage
    BEFORE INSERT OR UPDATE ON sessions_quiz
                         FOR EACH ROW
                         EXECUTE FUNCTION update_session_pourcentage();