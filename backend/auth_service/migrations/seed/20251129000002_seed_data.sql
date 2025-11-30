-- ============================================
-- AUTH SERVICE - Seed Data
-- Rôles et permissions par défaut
-- ============================================

BEGIN;

-- ============================================
-- ROLES SYSTÈME
-- ============================================

INSERT INTO roles (id, name, description, priority, is_system) VALUES
                                                                   (gen_random_uuid(), 'guest', 'Guest user with limited access', 0, true),
                                                                   (gen_random_uuid(), 'user', 'Standard registered user', 10, true),
                                                                   (gen_random_uuid(), 'premium', 'Premium subscriber', 20, true),
                                                                   (gen_random_uuid(), 'admin', 'Administrator with full access', 100, true)
    ON CONFLICT (name) DO NOTHING;

-- ============================================
-- PERMISSIONS SYSTÈME
-- ============================================

-- Auth permissions
INSERT INTO permissions (service, action, resource, name, description) VALUES
                                                                           ('auth', 'login', 'self', 'auth:login:self', 'Login to own account'),
                                                                           ('auth', 'register', 'public', 'auth:register:public', 'Register new account'),
                                                                           ('auth', 'refresh', 'self', 'auth:refresh:self', 'Refresh own token')
    ON CONFLICT (service, action, resource) DO NOTHING;

-- User permissions
INSERT INTO permissions (service, action, resource, name, description) VALUES
                                                                           ('user', 'read', 'self', 'user:read:self', 'Read own profile'),
                                                                           ('user', 'update', 'self', 'user:update:self', 'Update own profile'),
                                                                           ('user', 'delete', 'self', 'user:delete:self', 'Delete own account'),
                                                                           ('user', 'list', 'all', 'user:list:all', 'List all users (admin)'),
                                                                           ('user', 'read', 'all', 'user:read:all', 'Read any user profile (admin)'),
                                                                           ('user', 'update', 'status', 'user:update:status', 'Update user status (admin)'),
                                                                           ('user', 'delete', 'all', 'user:delete:all', 'Delete any user (admin)')
    ON CONFLICT (service, action, resource) DO NOTHING;

-- Quiz permissions (générique pour réutilisabilité)
INSERT INTO permissions (service, action, resource, name, description) VALUES
                                                                           ('quiz', 'play', 'free', 'quiz:play:free', 'Play free quizzes'),
                                                                           ('quiz', 'play', 'premium', 'quiz:play:premium', 'Play premium quizzes'),
                                                                           ('quiz', 'create', 'own', 'quiz:create:own', 'Create own quizzes'),
                                                                           ('quiz', 'view', 'stats', 'quiz:view:stats', 'View quiz statistics')
    ON CONFLICT (service, action, resource) DO NOTHING;

-- Admin permissions
INSERT INTO permissions (service, action, resource, name, description) VALUES
                                                                           ('admin', 'manage', 'all', 'admin:manage:all', 'Full admin access'),
                                                                           ('admin', 'manage', 'users', 'admin:manage:users', 'Manage users'),
                                                                           ('admin', 'manage', 'roles', 'admin:manage:roles', 'Manage roles'),
                                                                           ('admin', 'manage', 'permissions', 'admin:manage:permissions', 'Manage permissions')
    ON CONFLICT (service, action, resource) DO NOTHING;

-- ============================================
-- ASSIGNATION PERMISSIONS AUX ROLES
-- ============================================

-- GUEST: Accès très limité
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'guest' AND p.name IN (
                                      'auth:register:public',
                                      'quiz:play:free'
    )
    ON CONFLICT DO NOTHING;

-- USER: Accès standard
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'user' AND p.name IN (
                                     'auth:login:self',
                                     'auth:refresh:self',
                                     'user:read:self',
                                     'user:update:self',
                                     'user:delete:self',
                                     'quiz:play:free',
                                     'quiz:create:own',
                                     'quiz:view:stats'
    )
    ON CONFLICT DO NOTHING;

-- PREMIUM: Accès étendu
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'premium' AND p.name IN (
                                        'auth:login:self',
                                        'auth:refresh:self',
                                        'user:read:self',
                                        'user:update:self',
                                        'user:delete:self',
                                        'quiz:play:free',
                                        'quiz:play:premium',
                                        'quiz:create:own',
                                        'quiz:view:stats'
    )
    ON CONFLICT DO NOTHING;

-- ADMIN: Accès complet
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'admin'
    ON CONFLICT DO NOTHING;

-- ============================================
-- UTILISATEUR ADMIN PAR DÉFAUT (Development uniquement)
-- ============================================
-- Password: Admin123! (bcrypt hash avec cost 12)

DO $$
DECLARE
admin_user_id UUID;
    admin_role_id UUID;
BEGIN
    -- Créer l'admin si n'existe pas
INSERT INTO users (email, password_hash, status, is_guest, display_name)
VALUES (
           'admin@example.com',
           '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5oBzS.N8VCm/C', -- Admin123!
           'premium',
           false,
           'System Administrator'
       )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO admin_user_id;

-- Si l'admin a été créé
IF admin_user_id IS NOT NULL THEN
        -- Récupérer le role admin
SELECT id INTO admin_role_id FROM roles WHERE name = 'admin';

-- Assigner le rôle admin
INSERT INTO user_roles (user_id, role_id)
VALUES (admin_user_id, admin_role_id)
    ON CONFLICT DO NOTHING;

RAISE NOTICE 'Admin user created: admin@example.com / Admin123!';
ELSE
        RAISE NOTICE 'Admin user already exists';
END IF;
END $$;

-- ============================================
-- COMMENTAIRES
-- ============================================

COMMENT ON TABLE roles IS 'Roles système avec hiérarchie (guest < user < premium < admin)';
COMMENT ON TABLE permissions IS 'Permissions au format service:action:resource pour flexibilité';

COMMIT;

-- ============================================
-- VÉRIFICATION
-- ============================================

-- Compter les rôles créés
SELECT 'Roles created:', COUNT(*) FROM roles;

-- Compter les permissions créées
SELECT 'Permissions created:', COUNT(*) FROM permissions;

-- Afficher les permissions par rôle
SELECT
    r.name AS role,
    r.priority,
    COUNT(p.id) AS permissions_count
FROM roles r
         LEFT JOIN role_permissions rp ON r.id = rp.role_id
         LEFT JOIN permissions p ON rp.permission_id = p.id
GROUP BY r.id, r.name, r.priority
ORDER BY r.priority DESC;