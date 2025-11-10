### Supprimer et Relancer Cluster kind

## Méthode 1 : Via Docker Desktop (RECOMMANDÉ) Arrêter le Cluster
Ouvrir Docker Desktop
Aller dans Kubernetes (barre latérale gauche)
Cliquer sur le cluster kind
Cliquer sur Stop ou toggle le switch pour désactiver
Supprimer Complètement
Dans Docker Desktop → Kubernetes
Sélectionner le cluster kind
Cliquer sur Delete (icône poubelle ou bouton Delete)
Confirmer la suppression
Attendre 30 secondes
Le cluster et toutes ses données sont supprimés.

## Méthode 2 : Via kubectl (Nettoyage Partiel)Si vous voulez juste nettoyer l'application sans supprimer le cluster :powershell# Supprimer namespace quiz-app (supprime tout dedans)
kubectl delete namespace quiz-app

# Supprimer Ingress Controller
kubectl delete namespace ingress-nginx

# Vérifier que tout est supprimé
kubectl get namespacesCette méthode garde le cluster mais supprime vos déploiements.

## Méthode 3 : Via kind CLI (Si Installé)Si vous avez installé kind via Chocolatey :
# Lister clusters
kind get clusters
# Supprimer le cluster
kind delete cluster --name <nom-du-cluster>
# Exemple
kind delete cluster --name quiz-cluster

## Méthode 4 : Via Docker (Forcé) Si les méthodes précédentes ne fonctionnent pas :

# Lister conteneurs kind
docker ps -a | findstr kind

# Arrêter conteneurs kind
docker stop $(docker ps -a | findstr kind | awk '{print $1}')

# Supprimer conteneurs kind
docker rm $(docker ps -a | findstr kind | awk '{print $1}')

# Supprimer réseaux kind
docker network ls | findstr kind
docker network rm <network-id>

# Supprimer volumes kind
docker volume ls | findstr kind
docker volume rm <volume-name>

Vérification Complète Suppression
# Vérifier contextes kubectl
kubectl config get-contexts

# Supprimer contexte kind (optionnel)
kubectl config delete-context kind-<nom-cluster>

# Vérifier conteneurs Docker
docker ps -a

# Vérifier volumes Docker
docker volume ls

# Vérifier réseaux Docker
docker network ls



### Relancer Proprement

## Étape 1 : Créer Nouveau Cluster
Via Docker Desktop :

Docker Desktop → Kubernetes
Cliquer Create
Sélectionner kind
Nodes : 3
Cliquer Create
Attendre 2-3 minutes


## Étape 2 : Vérifier Cluster

# Vérifier nodes
kubectl get nodes
# Devrait afficher 3 nodes

## Étape 3 : Installer Ingress
# Notes avec Docker-Desktop
Vous avez créé le cluster via Docker Desktop UI. Le label ingress-ready=true n'a pas été ajouté automatiquement aux nodes.
Ce label est normalement ajouté quand on crée le cluster avec un fichier de configuration kind.

Ajouter le Label au Node
# Lister les nodes
kubectl get nodes

# Ajouter le label au control-plane node
kubectl label node <nom-du-control-plane-node> ingress-ready=true

# Exemple si le node s'appelle "kind-control-plane"
kubectl label node kind-control-plane ingress-ready=true

# Installer NGINX Ingress Controller
kubectl apply -f ./manifests/000-my-ingress.yaml
ou
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/kind/deploy.yaml

# Attendre qu'il soit prêt
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s

# Vérifier Status Détaillé d'ingress
# Voir les pods dans namespace ingress-nginx
kubectl get pods -n ingress-nginx

# Description détaillée du deployment
kubectl describe deployment ingress-nginx-controller -n ingress-nginx

# Voir les events
kubectl get events -n ingress-nginx --sort-by='.lastTimestamp'

# Voir les logs 
# Logs du controller
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Logs en temps réel
kubectl logs -f -n ingress-nginx deployment/ingress-nginx-controller

# Dernières 50 lignes
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=50

# Vérifier le Service
kubectl get svc -n ingress-nginx

## Étape 4 : Build Image Backend
cd backend
docker build -t quiz-backend:local -f ../../docker/backend-dev.Dockerfile .

## Étape 5 : Déployer Application (Correct)
cd ../k8s/kind

# Déployer dans l'ordre
kubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/01-rbac.yaml
kubectl apply -f manifests/02-configmap.yaml
kubectl apply -f manifests/03-secret.yaml
kubectl apply -f manifests/04-resource-limits.yaml
kubectl apply -f manifests/05-network-policies.yaml
kubectl apply -f manifests/06-postgres-service.yaml
kubectl apply -f manifests/07-postgres-statefulset.yaml

# Attendre PostgreSQL
kubectl wait --for=condition=ready pod -l app=postgres -n quiz-app --timeout=120s

kubectl apply -f manifests/08-backend-service.yaml
kubectl apply -f manifests/09-backend-deployment.yaml

# Attendre Ingress Controller prêt
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
--selector=app.kubernetes.io/component=controller `
--timeout=120s

kubectl apply -f manifests/10-ingress.yaml

## Étape 6 : Vérifier
# Status
kubectl get all -n quiz-app

# Logs backend
kubectl logs -f deployment/quiz-backend -n quiz-app

# Port-forward (si ingress ne marche pas)
kubectl port-forward -n quiz-app svc/quiz-backend 8080:8080



### Problème
# Le deployment existe mais aucun pod backend n'est créé.

# 1. Voir status deployment
kubectl get deployment -n quiz-app

# 2. Détails deployment
kubectl describe deployment quiz-backend -n quiz-app

# 3. Voir replica sets
kubectl get replicaset -n quiz-app

# 4. Events récents
kubectl get events -n quiz-app --sort-by='.lastTimestamp'

### Nouveau Problème rencontré : Image busybox Ne Se Télécharge Pas
Failed to pull image "busybox:1.36":
failed to read expected number of bytes: unexpected EOF

# Solution : Pull Manuel busybox ou changer de version dans le manifest 
# Pull busybox manuellement
docker pull busybox:1.3
ou 
dans
initContainers:
- name: wait-for-postgres
image: alpine:3.19 # rempalcer busybox

# Redémarrer deployment
kubectl rollout restart deployment/quiz-backend -n quiz-app

# Vérifier
kubectl get pods -n quiz-app -w

### Nouvelle erreur : ImagePullBackOff - Image Pas dans les Nodes kind
Problème
Failed to pull image "quiz-backend:local": pull access denied
L'image quiz-backend:local existe sur votre PC mais pas dans les nodes kind.
5s          Normal    Pulling                 pod/quiz-backend-6c66d6749c-ggqm7                   Pulling image "quiz-backend:local"
4s          Warning   Failed                  pod/quiz-backend-6c66d6749c-ggqm7                   Error: ErrImagePull
4s          Warning   Failed                  pod/quiz-backend-6c66d6749c-ggqm7                   Failed to pull image "quiz-backend:local": failed to pull and unpack image "docker.io/library/quiz-backend:local": failed to resolve reference "docker.io/library/quiz-backend:local": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed


# Solution : upload l'image sur le hub
# Étape 1 : Login Docker Hub
docker login
# Étape 2 : Tag et Push
docker tag quiz-backend:local votre-username/quiz-backend:latest
docker push votre-username/quiz-backend:latest
# Étape 3 : Modifier Deployment
Éditez k8s/kind/manifests/09-backend-deployment.yaml
containers:
- name: quiz-backend
  image: votre-username/quiz-backend:latest  # Votre image Docker Hub
  imagePullPolicy: Always

# Étape 4 : Déployer
kubectl delete deployment quiz-backend -n quiz-app
kubectl apply -f k8s/kind/manifests/09-backend-deployment.yaml
kubectl get pods -n quiz-app -w