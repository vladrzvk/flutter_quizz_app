# ☸️ Kubernetes - Guide Complet

Configuration et déploiement Kubernetes pour Quiz Géo App.

## 📋 Table des Matières

1. [Architecture](#architecture)
2. [Setup Local (Docker Desktop)](#setup-local-docker-desktop)
3. [Déploiement Backend](#déploiement-backend)
4. [Déploiement PostgreSQL](#déploiement-postgresql)
5. [Ingress & DNS](#ingress--dns)
6. [Monitoring](#monitoring)
7. [Production](#production)
8. [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture

### Architecture Kubernetes
```
┌──────────────────────────────────────────────┐
│          Kubernetes Cluster                  │
├──────────────────────────────────────────────┤
│                                              │
│  ┌────────────────────────────────────┐    │
│  │  Namespace: quiz-app               │    │
│  ├────────────────────────────────────┤    │
│  │                                    │    │
│  │  📡 Ingress (NGINX)                │    │
│  │    ├─ quiz-app.local → backend    │    │
│  │    └─ map.local → map-service     │    │
│  │                                    │    │
│  │  🎯 Services                       │    │
│  │    ├─ quiz-backend (ClusterIP)    │    │
│  │    ├─ postgres (ClusterIP)        │    │
│  │    ├─ redis (ClusterIP)           │    │
│  │    └─ map-service (ClusterIP)     │    │
│  │                                    │    │
│  │  🚀 Deployments                    │    │
│  │    ├─ quiz-backend (3 replicas)   │    │
│  │    └─ map-service (2 replicas)    │    │
│  │                                    │    │
│  │  💾 StatefulSets                   │    │
│  │    ├─ postgres (1 replica)        │    │
│  │    └─ redis (1 replica)           │    │
│  │                                    │    │
│  │  📦 PersistentVolumes              │    │
│  │    ├─ postgres-pv (10Gi)          │    │
│  │    └─ redis-pv (1Gi)              │    │
│  │                                    │    │
│  │  ⚙️  ConfigMaps & Secrets          │    │
│  │    ├─ quiz-config                 │    │
│  │    └─ quiz-secrets                │    │
│  │                                    │    │
│  └────────────────────────────────────┘    │
│                                              │
│  ┌────────────────────────────────────┐    │
│  │  Namespace: monitoring             │    │
│  ├────────────────────────────────────┤    │
│  │  📊 Prometheus                     │    │
│  │  📈 Grafana                        │    │
│  │  📝 Loki                           │    │
│  └────────────────────────────────────┘    │
│                                              │
└──────────────────────────────────────────────┘
```

---

## 🖥️ Setup Local (Docker Desktop)

### 1. Activer Kubernetes
```bash
# Ouvrir Docker Desktop
# Settings → Kubernetes → Enable Kubernetes
# Apply & Restart

# Vérifier que K8s fonctionne
kubectl cluster-info
kubectl get nodes
```

### 2. Créer le Namespace

**Fichier** : `k8s/local/namespace.yaml`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: quiz-app
  labels:
    name: quiz-app
    environment: local
```
```bash
kubectl apply -f k8s/local/00_namespace.yaml
```

### 3. Script de Setup Automatique

**Fichier** : `scripts/setup-k8s-local.sh`
```bash
#!/bin/bash
set -e

echo "🚀 Setup Kubernetes local (Docker Desktop)"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Vérifier que Docker Desktop K8s est actif
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Kubernetes n'est pas actif dans Docker Desktop${NC}"
    echo "Activez-le dans : Docker Desktop → Settings → Kubernetes"
    exit 1
fi

echo -e "${GREEN}✅ Kubernetes actif${NC}"

# Créer le namespace
echo -e "${BLUE}📦 Création du namespace quiz-app${NC}"
kubectl apply -f k8s/local/00_namespace.yaml

# Installer NGINX Ingress Controller
echo -e "${BLUE}🔧 Installation NGINX Ingress Controller${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Attendre que l'ingress soit prêt
echo -e "${BLUE}⏳ Attente du démarrage de l'Ingress Controller...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# Déployer PostgreSQL
echo -e "${BLUE}🐘 Déploiement PostgreSQL${NC}"
kubectl apply -f k8s/local/postgres/

# Attendre que PostgreSQL soit prêt
echo -e "${BLUE}⏳ Attente du démarrage de PostgreSQL...${NC}"
kubectl wait --namespace quiz-app \
  --for=condition=ready pod \
  --selector=app=postgres \
  --timeout=120s

# Exécuter les migrations
echo -e "${BLUE}🔄 Exécution des migrations${NC}"
kubectl exec -n quiz-app postgres-0 -- psql -U quiz_user -d quiz_db -c "SELECT 1"

# Déployer le backend
echo -e "${BLUE}🦀 Déploiement Backend${NC}"
kubectl apply -f k8s/local/quiz-backend/

# Attendre que le backend soit prêt
echo -e "${BLUE}⏳ Attente du démarrage du Backend...${NC}"
kubectl wait --namespace quiz-app \
  --for=condition=ready pod \
  --selector=app=quiz-backend \
  --timeout=120s

# Déployer l'Ingress
echo -e "${BLUE}🌐 Configuration Ingress${NC}"
kubectl apply -f k8s/local/ingress.yaml

# Ajouter au /etc/hosts
echo -e "${BLUE}🔧 Configuration /etc/hosts${NC}"
if ! grep -q "quiz-app.local" /etc/hosts; then
    echo "127.0.0.1 quiz-app.local" | sudo tee -a /etc/hosts
    echo -e "${GREEN}✅ Ajout de quiz-app.local dans /etc/hosts${NC}"
fi

# Afficher le statut
echo -e "${GREEN}"
echo "================================"
echo "✅ Setup terminé !"
echo "================================"
echo -e "${NC}"
echo ""
echo "🎯 Application accessible sur :"
echo "   http://quiz-app.local"
echo ""
echo "📊 Voir les pods :"
echo "   kubectl get pods -n quiz-app"
echo ""
echo "📝 Voir les logs :"
echo "   kubectl logs -f -n quiz-app -l app=quiz-backend"
echo ""
echo "🔍 Interface K9s :"
echo "   k9s -n quiz-app"
```
```bash
chmod +x scripts/setup-k8s-local.sh
./scripts/setup-k8s-local.sh
```

---

## 🦀 Déploiement Backend

### ConfigMap

**Fichier** : `k8s/local/quiz-backend/configmap.yaml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: quiz-config
  namespace: quiz-app
data:
  RUST_LOG: "info"
  ENVIRONMENT: "local"
  # DATABASE_URL sera dans le Secret
```

### Secret

**Fichier** : `k8s/local/quiz-backend/secret.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: quiz-secrets
  namespace: quiz-app
type: Opaque
stringData:
  DATABASE_URL: "postgresql://quiz_user:quiz@postgres:5432/quiz_db"
  JWT_SECRET: "your-super-secret-jwt-key-change-in-production"
```

### Deployment

**Fichier** : `k8s/local/quiz-backend/deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quiz-backend
  namespace: quiz-app
  labels:
    app: quiz-backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: quiz-backend
  template:
    metadata:
      labels:
        app: quiz-backend
    spec:
      containers:
      - name: quiz-backend
        image: ghcr.io/your-username/quiz-backend:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: quiz-secrets
              key: DATABASE_URL
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: quiz-secrets
              key: JWT_SECRET
        - name: RUST_LOG
          valueFrom:
            configMapKeyRef:
              name: quiz-config
              key: RUST_LOG
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
```

### Service

**Fichier** : `k8s/local/quiz-backend/service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: quiz-backend
  namespace: quiz-app
  labels:
    app: quiz-backend
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: quiz-backend
```

---

## 🐘 Déploiement PostgreSQL

### PersistentVolumeClaim

**Fichier** : `k8s/local/postgres/pvc.yaml`
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: quiz-app
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: hostpath
```

### StatefulSet

**Fichier** : `k8s/local/postgres/statefulset.yaml`
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: quiz-app
spec:
  serviceName: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_USER
          value: "quiz_user"
        - name: POSTGRES_PASSWORD
          value: "quiz"
        - name: POSTGRES_DB
          value: "quiz_db"
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - quiz_user
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - quiz_user
          initialDelaySeconds: 5
          periodSeconds: 5
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: hostpath
      resources:
        requests:
          storage: 10Gi
```

### Service

**Fichier** : `k8s/local/postgres/service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: quiz-app
spec:
  type: ClusterIP
  ports:
  - port: 5432
    targetPort: 5432
    protocol: TCP
    name: postgres
  selector:
    app: postgres
```

---

## 🌐 Ingress & DNS

### Ingress

**Fichier** : `k8s/local/ingress.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: quiz-app-ingress
  namespace: quiz-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: quiz-app.local
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

### Configuration /etc/hosts
```bash
# Ajouter manuellement
sudo nano /etc/hosts

# Ajouter cette ligne
127.0.0.1 quiz-app.local map.local
```

---

## 📊 Monitoring

### Prometheus
```bash
# Ajouter le repo Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Installer Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

### Grafana
```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Accéder : http://localhost:3000
# Login : admin / prom-operator
```

---

## 🚀 Production

### Différences Local vs Production

| Aspect | Local | Production |
|--------|-------|------------|
| **Replicas** | 1-2 | 3-5 |
| **Resources** | Low | High |
| **Storage** | hostpath | Cloud volumes |
| **Secrets** | Base64 | Vault/KMS |
| **Ingress** | HTTP | HTTPS (Let's Encrypt) |
| **DB** | Single instance | HA (replicas) |

### Production ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: quiz-config
  namespace: quiz-app
data:
  RUST_LOG: "warn"
  ENVIRONMENT: "production"
  MAX_CONNECTIONS: "100"
```

---

## 🐛 Troubleshooting

### Commandes Utiles
```bash
# Voir tous les pods
kubectl get pods -n quiz-app

# Logs d'un pod
kubectl logs -f -n quiz-app 

# Logs de tous les pods d'un deployment
kubectl logs -f -n quiz-app -l app=quiz-backend

# Décrire un pod
kubectl describe pod -n quiz-app 

# Shell dans un pod
kubectl exec -it -n quiz-app  -- /bin/sh

# Voir les events
kubectl get events -n quiz-app --sort-by='.lastTimestamp'

# Redémarrer un deployment
kubectl rollout restart deployment/quiz-backend -n quiz-app

# Voir l'historique des rollouts
kubectl rollout history deployment/quiz-backend -n quiz-app

# Rollback
kubectl rollout undo deployment/quiz-backend -n quiz-app
```

### Problèmes Courants

#### Pod en CrashLoopBackOff
```bash
# Voir les logs
kubectl logs -n quiz-app 

# Souvent : problème de connexion DB ou variable d'env manquante
kubectl describe pod -n quiz-app 
```

#### Service inaccessible
```bash
# Vérifier le service
kubectl get svc -n quiz-app

# Vérifier les endpoints
kubectl get endpoints -n quiz-app

# Test depuis un pod
kubectl run curl --image=curlimages/curl -i --tty --rm -- sh
curl http://quiz-backend.quiz-app.svc.cluster.local:8080/health
```

#### PostgreSQL ne démarre pas
```bash
# Vérifier les PVCs
kubectl get pvc -n quiz-app

# Vérifier les logs
kubectl logs -n quiz-app postgres-0

# Se connecter à la DB
kubectl exec -it -n quiz-app postgres-0 -- psql -U quiz_user -d quiz_db
```

---

## 📚 Ressources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Desktop Kubernetes](https://docs.docker.com/desktop/kubernetes/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [StatefulSets Guide](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)