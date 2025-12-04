# Guide de Deploiement Securise sur kind

## Prerequis

1. Docker Desktop installe
2. kind installe : `choco install kind`
3. kubectl installe : `choco install kubernetes-cli`

---

## Etape 1 : Creer le Cluster

```powershell
cd k8s/kind

# Executer le scripts de setup
.\setup-kind.ps1
```

Le script va :
- Creer un cluster 3 nodes (1 control-plane + 2 workers)
- Installer NGINX Ingress Controller
- Configurer le port mapping pour localhost

---

## Etape 2 : Build et Load l'Image Backend

```powershell
# Build l'image
cd backend
docker build -t quiz-backend:local -f ../docker/backend.Dockerfile .

# Charger l'image dans kind
kind load docker-image quiz-backend:local --name quiz-cluster

# Verifier
docker exec -it quiz-cluster-control-plane crictl images | grep quiz-backend
```

---

## Etape 3 : Deployer l'Application

```powershell
cd k8s/kind/manifests

# Deployer dans l'ordre
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-rbac.yaml
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-secret.yaml
kubectl apply -f 04-resource-limits.yaml
kubectl apply -f 05-network-policies.yaml
kubectl apply -f 06-postgres-service.yaml
kubectl apply -f 07-postgres-statefulset.yaml

# Attendre PostgreSQL
kubectl wait --for=condition=ready pod -l app=postgres -n quiz-app --timeout=120s

kubectl apply -f 08-backend-service.yaml
kubectl apply -f 09-backend-deployment.yaml
kubectl apply -f 10-ingress.yaml
```

Ou tout d'un coup :
```powershell
kubectl apply -f .
```

---

## Etape 4 : Verifier le Deploiement

```powershell
# Verifier tous les objets
kubectl get all -n quiz-app

# Verifier les pods
kubectl get pods -n quiz-app -o wide

# Verifier les network policies
kubectl get networkpolicies -n quiz-app

# Verifier les resource quotas
kubectl describe resourcequota quiz-app-quota -n quiz-app

# Logs backend
kubectl logs -f deployment/quiz-backend -n quiz-app

# Logs PostgreSQL
kubectl logs -f statefulset/postgres -n quiz-app
```

---

## Etape 5 : Configurer /etc/hosts

Ajouter dans `C:\Windows\System32\drivers\etc\hosts` :
```
127.0.0.1 quiz-app.local
```

---

## Etape 6 : Tester l'Application

```powershell
# Health check
curl http://quiz-app.local/health

# API
curl http://quiz-app.local/api/v1/quizzes
```

---

## Verification de la Securite

### 1. Verifier RBAC

```powershell
# Lister ServiceAccounts
kubectl get sa -n quiz-app

# Verifier roles
kubectl get roles -n quiz-app
kubectl describe role quiz-backend-role -n quiz-app

# Verifier rolebindings
kubectl get rolebindings -n quiz-app
```

### 2. Verifier Pod Security Standards

```powershell
# Verifier labels namespace
kubectl get namespace quiz-app --show-labels

# Tester creation pod non conforme
kubectl run test --image=nginx --namespace=quiz-app --privileged=true
# Devrait etre rejete
```

### 3. Verifier Security Contexts

```powershell
# Verifier security context backend
kubectl get pod -n quiz-app -l app=quiz-backend -o jsonpath='{.items[0].spec.securityContext}'

# Verifier capabilities
kubectl get pod -n quiz-app -l app=quiz-backend -o jsonpath='{.items[0].spec.containers[0].securityContext}'
```

### 4. Verifier Network Policies

```powershell
# Lister policies
kubectl get networkpolicies -n quiz-app

# Tester isolation : Creer pod test
kubectl run test-pod --image=busybox -n quiz-app --rm -it -- sh

# Dans le pod test, tenter connexion PostgreSQL (devrait echouer)
nc -zv postgres 5432
```

### 5. Verifier Resource Limits

```powershell
# Verifier quotas
kubectl describe resourcequota quiz-app-quota -n quiz-app

# Verifier limitrange
kubectl describe limitrange quiz-app-limitrange -n quiz-app

# Verifier resources pods
kubectl top pods -n quiz-app
```

---

## Deploiement Fonctionnalites Avancees (Optionnel)

### OPA Gatekeeper

```powershell
# Installer Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml

# Attendre demarrage
kubectl wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=120s

# Deployer policies
kubectl apply -f optional/gatekeeper-policies.yaml

# Tester : Creer pod avec tag latest (devrait etre rejete)
kubectl run test --image=nginx:latest -n quiz-app
```

### Falco (Runtime Security)

```powershell
# Installer Falco via Helm
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco --namespace falco-system --create-namespace

# Voir les alertes
kubectl logs -f -n falco-system -l app.kubernetes.io/name=falco
```

---

## Troubleshooting

### Pods en CrashLoopBackOff

```powershell
# Voir logs
kubectl logs <pod-name> -n quiz-app --previous

# Voir events
kubectl get events -n quiz-app --sort-by='.lastTimestamp'

# Describe pod
kubectl describe pod <pod-name> -n quiz-app
```

### Network Policy bloque trafic

```powershell
# Verifier policies
kubectl get networkpolicies -n quiz-app

# Temporairement desactiver pour tester
kubectl delete networkpolicy default-deny-all -n quiz-app

# Re-appliquer apres debug
kubectl apply -f 05-network-policies.yaml
```

### Image non trouvee

```powershell
# Verifier images dans kind
docker exec -it quiz-cluster-control-plane crictl images

# Recharger image
kind load docker-image quiz-backend:local --name quiz-cluster
```

### Resource Quota depasse

```powershell
# Voir utilisation
kubectl describe resourcequota quiz-app-quota -n quiz-app

# Augmenter quotas si necessaire
kubectl edit resourcequota quiz-app-quota -n quiz-app
```

---

## Nettoyage

### Supprimer application

```powershell
kubectl delete namespace quiz-app
```

### Supprimer cluster

```powershell
kind delete cluster --name quiz-cluster
```

---

## Prochaines Etapes

### Pour aller plus loin en securite :

1. **TLS/HTTPS**
   - Installer cert-manager
   - Configurer certificats automatiques

2. **Secrets externes**
   - Sealed Secrets
   - External Secrets Operator
   - HashiCorp Vault

3. **Service Mesh**
   - Istio pour mTLS automatique
   - Authorization policies fines

4. **Monitoring securite**
   - Falco pour runtime security
   - Prometheus + Grafana pour metriques
   - ELK pour logs centralises

5. **Image scanning**
   - Trivy pour scan vulnerabilites
   - Integration CI/CD

6. **Audit logging**
   - Activer audit logs K8s
   - Integration SIEM

---

## Bonnes Pratiques Production

1. Utiliser Sealed Secrets ou Vault (pas secrets K8s en clair)
2. Activer encryption-at-rest dans etcd
3. Scanner images avant deploiement
4. Mettre en place monitoring runtime (Falco)
5. Audit logs vers SIEM
6. Backup reguliers (Velero)
7. Disaster recovery plan
8. Penetration testing regulier
9. Rotation credentials automatique
10. Principe du moindre privilege partout
