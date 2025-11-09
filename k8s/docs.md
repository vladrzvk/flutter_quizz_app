### Structure des Manifests Kubernetes
📋 Organisation des Fichiers
Chaque fichier = Une ressource unique pour une meilleure maintenabilité.
k8s/local/
├── 00-namespace.yaml          # Namespace "quiz-app"
├── 01-configmap.yaml           # Configuration non-sensible
├── 02-secret.yaml              # Credentials (DATABASE_URL, JWT_SECRET)
├── 03-postgres-service.yaml    # Service headless pour PostgreSQL
├── 04-postgres-statefulset.yaml # Base de données avec volume persistant
├── 05-backend-service.yaml     # Service ClusterIP pour backend
├── 06-backend-deployment.yaml  # Application backend (2 replicas)
└── 07-ingress.yaml             # Exposition sur localhost

🎯 Principe : 1 Fichier = 1 Ressource
✅ Avantages

Lisibilité : Facile de retrouver une ressource
Modifications ciblées : Changer le ConfigMap sans toucher au Secret
Git-friendly : Diffs clairs et précis
Évolutivité : Ajouter un service = Ajouter 2 fichiers

❌ À Éviter
Ne pas regrouper plusieurs ressources dans un seul fichier :
yaml# ❌ Mauvaise pratique
---
apiVersion: v1
kind: ConfigMap
...
---
apiVersion: v1
kind: Secret
...
---
# Difficile à maintenir !

📝 Convention de Nommage
[numéro]-[nom-ressource]-[type].yaml
Exemples :

03-postgres-service.yaml → Service pour PostgreSQL
04-postgres-statefulset.yaml → StatefulSet pour PostgreSQL
05-backend-service.yaml → Service pour Backend
06-backend-deployment.yaml → Deployment pour Backend

Numérotation :

00-09 : Infrastructure (namespace, config, secrets)
10-19 : Base de données
20-29 : Backend
30-39 : Frontend (si déployé sur K8s)
40-49 : Services annexes (Redis, RabbitMQ, etc.)
90-99 : Ingress, monitoring


🔄 Workflow de Modification
1. Modifier le ConfigMap
   bash# 1. Éditer le fichier
   nano 01-configmap.yaml

# 2. Apply seulement ce fichier
kubectl apply -f 01-configmap.yaml

# 3. Redémarrer les pods qui l'utilisent
kubectl rollout restart deployment/quiz-backend -n quiz-app
2. Ajouter un Nouveau Service (Redis)
   bash# 1. Créer les fichiers
   touch 08-redis-service.yaml
   touch 09-redis-deployment.yaml

# 2. Éditer les fichiers
# ...

# 3. Apply les nouveaux fichiers
kubectl apply -f 08-redis-service.yaml
kubectl apply -f 09-redis-deployment.yaml
3. Supprimer un Service
   bash# 1. Delete les ressources
   kubectl delete -f 08-redis-service.yaml
   kubectl delete -f 09-redis-deployment.yaml

# 2. Supprimer les fichiers
rm 08-redis-service.yaml 09-redis-deployment.yaml

🎓 Évolution de l'Architecture
Exemple : Ajouter un Cache Redis
k8s/local/
├── ...
├── 06-backend-deployment.yaml
├── 07-ingress.yaml
├── 08-redis-service.yaml        # ✅ Nouveau
├── 09-redis-deployment.yaml     # ✅ Nouveau
└── 10-backend-configmap.yaml    # ✅ Modifier pour ajouter REDIS_URL
Exemple : Séparer Frontend
k8s/local/
├── ...
├── 20-frontend-service.yaml     # ✅ Nouveau
├── 21-frontend-deployment.yaml  # ✅ Nouveau
└── 22-frontend-ingress.yaml     # ✅ Nouveau (ou fusionner avec 07)

🚀 Commandes Utiles
Apply Tout
bash# Applique tous les manifests dans l'ordre numérique
kubectl apply -f .
Apply Sélectif
bash# Seulement PostgreSQL
kubectl apply -f 03-postgres-service.yaml -f 04-postgres-statefulset.yaml

# Seulement Backend
kubectl apply -f 05-backend-service.yaml -f 06-backend-deployment.yaml
Watch les Changements
bash# Watch tous les objets
kubectl get all -n quiz-app -w

# Watch seulement les pods
kubectl get pods -n quiz-app -w

📊 Dépendances
00-namespace.yaml
↓
01-configmap.yaml + 02-secret.yaml
↓
03-postgres-service.yaml + 04-postgres-statefulset.yaml
↓ (attendre que PostgreSQL soit prêt)
05-backend-service.yaml + 06-backend-deployment.yaml
↓
07-ingress.yaml
Ordre recommandé : Suivre la numérotation.

💡 Best Practices

1 fichier = 1 ressource ✅
Numérotation logique (infrastructure → services → ingress)
Commentaires dans chaque fichier pour expliquer son rôle
Git : Commit par fichier modifié pour des historiques clairs
Documentation : Mettre à jour ce fichier quand la structure évolue


Structure maintenue par : Moi
Dernière mise à jour : 08/11/202()