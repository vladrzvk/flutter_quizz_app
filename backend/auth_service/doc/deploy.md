# 🚀 Guide de Déploiement Production - Auth Service

## Checklist de Sécurité Pré-Déploiement

### 1. Secrets et Configuration

- [ ] Générer JWT_SECRET fort (32+ caractères aléatoires)
  ```bash
  openssl rand -base64 32
  ```

- [ ] Générer JWT_REFRESH_SECRET fort (différent de JWT_SECRET)
  ```bash
  openssl rand -base64 32
  ```

- [ ] Configurer CORS_ORIGINS avec whitelist stricte
  ```env
  CORS_ORIGINS=https://app.example.com,https://www.example.com
  ```

- [ ] Activer CAPTCHA
  ```env
  HCAPTCHA_ENABLED=true
  HCAPTCHA_SECRET=your-production-secret
  ```

- [ ] Augmenter BCRYPT_COST
  ```env
  BCRYPT_COST=14  # ~1.6s par hash
  ```

- [ ] Configurer DATABASE_URL sécurisé
    - Utiliser un utilisateur dédié avec permissions minimales
    - Connexion SSL/TLS
    - Mots de passe forts

### 2. Infrastructure

- [ ] HTTPS obligatoire (certificat SSL/TLS valide)
- [ ] Firewall configuré
    - Port 3001 non exposé publiquement
    - Accès uniquement via API Gateway
- [ ] Load balancer configuré (si nécessaire)
- [ ] Monitoring actif
    - Prometheus/Grafana
    - Logs centralisés (ELK, Datadog, etc.)
- [ ] Backup base de données automatique

### 3. Base de Données

```sql
-- Créer un utilisateur dédié avec permissions minimales
CREATE USER auth_prod WITH ENCRYPTED PASSWORD 'strong-random-password';
GRANT CONNECT ON DATABASE auth_db TO auth_prod;
GRANT USAGE ON SCHEMA public TO auth_prod;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO auth_prod;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO auth_prod;
```

## Déploiement Docker

### 1. Build de l'image

```bash
# Build
docker build -t auth-service:v1.0.0 .

# Tag pour registry
docker tag auth-service:v1.0.0 your-registry.com/auth-service:v1.0.0

# Push
docker push your-registry.com/auth-service:v1.0.0
```

### 2. Déploiement avec Docker Compose (Production)

Créer `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  auth-service:
    image: your-registry.com/auth-service:v1.0.0
    container_name: auth-service-prod
    environment:
      ENVIRONMENT: production
      SERVER_HOST: 0.0.0.0
      SERVER_PORT: 3001
      DATABASE_URL: ${DATABASE_URL}
      JWT_SECRET: ${JWT_SECRET}
      JWT_REFRESH_SECRET: ${JWT_REFRESH_SECRET}
      JWT_ACCESS_EXPIRATION_MINUTES: 15
      JWT_REFRESH_EXPIRATION_DAYS: 7
      BCRYPT_COST: 14
      RATE_LIMIT_RPM: 30
      LOGIN_ATTEMPTS_BEFORE_CAPTCHA: 2
      LOGIN_MAX_ATTEMPTS_BEFORE_BLOCK: 5
      HCAPTCHA_ENABLED: true
      HCAPTCHA_SECRET: ${HCAPTCHA_SECRET}
      DEVICE_FINGERPRINT_MAX_GUESTS: 3
      CORS_ORIGINS: ${CORS_ORIGINS}
      RUST_LOG: auth_service=info,tower_http=info
    ports:
      - "127.0.0.1:3001:3001"  # Bind sur localhost uniquement
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - prod-network
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M

networks:
  prod-network:
    external: true
```

Lancer:

```bash
# Charger les secrets depuis fichier .env.prod
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

## Déploiement Kubernetes

### 1. Secrets

```yaml
# secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: auth-service-secrets
  namespace: production
type: Opaque
stringData:
  jwt-secret: "your-jwt-secret-32chars-minimum"
  jwt-refresh-secret: "your-refresh-secret-32chars"
  database-url: "postgresql://user:pass@host:5432/auth_db"
  hcaptcha-secret: "your-hcaptcha-secret"
```

```bash
kubectl apply -f secrets.yaml
```

### 2. ConfigMap

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: auth-service-config
  namespace: production
data:
  ENVIRONMENT: "production"
  SERVER_HOST: "0.0.0.0"
  SERVER_PORT: "3001"
  JWT_ACCESS_EXPIRATION_MINUTES: "15"
  JWT_REFRESH_EXPIRATION_DAYS: "7"
  BCRYPT_COST: "14"
  RATE_LIMIT_RPM: "30"
  LOGIN_ATTEMPTS_BEFORE_CAPTCHA: "2"
  HCAPTCHA_ENABLED: "true"
  CORS_ORIGINS: "https://app.example.com"
```

### 3. Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
    spec:
      containers:
      - name: auth-service
        image: your-registry.com/auth-service:v1.0.0
        ports:
        - containerPort: 3001
        envFrom:
        - configMapRef:
            name: auth-service-config
        env:
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: auth-service-secrets
              key: jwt-secret
        - name: JWT_REFRESH_SECRET
          valueFrom:
            secretKeyRef:
              name: auth-service-secrets
              key: jwt-refresh-secret
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: auth-service-secrets
              key: database-url
        - name: HCAPTCHA_SECRET
          valueFrom:
            secretKeyRef:
              name: auth-service-secrets
              key: hcaptcha-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1"
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3001
          initialDelaySeconds: 10
          periodSeconds: 5
```

### 4. Service

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: auth-service
  namespace: production
spec:
  type: ClusterIP
  ports:
  - port: 3001
    targetPort: 3001
    protocol: TCP
  selector:
    app: auth-service
```

### 5. Déployer

```bash
kubectl apply -f configmap.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

## Monitoring

### Prometheus Metrics

Ajouter au service (future implémentation):

```rust
// Dans main.rs
use prometheus::{Encoder, TextEncoder, Registry};

// Métriques à tracker:
// - auth_login_attempts_total
// - auth_login_failures_total
// - auth_captcha_required_total
// - auth_sessions_active
// - auth_quotas_consumed_total
```

### Logs

```bash
# Voir les logs en temps réel
kubectl logs -f deployment/auth-service -n production

# Logs des 100 dernières lignes
kubectl logs --tail=100 deployment/auth-service -n production
```

## Rollback

```bash
# Voir l'historique des déploiements
kubectl rollout history deployment/auth-service -n production

# Rollback vers version précédente
kubectl rollout undo deployment/auth-service -n production

# Rollback vers version spécifique
kubectl rollout undo deployment/auth-service --to-revision=2 -n production
```

## Tests Post-Déploiement

### 1. Health Checks

```bash
curl https://auth.example.com/health
curl https://auth.example.com/ready
```

### 2. Register/Login Flow

```bash
# Register
curl -X POST https://auth.example.com/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!",
    "display_name": "Test User"
  }'

# Login
curl -X POST https://auth.example.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!"
  }'
```

### 3. Rate Limiting

```bash
# Tester le rate limiting
for i in {1..10}; do
  curl -X POST https://auth.example.com/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"fake@test.com","password":"wrong"}' &
done
```

### 4. CAPTCHA

```bash
# Après 3 échecs, CAPTCHA requis
curl -X POST https://auth.example.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "wrong"
  }'
# Répéter 3 fois, puis vérifier erreur "CAPTCHA required"
```

## Maintenance

### Nettoyage des anciennes données

```sql
-- Supprimer les tentatives de login > 7 jours
DELETE FROM login_attempts WHERE attempted_at < NOW() - INTERVAL '7 days';

-- Supprimer les sessions expirées > 30 jours
DELETE FROM jwt_sessions WHERE expires_at < NOW() - INTERVAL '30 days';

-- Supprimer les consommations quota > 7 jours
DELETE FROM quota_consumptions WHERE consumed_at < NOW() - INTERVAL '7 days';
```

Créer un cron job pour exécuter périodiquement.

## Support

Pour tout problème en production:
1. Consulter les logs
2. Vérifier les métriques Prometheus
3. Contacter l'équipe DevOps
4. Créer un incident si nécessaire

## Checklist Finale

- [ ] Tous les secrets en production sont différents du dev
- [ ] HTTPS activé avec certificat valide
- [ ] CORS configuré strictement
- [ ] CAPTCHA activé et testé
- [ ] Rate limiting testé
- [ ] Monitoring actif
- [ ] Logs centralisés configurés
- [ ] Backup DB automatique configuré
- [ ] Health checks fonctionnels
- [ ] Tests de charge effectués
- [ ] Plan de rollback documenté
- [ ] Équipe formée sur les procédures