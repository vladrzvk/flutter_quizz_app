-- Add category and subcategory to questions
ALTER TABLE questions
    ADD COLUMN IF NOT EXISTS category VARCHAR(100),
    ADD COLUMN IF NOT EXISTS subcategory VARCHAR(100);

-- Index for filtering
CREATE INDEX IF NOT EXISTS idx_questions_category ON questions(category);
CREATE INDEX IF NOT EXISTS idx_questions_category_subcategory ON questions(category, subcategory);

-- Comments
COMMENT ON COLUMN questions.category IS 'Catégorie principale (fleuves, reliefs, pays_regions, capitales, etc.)';
COMMENT ON COLUMN questions.subcategory IS 'Sous-catégorie optionnelle (hydrographie, montagnes, administration, etc.)';