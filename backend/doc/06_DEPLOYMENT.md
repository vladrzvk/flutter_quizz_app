# 🚀 Guide de Déploiement

Déploiement de l'application Quiz Géo sur différents environnements.

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Prérequis](#prérequis)
3. [Déploiement Local](#déploiement-local)
4. [Déploiement Kubernetes](#déploiement-kubernetes)
5. [Déploiement Production](#déploiement-production)
6. [Rollback](#rollback)
7. [Backup & Restore](#backup--restore)

---

## 🎯 Vue d'Ensemble

### Stratégie de DéploiementLocal Dev → Docker Desktop K8s → Staging K8s → Production K8s
↓              ↓                   ↓              ↓
Manual        Semi-Auto          Auto (CI/CD)   Auto (CI/CD)
↓              ↓                   ↓              ↓
Dev          Testing            Pre-Prod       Production

### Environnements

| Environnement | Infra | URL | Base de données | Monitoring |
|---------------|-------|-----|-----------------|------------|
| **Local** | Docker Desktop | localhost:8080 | PostgreSQL local | Non |
| **Staging** | K8s Cloud | staging.quiz-app.com | PostgreSQL Cloud | Oui |
| **Production** | K8s Cloud | quiz-app.com | PostgreSQL HA | Oui |

---

## 📦 Prérequis

### Outils Nécessaires
```bashDocker Desktop avec K8s
https://www.docker.com/products/docker-desktopkubectl
brew install kubectlHelm (optionnel mais recommandé)
brew install helmk9s (interface K8s)
brew install k9sGitHub CLI (pour les secrets)
brew install gh

### Variables d'Environnement
```bash~/.zshrc ou ~/.bashrc
export KUBE_NAMESPACE=quiz-app
export DOCKER_REGISTRY=ghcr.io/your-username
export DATABASE_URL=postgresql://user:pass@host:5432/db

---

## 💻 Déploiement Local

### 1. Setup Initial
```bashCloner le repo
git clone https://github.com/your-username/quiz-geo-app.git
cd quiz-geo-appActiver Kubernetes dans Docker Desktop
Docker Desktop → Settings → Kubernetes → EnableVérifier que K8s fonctionne
kubectl cluster-info
kubectl get nodes

### 2. Build des Images

#### Backend
```bashcd backendBuild l'image Docker
docker build -f ../docker/backend.Dockerfile -t quiz-backend:local .Tag pour utilisation locale
docker tag quiz-backend:local ghcr.io/your-username/quiz-backend:local

#### Frontend (pour tests)
```bashcd frontendBuild web
flutter build webBuild APK Android
flutter build apk --debugBuild iOS (nécessite Mac ou Codemagic)
flutter build ios --debug --no-codesign

### 3. Déploiement sur Docker Desktop K8s
```bashLancer le script de setup
./scripts/setup-k8s-local.shVérifier le déploiement
kubectl get all -n quiz-appAccéder à l'application
Ajouter à /etc/hosts si pas déjà fait
echo "127.0.0.1 quiz-app.local" | sudo tee -a /etc/hostsTester
curl http://quiz-app.local/health

### 4. Hot Reload pour le Développement
```bashBackend : Utiliser cargo watch
cd backend/quiz_core_service
cargo watch -x runFrontend : Hot reload natif Flutter
cd frontend
flutter run -d chrome # ou -d macos

---

## ☸️ Déploiement Kubernetes

### Déploiement Manuel

#### 1. Créer le Namespace
```bashkubectl apply -f k8s/local/namespace.yaml

#### 2. Créer les Secrets
```bashCréer le secret pour la base de données
kubectl create secret generic quiz-secrets 
--from-literal=database-url=$DATABASE_URL 
--from-literal=jwt-secret=$JWT_SECRET 
-n quiz-appVérifier
kubectl get secrets -n quiz-app
kubectl describe secret quiz-secrets -n quiz-app

#### 3. Déployer PostgreSQL
```bashkubectl apply -f k8s/local/postgres/
kubectl wait --for=condition=ready pod -l app=postgres -n quiz-app --timeout=120s

#### 4. Déployer le Backend
```bashkubectl apply -f k8s/local/quiz-backend/Vérifier le déploiement
kubectl rollout status deployment/quiz-backend -n quiz-appVoir les logs
kubectl logs -f -l app=quiz-backend -n quiz-app

#### 5. Configurer l'Ingress
```bashInstaller NGINX Ingress (si pas déjà fait)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yamlDéployer l'Ingress
kubectl apply -f k8s/local/ingress.yamlVérifier
kubectl get ingress -n quiz-app

### Déploiement Automatisé (CI/CD)

Le déploiement automatique se fait via GitHub Actions :
```yaml.github/workflows/backend-cd.yml
Déjà configuré dans 02_CI_CD.mdDéclenchement :
1. Push sur main → Deploy automatique
2. Tag v* → Deploy en production

---

## 🌐 Déploiement Production

### Différences Local vs Production

#### Configuration

**Local** : `k8s/local/`
**Production** : `k8s/production/`
```yamlDifférences principales :1. Replicas
Local : 1-2 replicas
Prod : 3-5 replicas avec HPA2. Resources
Local : requests/limits bas
Prod : requests/limits élevés3. Ingress
Local : HTTP
Prod : HTTPS avec Let's Encrypt4. Base de données
Local : Single instance
Prod : HA avec replicas et backup5. Secrets
Local : Secrets K8s basiques
Prod : HashiCorp Vault ou AWS Secrets Manager

### Étapes de Déploiement Production

#### 1. Préparer l'Infrastructure
```bashCréer le cluster (exemple avec DigitalOcean)
doctl kubernetes cluster create quiz-prod 
--region fra1 
--node-pool "name=worker-pool;size=s-2vcpu-4gb;count=3" 
--auto-upgradeRécupérer le kubeconfig
doctl kubernetes cluster kubeconfig save quiz-prodVérifier
kubectl cluster-info
kubectl get nodes

#### 2. Configurer le DNS
```bashRécupérer l'IP externe de l'Ingress
kubectl get svc -n ingress-nginxConfigurer les DNS
A record : quiz-app.com → <EXTERNAL_IP>
A record : *.quiz-app.com → <EXTERNAL_IP>

#### 3. Configurer SSL/TLS
```bashInstaller cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yamlCréer un ClusterIssuer Let's Encrypt
kubectl apply -f k8s/production/cert-issuer.yamlLe certificat sera créé automatiquement via l'Ingress

**Fichier** : `k8s/production/cert-issuer.yaml`
```yamlapiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
name: letsencrypt-prod
spec:
acme:
server: https://acme-v02.api.letsencrypt.org/directory
email: admin@quiz-app.com
privateKeySecretRef:
name: letsencrypt-prod
solvers:
- http01:
ingress:
class: nginx

#### 4. Déployer les Secrets
```bashEncoder les secrets
echo -n "$DATABASE_URL" | base64
echo -n "$JWT_SECRET" | base64Créer le secret
kubectl apply -f k8s/production/secrets.yamlOu utiliser un secret manager
Exemple avec AWS Secrets Manager
aws secretsmanager create-secret 
--name quiz-app/database-url 
--secret-string "$DATABASE_URL"

#### 5. Déployer l'Application
```bashAppliquer tous les manifests
kubectl apply -f k8s/production/Vérifier le déploiement
kubectl get all -n quiz-appVérifier les certificats
kubectl get certificate -n quiz-appTester l'application
curl https://quiz-app.com/health

#### 6. Configurer le Monitoring
```bashInstaller Prometheus + Grafana
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo updatehelm install prometheus prometheus-community/kube-prometheus-stack 
--namespace monitoring 
--create-namespace 
--values k8s/production/monitoring/prometheus-values.yamlAccéder à Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
Ouvrir http://localhost:3000
Login : admin / prom-operator

---

## ↩️ Rollback

### Rollback d'un Déploiement
```bashVoir l'historique des déploiements
kubectl rollout history deployment/quiz-backend -n quiz-appRollback à la version précédente
kubectl rollout undo deployment/quiz-backend -n quiz-appRollback à une version spécifique
kubectl rollout undo deployment/quiz-backend -n quiz-app --to-revision=3Vérifier le rollback
kubectl rollout status deployment/quiz-backend -n quiz-app

### Rollback d'une Base de Données
```bashRestaurer depuis un backup
kubectl exec -n quiz-app postgres-0 -- 
pg_restore -U quiz_user -d quiz_db /backups/quiz_db_backup.dumpOu utiliser un snapshot cloud
Exemple avec DigitalOcean
doctl databases backups list <database-id>
doctl databases backups restore <database-id> <backup-id>

---

## 💾 Backup & Restore

### Backup Automatique PostgreSQL

**CronJob** : `k8s/production/postgres/backup-cronjob.yaml`
```yamlapiVersion: batch/v1
kind: CronJob
metadata:
name: postgres-backup
namespace: quiz-app
spec:
schedule: "0 2 * * *"  # Tous les jours à 2h du matin
jobTemplate:
spec:
template:
spec:
containers:
- name: backup
image: postgres:15
env:
- name: PGPASSWORD
valueFrom:
secretKeyRef:
name: quiz-secrets
key: postgres-password
command:
- /bin/bash
- -c
- |
BACKUP_FILE="/backups/quiz_db_$(date +%Y%m%d_%H%M%S).dump"
pg_dump -h postgres -U quiz_user -Fc quiz_db > $BACKUP_FILE          # Upload vers S3 (optionnel)
          aws s3 cp $BACKUP_FILE s3://quiz-backups/postgresql/          # Garder seulement les 7 derniers backups locaux
          ls -t /backups/*.dump | tail -n +8 | xargs rm -f
        volumeMounts:
        - name: backup-storage
          mountPath: /backups
      restartPolicy: OnFailure
      volumes:
      - name: backup-storage
        persistentVolumeClaim:
          claimName: postgres-backup-pvc

### Restaurer depuis un Backup
```bashLister les backups disponibles
kubectl exec -n quiz-app postgres-0 -- ls -lh /backups/Restaurer
kubectl exec -n quiz-app postgres-0 -- 
pg_restore -U quiz_user -d quiz_db --clean --if-exists 
/backups/quiz_db_20251101_020000.dumpOu depuis S3
kubectl exec -n quiz-app postgres-0 -- bash -c 
"aws s3 cp s3://quiz-backups/postgresql/quiz_db_20251101.dump - | 
pg_restore -U quiz_user -d quiz_db --clean --if-exists"

---

## 🔄 Blue-Green Deployment

### Configuration
```yamlk8s/production/quiz-backend/deployment-blue.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
name: quiz-backend-blue
namespace: quiz-app
labels:
app: quiz-backend
version: blue
spec:
replicas: 3
selector:
matchLabels:
app: quiz-backend
version: blue
template:
metadata:
labels:
app: quiz-backend
version: blue
spec:
containers:
- name: quiz-backend
image: ghcr.io/your-username/quiz-backend:v1.0.0
# ... reste de la config
```yamlk8s/production/quiz-backend/deployment-green.yaml
Identique mais avec version: green et image différente

### Processus de Déploiement Blue-Green
```bash1. Déployer la nouvelle version (green)
kubectl apply -f k8s/production/quiz-backend/deployment-green.yaml2. Attendre que green soit prêt
kubectl wait --for=condition=ready pod -l version=green -n quiz-app3. Tester green en interne
kubectl port-forward -n quiz-app deployment/quiz-backend-green 9090:8080
curl http://localhost:9090/health4. Switcher le traffic vers green
kubectl patch service quiz-backend -n quiz-app -p 
'{"spec":{"selector":{"version":"green"}}}'5. Surveiller les métriques pendant 10 minutes6a. Si OK : Supprimer blue
kubectl delete deployment quiz-backend-blue -n quiz-app6b. Si problème : Rollback vers blue
kubectl patch service quiz-backend -n quiz-app -p 
'{"spec":{"selector":{"version":"blue"}}}'

---

## 📊 Health Checks

### Vérifications Post-Déploiement

**Script** : `scripts/verify-deployment.sh`
```bash#!/bin/bash
set -eNAMESPACE=${1:-quiz-app}
DEPLOYMENT=${2:-quiz-backend}echo "🔍 Vérification du déploiement de $DEPLOYMENT dans $NAMESPACE"1. Vérifier que les pods sont prêts
echo "📦 Vérification des pods..."
kubectl wait --for=condition=ready pod 
-l app=$DEPLOYMENT 
-n $NAMESPACE 
--timeout=300s2. Vérifier le service
echo "🌐 Vérification du service..."
kubectl get svc $DEPLOYMENT -n $NAMESPACE3. Health check HTTP
echo "🏥 Health check..."
POD=(kubectl get pod -n $NAMESPACE -l app=
DEPLOYMENT -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n $NAMESPACE $POD -- curl -f
http://localhost:8080/health4. Vérifier les logs (pas d'erreurs récentes)
echo "📝 Vérification des logs..."
kubectl logs -n NAMESPACE−lapp=NAMESPACE -l app=
NAMESPACE−lapp=DEPLOYMENT --tail=20 | grep -i error && exit 1 || true
5. Vérifier les métriques
echo "📊 Vérification des métriques..."
kubectl top pods -n NAMESPACE−lapp=NAMESPACE -l app=
NAMESPACE−lapp=DEPLOYMENT
echo "✅ Déploiement vérifié avec succès !"

---

## 🚨 Procédures d'Urgence

### Rollback d'Urgence
```bashRollback immédiat
kubectl rollout undo deployment/quiz-backend -n quiz-appScaler à 0 si problème critique
kubectl scale deployment/quiz-backend -n quiz-app --replicas=0Restaurer depuis backup
./scripts/restore-from-backup.sh latest

### Contacts d'Urgence

| Rôle | Nom | Contact |
|------|-----|---------|
| DevOps Lead | Toi | ton-email@example.com |
| Backend Lead | - | - |
| DBA | - | - |
| On-call | - | PagerDuty |

---

## 📚 Ressources

- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Blue-Green Deployment](https://docs.cloudfoundry.org/devguide/deploy-apps/blue-green.html)
- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [PostgreSQL Backup Best Practices](https://www.postgresql.org/docs/current/backup.html)