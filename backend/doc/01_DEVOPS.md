# 🚀 Guide DevOps Complet

Documentation DevOps pour l'application Quiz Géo.

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Environnements](#environnements)
4. [Outils](#outils)
5. [Workflows](#workflows)
6. [Monitoring](#monitoring)
7. [Sécurité](#sécurité)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 Vue d'Ensemble

### Objectifs DevOps

- ✅ **Déploiement continu** : Push → Production en < 10 minutes
- ✅ **Zero-downtime** : Déploiements sans interruption
- ✅ **Scalabilité** : Adapter automatiquement les ressources
- ✅ **Observabilité** : Logs, metrics, traces centralisés
- ✅ **Sécurité** : Secrets chiffrés, images scannées

### Stack Technologique
```
┌─────────────────────────────────────────────────┐
│                    STACK                         │
├─────────────────────────────────────────────────┤
│ Version Control     : Git + GitHub              │
│ CI/CD Backend       : GitHub Actions            │
│ CI/CD Frontend      : Codemagic                 │
│ Container Registry  : GitHub Container Registry │
│ Orchestration       : Kubernetes                │
│ Monitoring          : Prometheus + Grafana      │
│ Logs                : ELK Stack / Loki          │
│ Secrets             : Kubernetes Secrets        │
└─────────────────────────────────────────────────┘
```

---

## 🏗️ Architecture

### Architecture Globale
```
                    ┌─────────────┐
                    │   GitHub    │
                    └──────┬──────┘
                           │
              ┌────────────┴────────────┐
              │                         │
         ┌────▼─────┐            ┌─────▼─────┐
         │ GitHub   │            │ Codemagic │
         │ Actions  │            │           │
         └────┬─────┘            └─────┬─────┘
              │                        │
         Backend CI/CD            Frontend CI/CD
              │                        │
         ┌────▼─────┐            ┌─────▼──────┐
         │  Docker  │            │ TestFlight │
         │ Registry │            │  & APK     │
         └────┬─────┘            └────────────┘
              │
         ┌────▼──────────────────────┐
         │    Kubernetes Cluster     │
         ├───────────────────────────┤
         │                           │
         │  ┌──────────────────┐    │
         │  │   Ingress        │    │
         │  └────────┬─────────┘    │
         │           │               │
         │  ┌────────▼─────────┐    │
         │  │  quiz-backend    │    │
         │  └────────┬─────────┘    │
         │           │               │
         │  ┌────────▼─────────┐    │
         │  │   PostgreSQL     │    │
         │  └──────────────────┘    │
         │                           │
         │  ┌──────────────────┐    │
         │  │   map-service    │    │
         │  └──────────────────┘    │
         │                           │
         └───────────────────────────┘
```

---

## 🌍 Environnements

### Environnements Disponibles

| Environnement | Description | URL | Base de données |
|---------------|-------------|-----|-----------------|
| **Local** | Développement local | `localhost:8080` | PostgreSQL local |
| **Docker Desktop** | K8s local | `quiz-app.local` | PostgreSQL K8s |
| **Staging** | Tests pré-production | `staging.quiz-app.com` | PostgreSQL cloud |
| **Production** | Production | `quiz-app.com` | PostgreSQL cloud (HA) |

### Configuration par Environnement

#### Local (Dev)
```bash
# .env.local
DATABASE_URL=postgresql://quiz_user:quiz@localhost:5432/quiz_db
RUST_LOG=debug
```

#### Docker Desktop (K8s Local)
```yaml
# Via ConfigMap K8s
DATABASE_URL: postgresql://quiz_user:quiz@postgres:5432/quiz_db
RUST_LOG: info
```

#### Production
```yaml
# Via Kubernetes Secrets
DATABASE_URL: 
RUST_LOG: warn
```

---

## 🛠️ Outils

### Prérequis
```bash
# Docker Desktop avec Kubernetes activé
brew install --cask docker

# kubectl
brew install kubectl

# Helm (package manager K8s)
brew install helm

# k9s (UI pour K8s)
brew install k9s

# Rust (backend)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Flutter (frontend)
# Voir https://docs.flutter.dev/get-started/install
```

### Configuration Docker Desktop

1. Ouvrir Docker Desktop
2. Settings → Kubernetes → Enable Kubernetes
3. Allouer ressources :
    - **CPU** : 4 cores minimum
    - **Memory** : 8 GB minimum
    - **Swap** : 2 GB
    - **Disk** : 60 GB

---

## 🔄 Workflows

### Workflow Backend
```
1. Developer push code
   ↓
2. GitHub Actions triggered
   ↓
3. Run tests (cargo test)
   ↓
4. Clippy linter (cargo clippy)
   ↓
5. Build Docker image
   ↓
6. Scan image (Trivy)
   ↓
7. Push to GitHub Registry
   ↓
8. Deploy to K8s (kubectl apply)
   ↓
9. Health check
   ↓
10. Rollback if failed
```

### Workflow Frontend
```
1. Developer push code
   ↓
2. Codemagic triggered
   ↓
3. Run Flutter tests
   ↓
4. Build Android APK
   ↓
5. Build iOS IPA (on macOS cloud)
   ↓
6. Deploy to TestFlight
   ↓
7. Notify Slack/Email
```

---

## 📊 Monitoring

### Metrics Collectées

- **Backend** :
    - Request rate
    - Response time (p50, p95, p99)
    - Error rate
    - CPU/Memory usage

- **Base de données** :
    - Connections actives
    - Query time
    - Deadlocks

- **Kubernetes** :
    - Pod status
    - Resource usage
    - Restart count

### Dashboards Grafana

- **Overview** : Vue d'ensemble système
- **Backend API** : Métriques HTTP
- **Database** : Performance PostgreSQL
- **Kubernetes** : Santé du cluster

---

## 🔒 Sécurité

### Secrets Management
```bash
# Créer un secret K8s
kubectl create secret generic quiz-secrets \
  --from-literal=database-url=$DATABASE_URL \
  --from-literal=jwt-secret=$JWT_SECRET

# Utiliser dans un pod
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: quiz-secrets
        key: database-url
```

### Scan de Sécurité

- **Trivy** : Scan des images Docker
- **Dependabot** : Mises à jour de sécurité
- **Snyk** : Scan des dépendances

---

## 🐛 Troubleshooting

### Problèmes Courants

#### 1. Pod ne démarre pas
```bash
# Voir les logs
kubectl logs -f 

# Décrire le pod
kubectl describe pod 

# Vérifier les events
kubectl get events --sort-by='.lastTimestamp'
```

#### 2. Service inaccessible
```bash
# Vérifier le service
kubectl get svc

# Tester depuis un pod
kubectl run curl --image=curlimages/curl -i --tty -- sh
curl http://quiz-backend:8080/health
```

#### 3. Base de données inaccessible
```bash
# Se connecter au pod PostgreSQL
kubectl exec -it postgres-0 -- psql -U quiz_user -d quiz_db

# Vérifier les connexions
SELECT count(*) FROM pg_stat_activity;
```

---

## 📚 Ressources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Codemagic Documentation](https://docs.codemagic.io/)
- [Prometheus Documentation](https://prometheus.io/docs/)