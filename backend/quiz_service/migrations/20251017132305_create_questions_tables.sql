-- Add migration script here
-- Questions table
CREATE TABLE questions (
                           id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                           quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,

                           ordre INTEGER NOT NULL,

                           type_question VARCHAR(50) NOT NULL CHECK (
                               type_question IN (
                                                 'choix_multiple',
                                                 'localisation_carte',
                                                 'capitale',
                                                 'frontiere',
                                                 'reperage_carte',
                                                 'trace_region',
                                                 'association'
                                   )
                               ),

                           question_data JSONB NOT NULL,

                           region_cible_id UUID,

                           points INTEGER NOT NULL DEFAULT 10,
                           temps_limite_sec INTEGER,

                           hint TEXT,
                           explanation TEXT,

                           metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

                           total_attempts INTEGER DEFAULT 0,
                           correct_attempts INTEGER DEFAULT 0,

                           created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                           updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

                           UNIQUE(quiz_id, ordre)
);

-- Index
CREATE INDEX idx_questions_quiz ON questions(quiz_id);
CREATE INDEX idx_questions_type ON questions(type_question);
CREATE INDEX idx_questions_region ON questions(region_cible_id);
CREATE INDEX idx_questions_ordre ON questions(quiz_id, ordre);

CREATE TRIGGER update_questions_updated_at
    BEFORE UPDATE ON questions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();