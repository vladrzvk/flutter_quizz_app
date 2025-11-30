-- ============================================
-- SEED DATA COMPLET : Geography Quiz V0
-- À exécuter APRÈS 05-quiz-db.sql
-- ============================================

-- ============================================
-- CATÉGORIE : FLEUVES (3 questions)
-- ============================================

-- Question 1 : QCM - Plus long fleuve
INSERT INTO questions (
    id,
    quiz_id,
    ordre,
    type_question,
    question_data,
    category,
    subcategory,
    points,
    temps_limite_sec,
    hint,
    explanation
) VALUES (
    '00000000-0000-0000-0001-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    1,
    'qcm',
    '{"text": "Quel est le plus long fleuve de France ?"}'::jsonb,
    'fleuves',
    'hydrographie',
    10,
    15,
    'Il traverse le centre de la France',
    'La Loire est le plus long fleuve de France avec 1 006 km'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO reponses (question_id, valeur, is_correct, ordre) VALUES
    ('00000000-0000-0000-0001-000000000001'::uuid, 'La Loire', true, 1),
    ('00000000-0000-0000-0001-000000000001'::uuid, 'La Seine', false, 2),
    ('00000000-0000-0000-0001-000000000001'::uuid, 'Le Rhône', false, 3),
    ('00000000-0000-0000-0001-000000000001'::uuid, 'La Garonne', false, 4)
ON CONFLICT DO NOTHING;

-- Question 2 : Vrai/Faux - Rhône source
INSERT INTO questions (
    id,
    quiz_id,
    ordre,
    type_question,
    question_data,
    category,
    subcategory,
    points,
    temps_limite_sec,
    explanation
) VALUES (
    '00000000-0000-0000-0001-000000000002'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    2,
    'vrai_faux',
    '{"text": "Le Rhône prend sa source en Suisse"}'::jsonb,
    'fleuves',
    'hydrographie',
    10,
    10,
    'Le Rhône prend sa source dans le glacier du Rhône en Suisse'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO reponses (question_id, valeur, is_correct, ordre) VALUES
    ('00000000-0000-0000-0001-000000000002'::uuid, 'Vrai', true, 1),
    ('00000000-0000-0000-0001-000000000002'::uuid, 'Faux', false, 2)
ON CONFLICT DO NOTHING;

-- Question 3 : Saisie texte - Seine Paris
INSERT INTO questions (
    id,
    quiz_id,
    ordre,
    type_question,
    question_data,
    category,
    subcategory,
    points,
    temps_limite_sec,
    hint,
    explanation
) VALUES (
    '00000000-0000-0000-0001-000000000003'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    3,
    'saisie_texte',
    '{"text": "Quel fleuve traverse Paris ?"}'::jsonb,
    'fleuves',
    'hydrographie',
    10,
    15,
    'Célèbre pour ses ponts et ses bateaux-mouches',
    'La Seine traverse Paris d''est en ouest'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO reponses (question_id, valeur, is_correct) VALUES
    ('00000000-0000-0000-0001-000000000003'::uuid, 'seine', true),
    ('00000000-0000-0000-0001-000000000003'::uuid, 'la seine', true)
ON CONFLICT DO NOTHING;

-- ============================================
-- CATÉGORIE : RELIEFS (4 questions)
-- ============================================

-- Question 4 : QCM - Mont Blanc
INSERT INTO questions (
    id,
    quiz_id,
    ordre,
    type_question,
    question_data,
    category,
    subcategory,
    points,
    temps_limite_sec,
    hint,
    explanation
) VALUES (
    '00000000-0000-0000-0001-000000000004'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    4,
    'qcm',
    '{"text": "Quel est le point culminant des Alpes françaises ?"}'::jsonb,
    'reliefs',
    'montagnes',
    10,
    15,
    'C''est aussi le plus haut sommet d''Europe occidentale',
    'Le Mont Blanc culmine à 4 808 mètres'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO reponses (question_id, valeur, is_correct, ordre) VALUES
    ('00000000-0000-0000-0001-000000000004'::uuid, 'Le Mont Blanc', true, 1),
    ('00000000-0000-0000-0001-000000000004'::uuid, 'Le Mont Cervin', false, 2),
    ('00000000-0000-0000-0001-000000000004'::uuid, 'La Meije', false, 3),
    ('00000000-0000-0000-0001-000000000004'::uuid, 'Le Grand Combin', false, 4)
ON CONFLICT DO NOTHING;

-- Question 5 : Vrai/Faux - Puy de Dôme volcan actif
INSERT INTO questions (
    id,
    quiz_id,
    ordre,
    type_question,
    question_data,
    category,
    subcategory,
    points,
    temps_limite_sec,
    explanation
) VALUES (
    '00000000-0000-0000-0001-000000000005'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    5,
    'vrai_faux',
    '{"text": "Le Puy de Dôme est un volcan actif"}'::jsonb,
    'reliefs',
    'volcans',
    10,
    10,
    'Le Puy de Dôme est un volcan endormi depuis environ 8 500 ans'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO reponses (question_id, valeur, is_correct, ordre) VALUES
    ('00000000-0000-0000-0001-000000000005'::uuid, 'Faux', true, 1),
    ('00000000-0000-0000-0001-000000000005'::uuid, 'Vrai', false, 2)
ON CONFLICT DO NOTHING;

-- Question 6 : QCM - Pyrénées
INSERT INTO questions (
    id,
    quiz_id,
    ordre,
    type_question,
    question_data,
    category,
    subcategory,
    points,
    temps_limite_sec,
    hint,
    explanation
) VALUES (
    '00000000-0000-0000-0001-000000000006'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    6,
    'qcm',
    '{"text": "Quelle chaîne de montagnes sépare la France de l''Espagne ?"}'::jsonb,
    'reliefs',
    'montagnes',
    10,
    15,
    'Elle s''étend sur environ 430 km',
    'Les Pyrénées forment une frontière naturelle entre la France et l''Espagne'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO reponses (question_id, valeur, is_correct, ordre) VALUES
    ('00000000-0000-0000-0001-000000000006'::uuid, 'Les Pyrénées', true, 1),
    ('00000000-0000-0000-0001-000000000006'::uuid, 'Les Alpes', false, 2),
    ('00000000-0000-0000-0001-000000000006'::uuid, 'Les Vosges', false, 3),
    ('00000000-0000-0000-0001-000000000006'::uuid, 'Le Jura', false, 4)
ON CONFLICT DO NOTHING;

-- Question 7 : Saisie texte - Massif Central
INSERT INTO questions (
    id,
    quiz_id,
    ordre,
    type_question,
    question_data,
    category,
    subcategory,
    points,
    temps_limite_sec,
    hint,
    explanation
) VALUES (
    '00000000-0000-0000-0001-000000000007'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    7,
    'saisie_texte',
    '{"text": "Quel massif occupe le centre de la France ?"}'::jsonb,
    'reliefs',
    'montagnes',
    10,
    15,
    'Il contient de nombreux volcans endormis',
    'Le Massif central occupe environ 15% du territoire français'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO reponses (question_id, valeur, is_correct) VALUES
    ('00000000-0000-0000-0001-000000000007'::uuid, 'massif central', true),
    ('00000000-0000-0000-0001-000000000007'::uuid, 'le massif central', true)
ON CONFLICT DO NOTHING;

-- ============================================
-- CATÉGORIE : PAYS/RÉGIONS (3 questions)
-- ============================================

-- Question 8 : QCM - Nombre de régions
INSERT INTO questions (
    id,
    quiz_id,
    ordre,
    type_question,
    question_data,
    category,
    subcategory,
    points,
    temps_limite_sec,
    hint,
    explanation
) VALUES (
    '00000000-0000-0000-0001-000000000008'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    8,
    'qcm',
    '{"text": "Combien de régions compte la France métropolitaine ?"}'::jsonb,
    'pays_regions',
    'administration',
    10,
    15,
    'Depuis la réforme territoriale de 2016',
    'La France métropolitaine compte 13 régions depuis 2016'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO reponses (question_id, valeur, is_correct, ordre) VALUES
    ('00000000-0000-0000-0001-000000000008'::uuid, '13', true, 1),
    ('00000000-0000-0000-0001-000000000008'::uuid, '12', false, 2),
    ('00000000-0000-0000-0001-000000000008'::uuid, '18', false, 3),
    ('00000000-0000-0000-0001-000000000008'::uuid, '22', false, 4)
ON CONFLICT DO NOTHING;

-- Question 9 : Vrai/Faux - Corse région
INSERT INTO questions (
    id,
    quiz_id,
    ordre,
    type_question,
    question_data,
    category,
    subcategory,
    points,
    temps_limite_sec,
    explanation
) VALUES (
    '00000000-0000-0000-0001-000000000009'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    9,
    'vrai_faux',
    '{"text": "La Corse est une région française"}'::jsonb,
    'pays_regions',
    'administration',
    10,
    10,
    'La Corse est une collectivité territoriale unique depuis 2018'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO reponses (question_id, valeur, is_correct, ordre) VALUES
    ('00000000-0000-0000-0001-000000000009'::uuid, 'Vrai', true, 1),
    ('00000000-0000-0000-0001-000000000009'::uuid, 'Faux', false, 2)
ON CONFLICT DO NOTHING;

-- Question 10 : Saisie texte - Chef-lieu Lyon
INSERT INTO questions (
    id,
    quiz_id,
    ordre,
    type_question,
    question_data,
    category,
    subcategory,
    points,
    temps_limite_sec,
    hint,
    explanation
) VALUES (
    '00000000-0000-0000-0001-000000000010'::uuid,
    '00000000-0000-0000-0000-000000000001'::uuid,
    10,
    'saisie_texte',
    '{"text": "Quelle région a pour chef-lieu Lyon ?"}'::jsonb,
    'pays_regions',
    'administration',
    10,
    20,
    'C''est la 2ème région la plus peuplée de France',
    'Auvergne-Rhône-Alpes a Lyon comme chef-lieu'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO reponses (question_id, valeur, is_correct) VALUES
    ('00000000-0000-0000-0001-000000000010'::uuid, 'auvergne-rhône-alpes', true),
    ('00000000-0000-0000-0001-000000000010'::uuid, 'auvergne rhône alpes', true),
    ('00000000-0000-0000-0001-000000000010'::uuid, 'aura', true)
ON CONFLICT DO NOTHING;

-- ============================================
-- RÉSUMÉ
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Seed data inserted successfully!';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Quiz: Géographie de France - Découverte';
    RAISE NOTICE 'Questions: 10';
    RAISE NOTICE 'Categories:';
    RAISE NOTICE '  - Fleuves: 3 questions';
    RAISE NOTICE '  - Reliefs: 4 questions';
    RAISE NOTICE '  - Pays/Régions: 3 questions';
    RAISE NOTICE '============================================';
END $$;
