# 🔒 Sécurité

Guide de sécurité pour l'application Quiz Géo.

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Authentification & Autorisation](#authentification--autorisation)
3. [Secrets Management](#secrets-management)
4. [Network Security](#network-security)
5. [Container Security](#container-security)
6. [Database Security](#database-security)
7. [Compliance & Audit](#compliance--audit)

---

## 🎯 Vue d'Ensemble

### Principes de Sécurité
```
┌─────────────────────────────────────────────┐
│          SECURITY LAYERS                     │
├─────────────────────────────────────────────┤
│                                             │
│  🌐 Network (Firewall, TLS)                │
│       ↓                                      │
│  🔐 Authentication (JWT)                    │
│       ↓                                      │
│  ✅ Authorization (RBAC)                    │
│       ↓                                      │
│  🐳 Container (Non-root, Read-only)         │
│       ↓                                      │
│  🗄️  Data (Encryption at rest)             │
│                                             │
└─────────────────────────────────────────────┘
```

### Checklist Sécurité

- [ ] TLS/HTTPS activé partout
- [ ] Secrets chiffrés (Vault ou K8s Secrets)
- [ ] JWT avec expiration courte
- [ ] Rate limiting sur les APIs
- [ ] Input validation
- [ ] SQL injection protection (SQLx)
- [ ] XSS protection
- [ ] CORS configuré
- [ ] Containers non-root
- [ ] Images scannées (Trivy)
- [ ] Network policies K8s
- [ ] Audit logs activés

---

## 🔐 Authentification & Autorisation

### JWT Authentication

**Fichier** : `backend/quiz_core_service/src/auth/jwt.rs`
```rust
use jsonwebtoken::{encode, decode, Header, Validation, EncodingKey, DecodingKey};
use serde::{Deserialize, Serialize};
use chrono::{Utc, Duration};

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,      // User ID
    pub exp: usize,       // Expiration timestamp
    pub iat: usize,       // Issued at
    pub role: String,     // User role
}

pub struct JwtManager {
    secret: String,
    expiration_hours: i64,
}

impl JwtManager {
    pub fn new(secret: String) -> Self {
        Self {
            secret,
            expiration_hours: 24, // 24 heures
        }
    }

    pub fn generate_token(&self, user_id: &str, role: &str) -> Result<String, jsonwebtoken::errors::Error> {
        let now = Utc::now();
        let exp = (now + Duration::hours(self.expiration_hours)).timestamp() as usize;
        let iat = now.timestamp() as usize;

        let claims = Claims {
            sub: user_id.to_string(),
            exp,
            iat,
            role: role.to_string(),
        };

        encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(self.secret.as_bytes()),
        )
    }

    pub fn validate_token(&self, token: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
        decode::<Claims>(
            token,
            &DecodingKey::from_secret(self.secret.as_bytes()),
            &Validation::default(),
        )
        .map(|data| data.claims)
    }
}
```

### Middleware d'Authentification

**Fichier** : `backend/quiz_core_service/src/middleware/auth.rs`
```rust
use axum::{
    extract::{Request, State},
    http::{StatusCode, header},
    middleware::Next,
    response::Response,
};
use std::sync::Arc;

pub async fn auth_middleware(
    State(state): State<Arc<AppState>>,
    mut req: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    // Extraire le token du header Authorization
    let auth_header = req.headers()
        .get(header::AUTHORIZATION)
        .and_then(|h| h.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    // Format: "Bearer <token>"
    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or(StatusCode::UNAUTHORIZED)?;

    // Valider le token
    let claims = state.jwt_manager
        .validate_token(token)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    // Ajouter les claims à la requête pour les handlers
    req.extensions_mut().insert(claims);

    Ok(next.run(req).await)
}
```

### Utilisation dans les Routes
```rust
use axum::{
    routing::{get, post},
    Router, Extension,
};

fn protected_routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/api/v1/quizzes", get(get_quizzes))
        .route("/api/v1/sessions", post(create_session))
        .layer(middleware::from_fn_with_state(state.clone(), auth_middleware))
}

async fn create_session(
    Extension(claims): Extension<Claims>,  // ← JWT claims injectés
    State(state): State<Arc<AppState>>,
    Json(request): Json<CreateSessionRequest>,
) -> Result<Json<Session>, AppError> {
    // Utiliser claims.sub (user ID)
    let user_id = claims.sub;
    
    // ...
}
```

### Role-Based Access Control (RBAC)
```rust
#[derive(Debug, Clone, PartialEq)]
pub enum Role {
    Admin,
    User,
    Guest,
}

pub fn require_role(required_role: Role) -> impl Fn(Extension<Claims>) -> Result<(), StatusCode> {
    move |Extension(claims): Extension<Claims>| {
        let user_role = Role::from_str(&claims.role)?;
        
        if user_role >= required_role {
            Ok(())
        } else {
            Err(StatusCode::FORBIDDEN)
        }
    }
}

// Usage
async fn admin_only_handler(
    Extension(claims): Extension<Claims>,
    _: Result<(), StatusCode> = require_role(Role::Admin)(Extension(claims)),
) -> Result<Json<AdminData>, AppError> {
    // Seulement accessible aux admins
    // ...
}
```

---

## 🔐 Secrets Management

### Kubernetes Secrets
```bash
# Créer un secret
kubectl create secret generic quiz-secrets \
  --from-literal=database-url="postgresql://user:pass@host/db" \
  --from-literal=jwt-secret="super-secret-key" \
  -n quiz-app

# Encoder en base64 manuellement
echo -n "my-secret-value" | base64
```

**Fichier** : `k8s/production/secrets.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: quiz-secrets
  namespace: quiz-app
type: Opaque
data:
  database-url: <base64-encoded>
  jwt-secret: <base64-encoded>
```

### HashiCorp Vault (Production)
```bash
# Installer Vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault \
  --namespace vault \
  --create-namespace

# Initialiser Vault
kubectl exec -n vault vault-0 -- vault operator init

# Unseal Vault (3 keys required)
kubectl exec -n vault vault-0 -- vault operator unseal <key-1>
kubectl exec -n vault vault-0 -- vault operator unseal <key-2>
kubectl exec -n vault vault-0 -- vault operator unseal <key-3>

# Stocker un secret
kubectl exec -n vault vault-0 -- vault kv put secret/quiz-app/database-url value="postgresql://..."
```

### Vault Injector

**Fichier** : `k8s/production/quiz-backend/deployment.yaml` (avec Vault)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quiz-backend
  namespace: quiz-app
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "quiz-app"
        vault.hashicorp.com/agent-inject-secret-database: "secret/quiz-app/database-url"
        vault.hashicorp.com/agent-inject-template-database: |
          {{- with secret "secret/quiz-app/database-url" -}}
          export DATABASE_URL="{{ .Data.data.value }}"
          {{- end }}
    spec:
      serviceAccountName: quiz-backend
      containers:
      - name: quiz-backend
        image: ghcr.io/your-username/quiz-backend:latest
        command: ["/bin/sh", "-c"]
        args:
          - source /vault/secrets/database && /app/quiz_core_service
```

---

## 🌐 Network Security

### Network Policies

**Fichier** : `k8s/production/network-policies.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: quiz-backend-policy
  namespace: quiz-app
spec:
  podSelector:
    matchLabels:
      app: quiz-backend
  policyTypes:
  - Ingress
  - Egress
  
  ingress:
  # Autoriser le trafic depuis l'ingress
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  
  egress:
  # Autoriser connexions vers PostgreSQL
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  
  # Autoriser DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  
  # Autoriser HTTPS externe (pour APIs externes)
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
```

### TLS/HTTPS

**Certificat Let's Encrypt** :
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: quiz-app-ingress
  namespace: quiz-app
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - quiz-app.com
    - www.quiz-app.com
    secretName: quiz-app-tls
  rules:
  - host: quiz-app.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: quiz-backend
            port:
              number: 8080
```

---

## 🐳 Container Security

### Dockerfile Sécurisé

**Fichier** : `docker/backend.Dockerfile`
```dockerfile
# Stage 1: Builder
FROM rust:1.75-slim as builder

WORKDIR /app

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copier les fichiers de dépendances
COPY backend/quiz_core_service/Cargo.toml backend/quiz_core_service/Cargo.lock ./

# Build des dépendances (mise en cache)
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
RUN rm -rf src

# Copier le code source
COPY backend/quiz_core_service/src ./src
COPY backend/quiz_core_service/migrations ./migrations

# Build de l'application
RUN cargo build --release

# Stage 2: Runtime (distroless)
FROM gcr.io/distroless/cc-debian12

WORKDIR /app

# Copier le binaire depuis le builder
COPY --from=builder /app/target/release/quiz_core_service /app/quiz_core_service
COPY --from=builder /app/migrations /app/migrations

# User non-root
USER nonroot:nonroot

# Exposition du port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/app/quiz_core_service", "--health-check"] || exit 1

# Commande de démarrage
CMD ["/app/quiz_core_service"]
```

### Pod Security Standards

**Fichier** : `k8s/production/quiz-backend/deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quiz-backend
  namespace: quiz-app
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 65532  # nonroot user from distroless
        fsGroup: 65532
        seccompProfile:
          type: RuntimeDefault
      
      containers:
      - name: quiz-backend
        image: ghcr.io/your-username/quiz-backend:latest
        
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        
      volumes:
      - name: tmp
        emptyDir: {}
```

### Scan des Images
```yaml
# .github/workflows/backend-ci.yml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ghcr.io/${{ github.repository }}/quiz-backend:${{ github.sha }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'

- name: Upload Trivy results to GitHub Security
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: 'trivy-results.sarif'
```

---

## 🗄️ Database Security

### Connection Security
```rust
// Utiliser TLS pour PostgreSQL
let pool = PgPoolOptions::new()
    .max_connections(5)
    .connect_with(
        PgConnectOptions::from_str(&database_url)?
            .ssl_mode(PgSslMode::Require)  // ← TLS obligatoire
    )
    .await?;
```

### Encryption at Rest
```bash
# PostgreSQL avec encryption (exemple AWS RDS)
aws rds create-db-instance \
  --db-instance-identifier quiz-db-prod \
  --storage-encrypted \
  --kms-key-id arn:aws:kms:region:account:key/key-id
```

### Secrets Rotation

**Script** : `scripts/rotate-db-password.sh`
```bash
#!/bin/bash
set -e

# Générer un nouveau password
NEW_PASSWORD=$(openssl rand -base64 32)

# Updater dans PostgreSQL
kubectl exec -n quiz-app postgres-0 -- psql -U postgres -c \
  "ALTER USER quiz_user WITH PASSWORD '$NEW_PASSWORD';"

# Updater le secret K8s
kubectl create secret generic quiz-secrets \
  --from-literal=database-url="postgresql://quiz_user:$NEW_PASSWORD@postgres:5432/quiz_db" \
  --dry-run=client -o yaml | kubectl apply -f -

# Rollout restart du backend pour recharger
kubectl rollout restart deployment/quiz-backend -n quiz-app

echo "✅ Password rotated successfully"
```

---

## 📊 Compliance & Audit

### Audit Logs
```yaml
# Activer l'audit logging K8s
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
spec:
  containers:
  - command:
    - kube-apiserver
    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
    - --audit-log-path=/var/log/audit.log
    - --audit-log-maxage=30
```

### OWASP Top 10 Mitigations

| Risque | Mitigation |
|--------|------------|
| **Injection** | SQLx (prepared statements), input validation |
| **Broken Authentication** | JWT avec expiration, bcrypt passwords |
| **Sensitive Data Exposure** | TLS partout, encryption at rest |
| **XML External Entities** | N/A (pas de XML) |
| **Broken Access Control** | RBAC, authorization middleware |
| **Security Misconfiguration** | Secure defaults, config reviews |
| **XSS** | Content-Type validation, CSP headers |
| **Insecure Deserialization** | Serde avec validation |
| **Using Components with Known Vulnerabilities** | Dependabot, Trivy scans |
| **Insufficient Logging & Monitoring** | Structured logs, alerting |

### Security Headers
```rust
use axum::http::header;

async fn add_security_headers(
    mut req: Request,
    next: Next,
) -> Response {
    let mut response = next.run(req).await;
    
    let headers = response.headers_mut();
    
    // Strict-Transport-Security
    headers.insert(
        header::STRICT_TRANSPORT_SECURITY,
        "max-age=31536000; includeSubDomains".parse().unwrap(),
    );
    
    // X-Content-Type-Options
    headers.insert(
        header::X_CONTENT_TYPE_OPTIONS,
        "nosniff".parse().unwrap(),
    );
    
    // X-Frame-Options
    headers.insert(
        header::X_FRAME_OPTIONS,
        "DENY".parse().unwrap(),
    );
    
    // Content-Security-Policy
    headers.insert(
        header::CONTENT_SECURITY_POLICY,
        "default-src 'self'".parse().unwrap(),
    );
    
    response
}
```

---

## 📚 Ressources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/security-best-practices/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Rust Security Guidelines](https://anssi-fr.github.io/rust-guide/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)