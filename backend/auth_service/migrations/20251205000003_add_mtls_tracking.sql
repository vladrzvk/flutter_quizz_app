-- ============================================
-- AUTH SERVICE - mTLS Tracking & Security
-- Migration: Ajout support mTLS avec tracking
-- ============================================

BEGIN;

-- ============================================
-- TRUSTED_SERVICES : Services autorisés via mTLS
-- ============================================
CREATE TABLE trusted_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Identification service
    service_name VARCHAR(50) UNIQUE NOT NULL,   -- 'quiz-service', 'gateway', 'file-service'
    certificate_cn VARCHAR(255) NOT NULL,       -- Common Name (CN) du certificat client
    
    -- Status
    enabled BOOLEAN DEFAULT true,               -- Permet de désactiver sans supprimer
    
    -- Description
    description TEXT,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Contraintes
    CONSTRAINT service_name_format CHECK (
        service_name ~* '^[a-z0-9-]+$'          -- Format: lowercase, alphanumeric, hyphens
    )
);

-- Index
CREATE INDEX idx_trusted_services_name ON trusted_services(service_name);
CREATE INDEX idx_trusted_services_enabled ON trusted_services(enabled) WHERE enabled = true;
CREATE INDEX idx_trusted_services_cn ON trusted_services(certificate_cn);

-- Trigger pour updated_at
CREATE TRIGGER update_trusted_services_updated_at
    BEFORE UPDATE ON trusted_services
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- MTLS_CONNECTIONS : Log des connexions mTLS
-- ============================================
CREATE TABLE mtls_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Service qui se connecte
    service_id UUID REFERENCES trusted_services(id) ON DELETE SET NULL,
    certificate_cn VARCHAR(255) NOT NULL,
    
    -- Résultat de la connexion
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(100),
    
    -- Contexte
    endpoint VARCHAR(100),                      -- Endpoint appelé
    ip_address INET,
    user_agent TEXT,
    
    -- Métadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    connected_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Nettoyage automatique après 30 jours
    CONSTRAINT connection_recent CHECK (connected_at > NOW() - INTERVAL '30 days')
);

-- Index
CREATE INDEX idx_mtls_connections_service ON mtls_connections(service_id, connected_at DESC);
CREATE INDEX idx_mtls_connections_cn ON mtls_connections(certificate_cn, connected_at DESC);
CREATE INDEX idx_mtls_connections_success ON mtls_connections(success, connected_at DESC);
CREATE INDEX idx_mtls_connections_time ON mtls_connections(connected_at DESC);

-- ============================================
-- MODIFICATIONS : Ajouter client_cert_cn aux tables existantes
-- ============================================

-- Audit logs : Tracer le service qui a effectué l'action
ALTER TABLE audit_logs 
    ADD COLUMN client_cert_cn VARCHAR(255),
    ADD COLUMN service_name VARCHAR(50);

CREATE INDEX idx_audit_logs_service ON audit_logs(service_name) WHERE service_name IS NOT NULL;
CREATE INDEX idx_audit_logs_cert_cn ON audit_logs(client_cert_cn) WHERE client_cert_cn IS NOT NULL;

-- JWT Sessions : Tracer quel service a créé la session (si applicable)
ALTER TABLE jwt_sessions 
    ADD COLUMN client_cert_cn VARCHAR(255),
    ADD COLUMN created_by_service VARCHAR(50);

CREATE INDEX idx_jwt_sessions_service ON jwt_sessions(created_by_service) WHERE created_by_service IS NOT NULL;

-- ============================================
-- SEED DATA : Services initiaux autorisés
-- ============================================

-- Services autorisés par défaut
INSERT INTO trusted_services (service_name, certificate_cn, description, enabled) VALUES
    ('api-gateway', 'api-gateway.internal', 'API Gateway principal', true),
    ('quiz-service', 'quiz-service.internal', 'Service Quiz', true),
    ('file-service', 'file-service.internal', 'Service Fichiers', true),
    ('admin-panel', 'admin-panel.internal', 'Panel Admin', true)
ON CONFLICT (service_name) DO NOTHING;

-- ============================================
-- VIEWS : Vues utiles pour monitoring mTLS
-- ============================================

-- Vue : Connexions mTLS récentes (dernières 24h)
CREATE VIEW recent_mtls_connections AS
SELECT 
    mc.*,
    ts.service_name,
    ts.enabled AS service_enabled
FROM mtls_connections mc
LEFT JOIN trusted_services ts ON mc.service_id = ts.id
WHERE mc.connected_at > NOW() - INTERVAL '24 hours'
ORDER BY mc.connected_at DESC;

-- Vue : Statistiques mTLS par service
CREATE VIEW mtls_service_stats AS
SELECT 
    ts.service_name,
    ts.enabled,
    COUNT(mc.id) AS total_connections,
    COUNT(mc.id) FILTER (WHERE mc.success = true) AS successful_connections,
    COUNT(mc.id) FILTER (WHERE mc.success = false) AS failed_connections,
    MAX(mc.connected_at) AS last_connection,
    ROUND(
        100.0 * COUNT(mc.id) FILTER (WHERE mc.success = true) / NULLIF(COUNT(mc.id), 0),
        2
    ) AS success_rate_percent
FROM trusted_services ts
LEFT JOIN mtls_connections mc ON ts.id = mc.service_id
    AND mc.connected_at > NOW() - INTERVAL '7 days'
GROUP BY ts.id, ts.service_name, ts.enabled
ORDER BY total_connections DESC;

-- Vue : Activité audit par service
CREATE VIEW service_audit_activity AS
SELECT 
    al.service_name,
    al.action,
    COUNT(*) AS action_count,
    MAX(al.created_at) AS last_action
FROM audit_logs al
WHERE al.service_name IS NOT NULL
  AND al.created_at > NOW() - INTERVAL '7 days'
GROUP BY al.service_name, al.action
ORDER BY action_count DESC;

-- ============================================
-- FONCTIONS : Helpers pour mTLS
-- ============================================

-- Fonction : Vérifier si un service est autorisé
CREATE OR REPLACE FUNCTION is_service_trusted(cert_cn_input VARCHAR(255))
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT 1 FROM trusted_services
        WHERE certificate_cn = cert_cn_input
          AND enabled = true
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Fonction : Log connexion mTLS
CREATE OR REPLACE FUNCTION log_mtls_connection(
    cert_cn_input VARCHAR(255),
    success_input BOOLEAN,
    endpoint_input VARCHAR(100) DEFAULT NULL,
    ip_input INET DEFAULT NULL,
    failure_reason_input VARCHAR(100) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    connection_id UUID;
    service_id_var UUID;
BEGIN
    -- Récupérer l'ID du service si connu
    SELECT id INTO service_id_var
    FROM trusted_services
    WHERE certificate_cn = cert_cn_input;
    
    -- Insérer le log
    INSERT INTO mtls_connections (
        service_id,
        certificate_cn,
        success,
        failure_reason,
        endpoint,
        ip_address
    ) VALUES (
        service_id_var,
        cert_cn_input,
        success_input,
        failure_reason_input,
        endpoint_input,
        ip_input
    )
    RETURNING id INTO connection_id;
    
    RETURN connection_id;
END;
$$ LANGUAGE plpgsql;

-- Fonction : Nettoyer les vieux logs mTLS (>30 jours)
CREATE OR REPLACE FUNCTION cleanup_old_mtls_connections()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM mtls_connections
    WHERE connected_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTAIRES
-- ============================================
COMMENT ON TABLE trusted_services IS 'Services autorisés à se connecter via mTLS';
COMMENT ON TABLE mtls_connections IS 'Logs des connexions mTLS pour audit et monitoring';

COMMENT ON COLUMN trusted_services.service_name IS 'Nom unique du service (ex: quiz-service)';
COMMENT ON COLUMN trusted_services.certificate_cn IS 'Common Name (CN) du certificat client attendu';
COMMENT ON COLUMN trusted_services.enabled IS 'Service actif ou désactivé (sans suppression)';

COMMENT ON COLUMN mtls_connections.success IS 'true = connexion réussie, false = rejetée';
COMMENT ON COLUMN mtls_connections.failure_reason IS 'Raison du rejet (certificate invalid, service disabled, etc.)';

COMMENT ON COLUMN audit_logs.client_cert_cn IS 'CN du certificat client si action via mTLS';
COMMENT ON COLUMN audit_logs.service_name IS 'Nom du service si action effectuée par un service';

COMMENT ON COLUMN jwt_sessions.created_by_service IS 'Service ayant créé la session (si via mTLS)';

COMMENT ON FUNCTION is_service_trusted IS 'Vérifie si un certificat CN correspond à un service autorisé';
COMMENT ON FUNCTION log_mtls_connection IS 'Enregistre une tentative de connexion mTLS';
COMMENT ON FUNCTION cleanup_old_mtls_connections IS 'Supprime les logs mTLS > 30 jours';

-- ============================================
-- VÉRIFICATIONS
-- ============================================

-- Afficher les services configurés
SELECT 'Trusted services configured:', COUNT(*) FROM trusted_services;

-- Tester la fonction is_service_trusted
SELECT 
    'Service quiz-service.internal is trusted:',
    is_service_trusted('quiz-service.internal');

COMMIT;

-- ============================================
-- NOTES D'UTILISATION
-- ============================================

-- Pour ajouter un nouveau service autorisé :
-- INSERT INTO trusted_services (service_name, certificate_cn, description) 
-- VALUES ('new-service', 'new-service.internal', 'Description');

-- Pour désactiver temporairement un service :
-- UPDATE trusted_services SET enabled = false WHERE service_name = 'service-name';

-- Pour logger une connexion mTLS depuis l'application :
-- SELECT log_mtls_connection(
--     'quiz-service.internal',  -- CN du certificat
--     true,                      -- success
--     '/api/users/me',          -- endpoint
--     '10.0.0.5'::inet,         -- IP
--     NULL                       -- failure_reason (null si succès)
-- );

-- Pour nettoyer les vieux logs (à exécuter périodiquement) :
-- SELECT cleanup_old_mtls_connections();
