PLAN MISE À JOUR KUBERNETES KIND - Architecture Multi-Services Sécurisée
🎯 Objectif
Étendre la configuration Kubernetes kind existante pour supporter l'architecture microservices complète (6 services + 5 databases) tout en maintenant le même niveau de sécurité.

📊 ÉTAT ACTUEL vs ÉTAT CIBLE
✅ Configuration Actuelle (V0)
kind cluster (3 nodes)
├── quiz-app namespace
│   ├── PostgreSQL (1 StatefulSet)
│   └── quiz-backend (1 Deployment)
└── Ingress NGINX
Sécurité appliquée :

Pod Security Standards (restricted)
RBAC complet
Network Policies (3 policies)
Security Contexts stricts
Resource Quotas + LimitRanges
PodDisruptionBudget
Secrets management

🎯 Configuration Cible (V1)
kind cluster (3 nodes)
├── quiz-app namespace
│   ├── PostgreSQL Cluster (5 StatefulSets)
│   │   ├── postgres-auth (5432)
│   │   ├── postgres-subscription (5433)
│   │   ├── postgres-offline (5434)
│   │   ├── postgres-ads (5435)
│   │   └── postgres-quiz (5436)
│   │
│   ├── Backend Services (6 Deployments)
│   │   ├── auth-service (3001)
│   │   ├── subscription-service (3002)
│   │   ├── offline-service (3003)
│   │   ├── ads-service (3004)
│   │   ├── quiz-core-service (8080)
│   │   └── api-gateway (8000)
│   │
│   └── Services + Ingress
└── Ingress NGINX

🗺️ STRUCTURE FICHIERS MISE À JOUR
Arborescence Complète
k8s/kind/
├── kind-config.yaml                    🔄 À MODIFIER (port mappings)
├── setup-kind.ps1                      🔄 À MODIFIER
├── DEPLOYMENT-GUIDE.md                 🔄 À METTRE À JOUR
├── SECURITY-LEVERS.md                  ✅ OK (inchangé)
│
├── manifests/
│   ├── 00-namespace.yaml               ✅ OK (inchangé)
│   ├── 01-rbac.yaml                    🔄 ÉTENDRE (6 ServiceAccounts + Roles)
│   ├── 02-configmap.yaml               🔄 ÉTENDRE (configs tous services)
│   ├── 03-secret.yaml                  🔄 ÉTENDRE (secrets tous services)
│   ├── 04-resource-limits.yaml         🔄 AJUSTER (quotas augmentés)
│   ├── 05-network-policies.yaml        🔄 RÉECRIRE (13 nouvelles policies)
│   │
│   ├── databases/                      🆕 NOUVEAU DOSSIER
│   │   ├── 10-postgres-auth.yaml
│   │   ├── 11-postgres-subscription.yaml
│   │   ├── 12-postgres-offline.yaml
│   │   ├── 13-postgres-ads.yaml
│   │   └── 14-postgres-quiz.yaml
│   │
│   ├── services/                       🆕 NOUVEAU DOSSIER
│   │   ├── 20-auth-service.yaml
│   │   ├── 21-subscription-service.yaml
│   │   ├── 22-offline-service.yaml
│   │   ├── 23-ads-service.yaml
│   │   ├── 24-quiz-core-service.yaml
│   │   └── 25-api-gateway.yaml
│   │
│   └── 30-ingress.yaml                 🔄 MODIFIER (routes tous services)
│
└── optional/
└── gatekeeper-policies.yaml        🔄 ÉTENDRE (policies services)
Total fichiers :

À créer : 13 nouveaux
À modifier : 9 existants
Inchangés : 1


📅 PLAN DE MISE À JOUR - 4 ÉTAPES
ÉTAPE 1 : Infrastructure & Configuration de Base
1.1 Kind Cluster Configuration
Fichier : kind-config.yaml
À MODIFIER :

Port mappings pour tous les services

3001 → auth-service
3002 → subscription-service
3003 → offline-service
3004 → ads-service
8080 → quiz-core-service (existant)
8000 → api-gateway



Avant :
yamlextraPortMappings:
- containerPort: 80    # Ingress HTTP
- containerPort: 443   # Ingress HTTPS
  Après :
  yamlextraPortMappings:
- containerPort: 80
- containerPort: 443
- containerPort: 3001  # Auth
- containerPort: 3002  # Subscription
- containerPort: 3003  # Offline
- containerPort: 3004  # Ads
- containerPort: 8000  # API Gateway
- containerPort: 8080  # Quiz Core (debug direct)
  1.2 Setup Script
  Fichier : setup-kind.ps1
  À AJOUTER :

Vérifications images Docker pour 6 services
Load de 6 images dans kind au lieu d'une
Ajustements mémoire/CPU recommandés (min 8GB RAM)

1.3 RBAC Extension
Fichier : manifests/01-rbac.yaml
À AJOUTER :
yaml# 6 ServiceAccounts (1 par service)
---
apiVersion: v1
kind: ServiceAccount
metadata:
name: auth-service-sa
namespace: quiz-app

---
apiVersion: v1
kind: ServiceAccount
metadata:
name: subscription-service-sa
namespace: quiz-app

# ... (4 autres)

# 6 Roles (permissions spécifiques)
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
name: auth-service-role
namespace: quiz-app
rules:
- apiGroups: [""]
  resources: ["secrets", "configmaps"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

# ... (5 autres Roles)

# 6 RoleBindings
# ...
Total : 18 ressources (6 SA + 6 Roles + 6 RoleBindings)
1.4 ConfigMaps Extension
Fichier : manifests/02-configmap.yaml
À AJOUTER :
yamlapiVersion: v1
kind: ConfigMap
metadata:
name: services-config
namespace: quiz-app
data:
# URLs inter-services (ClusterIP)
AUTH_SERVICE_URL: "http://auth-service:3001"
SUBSCRIPTION_SERVICE_URL: "http://subscription-service:3002"
OFFLINE_SERVICE_URL: "http://offline-service:3003"
ADS_SERVICE_URL: "http://ads-service:3004"
QUIZ_CORE_SERVICE_URL: "http://quiz-core-service:8080"

# Database URLs
AUTH_DB_HOST: "postgres-auth"
AUTH_DB_PORT: "5432"
SUBSCRIPTION_DB_HOST: "postgres-subscription"
SUBSCRIPTION_DB_PORT: "5432"
# ... (3 autres DBs)

# Logging
LOG_LEVEL: "info"
LOG_FORMAT: "json"
1.5 Secrets Extension
Fichier : manifests/03-secret.yaml
À AJOUTER :
yamlapiVersion: v1
kind: Secret
metadata:
name: auth-db-secret
namespace: quiz-app
type: Opaque
data:
username: <base64>
password: <base64>
database: <base64>

---
# 4 autres secrets DB (subscription, offline, ads, quiz)

---
apiVersion: v1
kind: Secret
metadata:
name: jwt-secret
namespace: quiz-app
type: Opaque
data:
jwt-secret: <base64>
jwt-refresh-secret: <base64>

---
# Secrets Apple/Google IAP
apiVersion: v1
kind: Secret
metadata:
name: iap-secrets
namespace: quiz-app
type: Opaque
data:
apple-shared-secret: <base64>
google-service-account: <base64>
Total : 7 Secrets
1.6 Resource Quotas Ajustement
Fichier : manifests/04-resource-limits.yaml
À MODIFIER :
Avant (1 service + 1 DB) :
yamlspec:
hard:
requests.cpu: "2"
requests.memory: "4Gi"
limits.cpu: "4"
limits.memory: "8Gi"
pods: "10"
Après (6 services + 5 DBs) :
yamlspec:
hard:
requests.cpu: "8"      # ↑ x4
requests.memory: "16Gi" # ↑ x4
limits.cpu: "16"       # ↑ x4
limits.memory: "32Gi"  # ↑ x4
pods: "30"             # ↑ x3
LimitRange : Inchangé (limites par conteneur OK)

ÉTAPE 2 : Databases PostgreSQL (5 instances)
2.1 Structure Commune
Chaque database aura :

1 Service (Headless)
1 StatefulSet (1 replica en kind, 3 en prod)
Security contexts identiques
Resource limits adaptés

2.2 Fichiers Databases
Dossier : manifests/databases/
À CRÉER (5 fichiers similaires) :
10-postgres-auth.yaml
yaml# Service
---
apiVersion: v1
kind: Service
metadata:
name: postgres-auth
namespace: quiz-app
spec:
clusterIP: None  # Headless
selector:
app: postgres-auth
ports:
- port: 5432

# StatefulSet
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
name: postgres-auth
namespace: quiz-app
spec:
serviceName: postgres-auth
replicas: 1
selector:
matchLabels:
app: postgres-auth
template:
metadata:
labels:
app: postgres-auth
spec:
serviceAccountName: postgres-sa
securityContext:
runAsNonRoot: true
runAsUser: 999
fsGroup: 999
seccompProfile:
type: RuntimeDefault
containers:
- name: postgres
image: postgres:16-alpine
imagePullPolicy: IfNotPresent
env:
- name: POSTGRES_DB
valueFrom:
secretKeyRef:
name: auth-db-secret
key: database
- name: POSTGRES_USER
valueFrom:
secretKeyRef:
name: auth-db-secret
key: username
- name: POSTGRES_PASSWORD
valueFrom:
secretKeyRef:
name: auth-db-secret
key: password
- name: PGDATA
value: /var/lib/postgresql/data/pgdata
ports:
- containerPort: 5432
volumeMounts:
- name: postgres-storage
mountPath: /var/lib/postgresql/data
resources:
requests:
cpu: 250m
memory: 512Mi
limits:
cpu: 500m
memory: 1Gi
livenessProbe:
exec:
command: ["pg_isready", "-U", "postgres"]
initialDelaySeconds: 30
periodSeconds: 10
readinessProbe:
exec:
command: ["pg_isready", "-U", "postgres"]
initialDelaySeconds: 5
periodSeconds: 5
securityContext:
allowPrivilegeEscalation: false
capabilities:
drop: [ALL]
volumeClaimTemplates:
- metadata:
name: postgres-storage
spec:
accessModes: ["ReadWriteOnce"]
resources:
requests:
storage: 5Gi
Répéter pour :

11-postgres-subscription.yaml (même structure, noms différents)
12-postgres-offline.yaml
13-postgres-ads.yaml
14-postgres-quiz.yaml (remplace 07-postgres-statefulset.yaml)

Variables à changer :
FichierService NameStatefulSet NameSecret Name10postgres-authpostgres-authauth-db-secret11postgres-subscriptionpostgres-subscriptionsubscription-db-secret12postgres-offlinepostgres-offlineoffline-db-secret13postgres-adspostgres-adsads-db-secret14postgres-quizpostgres-quizquiz-db-secret

ÉTAPE 3 : Backend Services (6 deployments)
3.1 Template Commun Services
Chaque service aura :

1 Service (ClusterIP)
1 Deployment (2 replicas)
1 PodDisruptionBudget
Security contexts identiques
Init container pour wait-for DB

3.2 Fichiers Services
Dossier : manifests/services/
À CRÉER (6 fichiers) :
20-auth-service.yaml
yaml# Service
---
apiVersion: v1
kind: Service
metadata:
name: auth-service
namespace: quiz-app
spec:
type: ClusterIP
selector:
app: auth-service
ports:
- port: 3001
targetPort: 3001
name: http

# Deployment
---
apiVersion: apps/v1
kind: Deployment
metadata:
name: auth-service
namespace: quiz-app
spec:
replicas: 2
selector:
matchLabels:
app: auth-service
strategy:
type: RollingUpdate
rollingUpdate:
maxSurge: 1
maxUnavailable: 0
template:
metadata:
labels:
app: auth-service
annotations:
prometheus.io/scrape: "true"
prometheus.io/port: "3001"
spec:
serviceAccountName: auth-service-sa
securityContext:
runAsNonRoot: true
runAsUser: 65532
runAsGroup: 65532
fsGroup: 65532
seccompProfile:
type: RuntimeDefault

      # Init container - wait for DB
      initContainers:
        - name: wait-for-postgres
          image: busybox:1.36
          command:
            - sh
            - -c
            - |
              until nc -zv postgres-auth 5432; do
                echo "Waiting for postgres-auth..."
                sleep 2
              done
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: [ALL]
            runAsNonRoot: true
            runAsUser: 65532
      
      containers:
        - name: auth-service
          image: auth-service:local  # À build et load dans kind
          imagePullPolicy: Never
          ports:
            - containerPort: 3001
          env:
            - name: PORT
              value: "3001"
            - name: DATABASE_URL
              value: "postgres://$(DB_USER):$(DB_PASSWORD)@postgres-auth:5432/$(DB_NAME)"
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: auth-db-secret
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: auth-db-secret
                  key: password
            - name: DB_NAME
              valueFrom:
                secretKeyRef:
                  name: auth-db-secret
                  key: database
            - name: JWT_SECRET
              valueFrom:
                secretKeyRef:
                  name: jwt-secret
                  key: jwt-secret
            - name: JWT_REFRESH_SECRET
              valueFrom:
                secretKeyRef:
                  name: jwt-secret
                  key: jwt-refresh-secret
          resources:
            requests:
              cpu: 200m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /health
              port: 3001
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 3001
            initialDelaySeconds: 5
            periodSeconds: 5
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: [ALL]
          volumeMounts:
            - name: tmp
              mountPath: /tmp
      
      volumes:
        - name: tmp
          emptyDir: {}

# PodDisruptionBudget
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
name: auth-service-pdb
namespace: quiz-app
spec:
minAvailable: 1
selector:
matchLabels:
app: auth-service
Répéter pour (avec variations) :

21-subscription-service.yaml (port 3002, DB subscription)
22-offline-service.yaml (port 3003, DB offline)
23-ads-service.yaml (port 3004, DB ads)
24-quiz-core-service.yaml (port 8080, DB quiz) - remplace 09-backend-deployment.yaml
25-api-gateway.yaml (port 8000, pas de DB)

3.3 API Gateway Spécificités
Fichier : 25-api-gateway.yaml
Différences :

Pas d'init container (pas de DB)
Env vars : URLs de tous les services
Resources plus élevées (proxy)
Expose port 8000

yamlenv:
- name: AUTH_SERVICE_URL
  valueFrom:
  configMapKeyRef:
  name: services-config
  key: AUTH_SERVICE_URL
- name: SUBSCRIPTION_SERVICE_URL
  valueFrom:
  configMapKeyRef:
  name: services-config
  key: SUBSCRIPTION_SERVICE_URL
# ... autres services
resources:
requests:
cpu: 300m
memory: 512Mi
limits:
cpu: 1000m
memory: 1Gi

ÉTAPE 4 : Network Policies (Communication Inter-Services)
4.1 Stratégie Réseau
Fichier : manifests/05-network-policies.yaml (RÉÉCRIRE COMPLÈTEMENT)
Principes :

Default deny-all (existant, conserver)
DNS autorisé pour tous (existant, conserver)
Policies granulaires par service

À CRÉER (13 Network Policies) :
Policy 1 : Default Deny (Existante - OK)
yamlapiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: default-deny-all
namespace: quiz-app
spec:
podSelector: {}
policyTypes:
- Ingress
- Egress
Policy 2 : Allow DNS (Existante - OK)
yamlapiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: allow-dns
namespace: quiz-app
spec:
podSelector: {}
policyTypes:
- Egress
egress:
- to:
- namespaceSelector:
matchLabels:
kubernetes.io/metadata.name: kube-system
ports:
- protocol: UDP
port: 53
Policy 3 : Auth Service → Auth DB
yamlapiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: auth-service-to-auth-db
namespace: quiz-app
spec:
podSelector:
matchLabels:
app: auth-service
policyTypes:
- Egress
egress:
- to:
- podSelector:
matchLabels:
app: postgres-auth
ports:
- protocol: TCP
port: 5432
Policy 4 : Auth DB ← Auth Service
yamlapiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: auth-db-from-auth-service
namespace: quiz-app
spec:
podSelector:
matchLabels:
app: postgres-auth
policyTypes:
- Ingress
ingress:
- from:
- podSelector:
matchLabels:
app: auth-service
ports:
- protocol: TCP
port: 5432
Répéter pattern pour :

Subscription Service ↔ Subscription DB (policies 5-6)
Offline Service ↔ Offline DB (policies 7-8)
Ads Service ↔ Ads DB (policies 9-10)
Quiz Core Service ↔ Quiz DB (policies 11-12)

Policy 13 : API Gateway → All Services
yamlapiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: api-gateway-to-services
namespace: quiz-app
spec:
podSelector:
matchLabels:
app: api-gateway
policyTypes:
- Egress
egress:
- to:
- podSelector:
matchLabels:
app: auth-service
ports:
- protocol: TCP
port: 3001
- to:
- podSelector:
matchLabels:
app: subscription-service
ports:
- protocol: TCP
port: 3002
- to:
- podSelector:
matchLabels:
app: offline-service
ports:
- protocol: TCP
port: 3003
- to:
- podSelector:
matchLabels:
app: ads-service
ports:
- protocol: TCP
port: 3004
- to:
- podSelector:
matchLabels:
app: quiz-core-service
ports:
- protocol: TCP
port: 8080
Policy 14 : Services ← API Gateway
yamlapiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: services-from-api-gateway
namespace: quiz-app
spec:
podSelector:
matchLabels:
tier: backend  # Label commun tous services
policyTypes:
- Ingress
ingress:
- from:
- podSelector:
matchLabels:
app: api-gateway
Policy 15 : Ingress → API Gateway
yamlapiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: ingress-to-api-gateway
namespace: quiz-app
spec:
podSelector:
matchLabels:
app: api-gateway
policyTypes:
- Ingress
ingress:
- from:
- namespaceSelector:
matchLabels:
kubernetes.io/metadata.name: ingress-nginx
ports:
- protocol: TCP
port: 8000
Policy 16 : Quiz Core ↔ Auth Service (pour validation JWT)
yamlapiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
name: quiz-core-to-auth
namespace: quiz-app
spec:
podSelector:
matchLabels:
app: quiz-core-service
policyTypes:
- Egress
egress:
- to:
- podSelector:
matchLabels:
app: auth-service
ports:
- protocol: TCP
port: 3001
Policy 17 : Quiz Core ↔ Subscription Service
yaml# Similar pattern pour communication Quiz Core vers autres services
Total : 17 Network Policies

ÉTAPE 5 : Ingress Configuration
5.1 Mise à Jour Ingress
Fichier : manifests/30-ingress.yaml
À MODIFIER :
Avant (1 backend) :
yamlspec:
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
Après (routing via API Gateway) :
yamlapiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
name: quiz-app-ingress
namespace: quiz-app
annotations:
nginx.ingress.kubernetes.io/rewrite-target: /
nginx.ingress.kubernetes.io/ssl-redirect: "false"

    # Security headers (existants - conserver)
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
      more_set_headers "Referrer-Policy: no-referrer-when-downgrade";
    
    # Rate limiting (existant - conserver)
    nginx.ingress.kubernetes.io/limit-rps: "100"
    nginx.ingress.kubernetes.io/limit-connections: "50"
    
    # CORS (nouveau - si nécessaire)
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"

spec:
ingressClassName: nginx
rules:
- host: quiz-app.local
http:
paths:
# Toutes les requêtes passent par API Gateway
- path: /
pathType: Prefix
backend:
service:
name: api-gateway
port:
number: 8000
Optionnel : Ingress séparés par service (debug)
yaml# Accès direct aux services (dev/debug uniquement)
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
name: direct-services-ingress
namespace: quiz-app
annotations:
nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
ingressClassName: nginx
rules:
- host: quiz-app.local
http:
paths:
- path: /auth(/|$)(.*)
pathType: Prefix
backend:
service:
name: auth-service
port:
number: 3001
- path: /subscription(/|$)(.*)
pathType: Prefix
backend:
service:
name: subscription-service
port:
number: 3002
# ... autres services

📊 RÉSUMÉ DES MODIFICATIONS
Fichiers par Type
TypeÀ CréerÀ ModifierTotalConfiguration022RBAC011ConfigMaps/Secrets022Resource Limits011Network Policies15217Databases505Services Backend606Ingress011Documentation011Total261036
Leviers Sécurité Maintenus
Tous les 15 leviers existants sont maintenus :

✅ RBAC (étendu à 6 services)
✅ Pod Security Standards (inchangé)
✅ Security Contexts (appliqués partout)
✅ Network Policies (étendues)
✅ Resource Quotas (augmentés)
✅ Secrets Management (étendus)
✅ Image Security (maintenu)
✅ PodDisruptionBudget (6 PDBs)
✅ Ingress Security (maintenu)
✅ Monitoring Hooks (étendus)


🚀 ORDRE DE DÉPLOIEMENT
Phase 1 : Infrastructure
bashkubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/01-rbac.yaml
kubectl apply -f manifests/02-configmap.yaml
kubectl apply -f manifests/03-secret.yaml
kubectl apply -f manifests/04-resource-limits.yaml
kubectl apply -f manifests/05-network-policies.yaml
Phase 2 : Databases (ordre important)
bashkubectl apply -f manifests/databases/10-postgres-auth.yaml
kubectl wait --for=condition=ready pod -l app=postgres-auth -n quiz-app --timeout=120s

kubectl apply -f manifests/databases/11-postgres-subscription.yaml
kubectl wait --for=condition=ready pod -l app=postgres-subscription -n quiz-app --timeout=120s

kubectl apply -f manifests/databases/12-postgres-offline.yaml
kubectl apply -f manifests/databases/13-postgres-ads.yaml
kubectl apply -f manifests/databases/14-postgres-quiz.yaml

# Attendre toutes les DBs
kubectl wait --for=condition=ready pod -l tier=database -n quiz-app --timeout=300s
Phase 3 : Backend Services (ordre important)
bash# 1. Auth d'abord (autres dépendent de lui)
kubectl apply -f manifests/services/20-auth-service.yaml
kubectl wait --for=condition=available deployment/auth-service -n quiz-app --timeout=120s

# 2. Services indépendants
kubectl apply -f manifests/services/21-subscription-service.yaml
kubectl apply -f manifests/services/22-offline-service.yaml
kubectl apply -f manifests/services/23-ads-service.yaml

# 3. Quiz Core (dépend de Subscription)
kubectl apply -f manifests/services/24-quiz-core-service.yaml

# 4. API Gateway (dépend de tous)
kubectl apply -f manifests/services/25-api-gateway.yaml

# Attendre tous
kubectl wait --for=condition=available deployment -l tier=backend -n quiz-app --timeout=300s
Phase 4 : Exposition
bashkubectl apply -f manifests/30-ingress.yaml

🔍 VALIDATION POST-DÉPLOIEMENT
Vérifications Essentielles
bash# 1. Tous les pods running
kubectl get pods -n quiz-app

# Attendu : 5 postgres + 12 backend (6 services x 2 replicas)
# Total : 17 pods

# 2. Services créés
kubectl get svc -n quiz-app
# Attendu : 11 services (5 postgres + 6 backend)

# 3. Network Policies appliquées
kubectl get networkpolicies -n quiz-app
# Attendu : 17 policies

# 4. Resource Quotas
kubectl describe resourcequota quiz-app-quota -n quiz-app

# 5. Tests connectivité
# Auth Service
curl http://quiz-app.local/auth/health

# Subscription Service
curl http://quiz-app.local/subscription/health

# API Gateway
curl http://quiz-app.local/health

📝 CHECKLIST COMPLÈTE
Avant Déploiement

Docker Desktop avec 8GB+ RAM
kind installé
kubectl installé
6 images Docker buildées
Secrets générés (passwords, JWT)

Configuration

kind-config.yaml modifié
setup-kind.ps1 modifié
/etc/hosts configuré

Manifests

01-rbac.yaml étendu
02-configmap.yaml étendu
03-secret.yaml étendu
04-resource-limits.yaml ajusté
05-network-policies.yaml réécrit
5 fichiers databases créés
6 fichiers services créés
30-ingress.yaml modifié

Images Kind

auth-service:local loaded
subscription-service:local loaded
offline-service:local loaded
ads-service:local loaded
quiz-core-service:local loaded
api-gateway:local loaded

Post-Déploiement

17 pods running
11 services actifs
17 network policies appliquées
Ingress fonctionnel
Tests API passent

