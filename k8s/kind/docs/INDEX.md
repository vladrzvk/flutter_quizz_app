# Index Complet - Configuration kind Securisee

## Structure Complete

```
k8s/kind/
├── kind-config.yaml                    # Configuration cluster kind
├── setup-kind.ps1                      # Script setup automatique
├── DEPLOYMENT-GUIDE.md                 # Guide deploiement complet
├── SECURITY-LEVERS.md                  # Documentation leviers securite
│
├── manifests/                          # Manifests principaux
│   ├── 00-namespace.yaml               # Namespace + Pod Security Standards
│   ├── 01-rbac.yaml                    # RBAC complet (SA + Roles)
│   ├── 02-configmap.yaml               # Configuration non-sensible
│   ├── 03-secret.yaml                  # Secrets (a proteger)
│   ├── 04-resource-limits.yaml         # Quotas + LimitRanges
│   ├── 05-network-policies.yaml        # Isolation reseau
│   ├── 06-postgres-service.yaml        # Service PostgreSQL
│   ├── 07-postgres-statefulset.yaml    # PostgreSQL securise
│   ├── 08-backend-service.yaml         # Service backend
│   ├── 09-backend-deployment.yaml      # Backend securise + PDB
│   └── 10-ingress.yaml                 # Ingress avec securite
│
└── optional/                           # Fonctionnalites avancees
    └── gatekeeper-policies.yaml        # OPA Gatekeeper policies
```

---

## Fichiers Generes (Total : 15)

### Configuration & Scripts (3 fichiers)

| Fichier | Description |
|---------|-------------|
| `kind-config.yaml` | Config cluster 3 nodes avec port mapping |
| `setup-kind.ps1` | Script setup automatique complet |
| `SECURITY-LEVERS.md` | Documentation complete leviers securite |

### Manifests Core (11 fichiers)

| Fichier | Ressources | Leviers Securite Appliques |
|---------|-----------|---------------------------|
| `00-namespace.yaml` | Namespace | Pod Security Standards (restricted) |
| `01-rbac.yaml` | ServiceAccounts, Roles, RoleBindings | RBAC, Principe moindre privilege |
| `02-configmap.yaml` | ConfigMap | Separation config sensible/non-sensible |
| `03-secret.yaml` | Secret | Secrets K8s (a remplacer par Sealed Secrets) |
| `04-resource-limits.yaml` | ResourceQuota, LimitRange | Controle ressources, DoS prevention |
| `05-network-policies.yaml` | NetworkPolicies (3) | Isolation reseau, deny-by-default |
| `06-postgres-service.yaml` | Service | Service headless |
| `07-postgres-statefulset.yaml` | StatefulSet | Security contexts complets, non-root |
| `08-backend-service.yaml` | Service | Service ClusterIP |
| `09-backend-deployment.yaml` | Deployment, PDB | Security contexts, PDB, init container |
| `10-ingress.yaml` | Ingress | Security headers, rate limiting |

### Optionnels (1 fichier)

| Fichier | Description |
|---------|-------------|
| `gatekeeper-policies.yaml` | OPA Gatekeeper policies (admission control) |

### Documentation (2 fichiers)

| Fichier | Description |
|---------|-------------|
| `SECURITY-LEVERS.md` | Documentation complete leviers securite K8s |
| `DEPLOYMENT-GUIDE.md` | Guide deploiement pas a pas |

---

## Leviers de Securite Appliques

### 1. RBAC
- ServiceAccounts dedies pour backend et PostgreSQL
- Roles avec permissions minimales
- RoleBindings

### 2. Pod Security Standards
- Niveau `restricted` en mode `enforce`
- Applique au namespace entier

### 3. Security Contexts

#### Niveau Pod
- `runAsNonRoot: true`
- `runAsUser/runAsGroup: 65532` (backend) / `999` (postgres)
- `fsGroup` configure
- `seccompProfile: RuntimeDefault`

#### Niveau Conteneur
- `allowPrivilegeEscalation: false`
- `readOnlyRootFilesystem: true` (sauf PostgreSQL)
- `capabilities: drop: [ALL]`
- Pas de mode `privileged`

### 4. Network Policies
- Deny-all par defaut
- Autorisation explicite backend <-> PostgreSQL
- Autorisation Ingress -> backend
- DNS autorise pour tous

### 5. Resource Management
- ResourceQuota global namespace
- LimitRange pour valeurs min/max/default
- Requests et limits sur tous les conteneurs

### 6. Secrets Management
- Secrets K8s (base, a ameliorer)
- Montage en volumes (pas env vars)
- Notes pour Sealed Secrets/External Secrets

### 7. Image Security
- `imagePullPolicy` configure
- Init containers avec security contexts
- Images tagged (pas latest)

### 8. High Availability
- 2 replicas backend
- PodDisruptionBudget (minAvailable: 1)
- RollingUpdate strategy

### 9. Ingress Security
- Security headers (X-Frame-Options, etc.)
- Rate limiting (100 req/s, 50 conn)
- Timeouts configures
- CORS configure

### 10. Monitoring Hooks
- Annotations Prometheus
- Liveness/Readiness probes

---

## Differences avec Version Non-Securisee

| Aspect | Version Simple | Version Securisee |
|--------|---------------|------------------|
| Namespace | Labels basiques | Pod Security Standards |
| RBAC | Aucun | ServiceAccounts + Roles |
| Security Contexts | Basiques | Complets (pod + container) |
| Network Policies | Aucune | 3 policies (deny-all + autorisation) |
| Resource Limits | ResourceQuota simple | Quotas + LimitRanges |
| Secrets | En clair | Annotations + notes upgrade |
| Image Pull | IfNotPresent | Never (kind local) |
| PDB | Aucun | PDB avec minAvailable |
| Ingress | Basique | Security headers + rate limit |

---

## Ordre de Deploiement Recommande

1. **Infrastructure**
   ```
   00-namespace.yaml
   01-rbac.yaml
   02-configmap.yaml
   03-secret.yaml
   04-resource-limits.yaml
   05-network-policies.yaml
   ```

2. **Base de Donnees**
   ```
   06-postgres-service.yaml
   07-postgres-statefulset.yaml
   ```
   Attendre readiness : `kubectl wait...`

3. **Backend**
   ```
   08-backend-service.yaml
   09-backend-deployment.yaml
   ```

4. **Exposition**
   ```
   10-ingress.yaml
   ```

5. **Optionnel**
   ```
   optional/gatekeeper-policies.yaml
   ```

---

## Commandes Essentielles

### Setup
```powershell
.\setup-kind.ps1
kind load docker-image quiz-backend:local --name quiz-cluster
kubectl apply -f manifests/
```

### Verification
```powershell
kubectl get all -n quiz-app
kubectl get networkpolicies -n quiz-app
kubectl describe resourcequota quiz-app-quota -n quiz-app
```

### Tests
```powershell
curl http://quiz-app.local/health
kubectl logs -f deployment/quiz-backend -n quiz-app
```

### Nettoyage
```powershell
kubectl delete namespace quiz-app
kind delete cluster --name quiz-cluster
```

---

## Prochaines Ameliorations Possibles

### Court Terme
1. Sealed Secrets pour chiffrement secrets
2. cert-manager pour TLS automatique
3. Monitoring Prometheus/Grafana

### Moyen Terme
1. OPA Gatekeeper en production
2. Falco pour runtime security
3. Image scanning (Trivy)
4. Backup Velero

### Long Terme
1. Service Mesh (Istio/Linkerd) pour mTLS
2. Vault pour secrets management
3. SIEM integration pour audit logs
4. Policy as Code complet

---

## Conformite

Cette configuration respecte :
- CIS Kubernetes Benchmark (majorite des controles)
- Pod Security Standards niveau restricted
- Principe du moindre privilege
- Defense en profondeur
- Separation of concerns

Outils verification conformite :
- kube-bench pour CIS Benchmark
- kube-hunter pour pentest
- Falco pour runtime

---

## Notes Importantes

1. **Secrets** : En production, NE PAS utiliser secrets K8s en clair
2. **TLS** : Activer en production avec cert-manager
3. **Images** : Scanner avant deploiement (Trivy)
4. **Backup** : Mettre en place Velero
5. **Monitoring** : Integrer Prometheus + Falco
6. **Audit** : Activer audit logs K8s
7. **Network** : Les NetworkPolicies sont strictes, ajuster si besoin

---

## Support

Pour questions ou problemes :
1. Consulter DEPLOYMENT-GUIDE.md (troubleshooting)
2. Consulter SECURITY-LEVERS.md (explications)
3. Verifier logs : `kubectl logs ...`
4. Verifier events : `kubectl get events ...`
