-- Add migration script here
-- Reponses table
CREATE TABLE reponses (
                          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                          question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,

                          valeur TEXT,
                          coordinates_point POINT,
                          region_id UUID,

                          is_correct BOOLEAN NOT NULL,

                          ordre INTEGER DEFAULT 0,

                          tolerance_meters INTEGER,

                          metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

                          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX idx_reponses_question ON reponses(question_id);
CREATE INDEX idx_reponses_correct ON reponses(is_correct);
CREATE INDEX idx_reponses_region ON reponses(region_id);