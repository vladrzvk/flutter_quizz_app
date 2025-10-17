-- Add migration script here
-- Fix DECIMAL types to DOUBLE PRECISION for Rust f64 compatibility

-- Table sessions_quiz: change pourcentage
ALTER TABLE sessions_quiz
ALTER COLUMN pourcentage TYPE DOUBLE PRECISION;

-- Table quizzes: change average_score
ALTER TABLE quizzes
ALTER COLUMN average_score TYPE DOUBLE PRECISION;

-- Note: La fonction update_session_pourcentage() continuera de fonctionner
-- car DOUBLE PRECISION supporte aussi les opérations arithmétiques