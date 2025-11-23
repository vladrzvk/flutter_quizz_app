# Guide kind via Docker Desktop

## Prerequis

1. Docker Desktop installe et lance
2. kubectl (verifier avec `kubectl version --client`)

---

## Etape 1 : Verifier kubectl

```powershell
kubectl version --client
```

**Si erreur** :
```powershell
choco install kubernetes-cli -y
```

---

## Etape 2 : Creer Cluster via Docker Desktop

### Via l'Interface Graphique

1. Ouvrir Docker Desktop
2. Cliquer sur **Kubernetes** (barre laterale gauche)
3. Cliquer sur **Create** ou le bouton **+**
4. Dans la fenetre "Create Kubernetes Cluster" :
    - Selectionner **kind**
    - **Node(s)** : Regler sur **3**
    - **Version** : Laisser par defaut (1.31.1 ou similaire)
    - Cliquer **Create**
5. Attendre 2-3 minutes (barre de progression)

### Verification

```powershell
# Voir les nodes
kubectl get nodes

# Devrait afficher 3 nodes
# NAME                         STATUS   ROLES           AGE
# kind-control-plane           Ready    control-plane   2m
# kind-worker                  Ready    <none>          2m
# kind-worker2                 Ready    <none>          2m
```

---

## Etape 3 : Installer NGINX Ingress

# Notes avec Docker-Desktop
Vous avez créé le cluster via Docker Desktop UI. Le label ingress-ready=true n'a pas été ajouté automatiquement aux nodes.
Ce label est normalement ajouté quand on crée le cluster avec un fichier de configuration kind.

# Ajouter le Label au Node
# Lister les nodes
kubectl get nodes

# Ajouter le label au control-plane node
kubectl label node desktop-control-plane ingress-ready=true

# Exemple si le node s'appelle "kind-control-plane"
# (kubectl label node kind-control-plane ingress-ready=true)


# Installer Ingress Controller

kubectl apply -f .\manifests\000-my-ingress.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/kind/deploy.yaml

# Attendre que ce soit pret
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/component=controller `
  --timeout=120s

---

## Etape 4 : Build Image Backend

cd backend
docker build -t quiz-backend:local -f ../../docker/backend-dev.Dockerfile .

**IMPORTANT avec Docker Desktop kind** :
L'image est **automatiquement disponible** dans le cluster.
**PAS BESOIN** de `kind load docker-image`.

---

## Etape 5 : Deployer Application


cd ../k8s/kind/manifests

# Deployer tous les manifests
kubectl apply -f .

# Ou dans l'ordre
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


---

## Etape 6 : Configurer /etc/hosts

Editer `C:\Windows\System32\drivers\etc\hosts` (admin requis) :

```
127.0.0.1 quiz-app.local
```

---

## Etape 7 : Tester


# Port-forward (si ingress ne marche pas)
kubectl port-forward -n quiz-app svc/quiz-backend 8080:8080

# Health check
curl http://quiz-app.local/health

# API
curl http://quiz-app.local/api/v1/quizzes

# Voir logs
kubectl logs -f deployment/quiz-backend -n quiz-app


---

## Differences avec kind CLI

### kind CLI (via Chocolatey)

```powershell
# Installation
choco install kind

# Creation cluster
kind create cluster --config kind-config.yaml

# Load image (OBLIGATOIRE)
kind load docker-image quiz-backend:local --name quiz-cluster

# Liste clusters
kind get clusters

# Supprimer cluster
kind delete cluster --name quiz-cluster
```

### kind Docker Desktop

```powershell
# Pas d'installation necessaire

# Creation cluster
# Via UI Docker Desktop

# Load image (PAS NECESSAIRE)
# Image automatiquement disponible

# Liste clusters
# Via UI Docker Desktop ou kubectl config get-contexts

# Supprimer cluster
# Via UI Docker Desktop (bouton Delete)
```

---

## Gestion du Cluster

### Via Docker Desktop UI

- **Demarrer/Arreter** : Toggle dans l'UI
- **Supprimer** : Bouton Delete
- **Logs** : Voir dans l'UI

### Via kubectl


# Contexte actuel
kubectl config current-context

# Lister contextes
kubectl config get-contexts

# Changer contexte
kubectl config use-context <context-name>

# Voir resources
kubectl get all -n quiz-app


---

## Nettoyage

### Via Docker Desktop

1. Ouvrir Docker Desktop
2. Aller dans Kubernetes
3. Selectionner le cluster
4. Cliquer Delete
5. Confirmer

### Via kubectl

```powershell
# Supprimer namespace (supprime tout dedans)
kubectl delete namespace quiz-app

# Supprimer ingress controller
kubectl delete namespace ingress-nginx
```

---

## Avantages Docker Desktop kind

1. **Pas d'installation supplementaire** : kind integre
2. **UI graphique** : Creation/gestion facile
3. **Images automatiques** : Pas besoin de load
4. **Integration** : Tout dans Docker Desktop
5. **Simple** : Moins de commandes CLI

---

## Inconvenients vs kind CLI

1. **Moins de controle** : Config moins fine
2. **Pas de config file** : Pas de kind-config.yaml
3. **Version K8s** : Limitee aux choix Docker Desktop
4. **Multi-clusters** : Moins pratique que kind CLI

---

## Recommandation

**Pour votre cas** :

**Utilisez kind via Docker Desktop** car :
- Plus simple
- Deja installe
- Images automatiques
- Interface graphique pratique

**Passez a kind CLI plus tard** si besoin de :
- Plusieurs clusters en parallele
- Configuration fine (kind-config.yaml)
- Automatisation CI/CD
- Multi-nodes complexes

---

## Quick Reference

```powershell
# Verifier cluster
kubectl get nodes

# Deployer app
kubectl apply -f manifests/

# Voir status
kubectl get all -n quiz-app

# Logs backend
kubectl logs -f deployment/quiz-backend -n quiz-app

# Logs PostgreSQL
kubectl logs -f statefulset/postgres -n quiz-app

# Shell dans pod
kubectl exec -it deployment/quiz-backend -n quiz-app -- sh

# Port-forward (si ingress ne marche pas)
kubectl port-forward -n quiz-app svc/quiz-backend 8080:8080
```

---

## Conclusion

**Reponse finale** :

- **kind** : NON, pas besoin d'installer (integre Docker Desktop)
- **kubectl** : Verifier d'abord, installer si absent

Utilisez le script `setup-kind-docker-desktop.ps1` qui gere tout automatiquement.