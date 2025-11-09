# Leviers de Securisation Kubernetes

Ce document presente tous les mecanismes de securite disponibles dans Kubernetes.

---

## 1. RBAC (Role-Based Access Control)

### Explication
Controle d'acces base sur les roles. Definit qui peut faire quoi sur quelles ressources.

### Composants
- **ServiceAccount** : Identite pour les pods
- **Role/ClusterRole** : Ensemble de permissions
- **RoleBinding/ClusterRoleBinding** : Lie un role a un utilisateur/ServiceAccount

### Portee
- **Role** : Namespace scope (limite a un namespace)
- **ClusterRole** : Cluster scope (sur tout le cluster)

### Principe du moindre privilege
Donner uniquement les permissions necessaires, rien de plus.

---

## 2. Pod Security Standards

### Explication
Remplace PodSecurityPolicy (deprecated). Trois niveaux de securite appliques aux namespaces.

### Niveaux
- **Privileged** : Aucune restriction (non recommande)
- **Baseline** : Restrictions minimales (bloque les privileges dangereux)
- **Restricted** : Hautement restrictif (production recommandee)

### Modes d'application
- **enforce** : Rejette les pods non conformes
- **audit** : Autorise mais log les violations
- **warn** : Autorise mais avertit l'utilisateur

### Application
Via labels sur le namespace.

---

## 3. Security Context

### Explication
Configuration de securite au niveau pod et conteneur.

### Parametres principaux

#### Au niveau Pod
- **runAsNonRoot** : Force l'execution sans root
- **runAsUser/runAsGroup** : UID/GID specifiques
- **fsGroup** : GID pour les volumes
- **seccompProfile** : Profil seccomp pour syscalls
- **seLinuxOptions** : Configuration SELinux

#### Au niveau Conteneur
- **allowPrivilegeEscalation** : Empeche l'escalade de privileges
- **readOnlyRootFilesystem** : Filesystem racine en lecture seule
- **capabilities** : Ajouter/supprimer des Linux capabilities
- **privileged** : Mode privilegie (a eviter)

---

## 4. Network Policies

### Explication
Firewall au niveau Kubernetes. Controle le trafic entre pods.

### Types de regles
- **Ingress** : Trafic entrant vers les pods
- **Egress** : Trafic sortant des pods

### Selecteurs
- **podSelector** : Selection des pods cibles
- **namespaceSelector** : Selection par namespace
- **ipBlock** : Selection par plage IP

### Strategie
Par defaut, tout est autorise. Une NetworkPolicy active le mode "deny by default".

---

## 5. Secrets Management

### Explication
Gestion securisee des donnees sensibles.

### Types de secrets
- **Opaque** : Donnees arbitraires (defaut)
- **kubernetes.io/service-account-token** : Token de ServiceAccount
- **kubernetes.io/dockerconfigjson** : Credentials registry Docker
- **kubernetes.io/tls** : Certificats TLS

### Bonnes pratiques
- Chiffrement at-rest (encryption-at-rest dans etcd)
- Rotation reguliere
- Montage en volume (pas en variable d'environnement)
- Outils externes : Sealed Secrets, External Secrets Operator, Vault

### Limitations natives
Les secrets K8s sont base64 encodes, pas chiffres par defaut.

---

## 6. Resource Quotas & Limit Ranges

### Explication
Controle de l'utilisation des ressources.

### Resource Quota
Limite globale au niveau namespace :
- CPU/Memory total
- Nombre de pods/services/secrets
- Storage

### Limit Range
Limites par defaut et min/max pour les conteneurs :
- CPU/Memory request/limit par defaut
- Min/Max CPU/Memory par conteneur
- Ratio max entre request et limit

### But
Eviter qu'un pod consomme toutes les ressources du cluster.

---

## 7. Image Security

### Explication
Securite des images de conteneurs.

### Leviers

#### Image Pull Policy
- **Always** : Toujours pull (recommande en prod)
- **IfNotPresent** : Pull si absente
- **Never** : Ne jamais pull

#### Image Scanning
- Scan des vulnerabilites (Trivy, Clair, Snyk)
- Integration CI/CD pour bloquer images vulnerables

#### Image Signing
- Verification de la signature (Cosign, Notary)
- Admission controller pour verifier signatures

#### Private Registry
- Utilisation de registries prives
- ImagePullSecrets pour authentification

#### Admission Controllers
- **ImagePolicyWebhook** : Valide les images avant admission
- **AlwaysPullImages** : Force le pull systematique

---

## 8. Admission Controllers

### Explication
Interceptent les requetes API avant persistance des objets.

### Types

#### Validating Admission
Valide la requete (accept/reject).

#### Mutating Admission
Modifie la requete avant persistance.

### Admission Controllers courants

#### Built-in
- **PodSecurity** : Applique Pod Security Standards
- **LimitRanger** : Applique LimitRange
- **ResourceQuota** : Applique quotas
- **AlwaysPullImages** : Force pull des images
- **DefaultStorageClass** : Assigne storage class par defaut

#### Personnalises (webhooks)
- **OPA Gatekeeper** : Policies as code
- **Kyverno** : Policy engine K8s-native
- **Custom webhooks** : Validation/mutation personnalisee

---

## 9. Audit Logging

### Explication
Enregistrement de toutes les requetes API pour traçabilite.

### Niveaux d'audit
- **None** : Pas de log
- **Metadata** : Log metadata uniquement
- **Request** : Log metadata + request body
- **RequestResponse** : Log metadata + request + response

### Configuration
Via AuditPolicy (fichier YAML) defini au demarrage de l'API server.

### Stockage
- Fichiers logs
- Webhook vers SIEM
- Backend externe (Elasticsearch, Splunk)

### But
Detective control : detecter activites suspectes, forensics.

---

## 10. TLS & Certificats

### Explication
Chiffrement des communications.

### Composants

#### API Server TLS
Tous les clients doivent utiliser TLS pour communiquer avec l'API.

#### Pod-to-Pod encryption (mTLS)
Service mesh (Istio, Linkerd) pour chiffrer trafic inter-pods.

#### Ingress TLS
Certificats TLS pour exposition externe :
- cert-manager pour gestion automatique
- Let's Encrypt pour certificats gratuits

#### etcd encryption
Chiffrement des donnees at-rest dans etcd.

---

## 11. Service Mesh

### Explication
Couche infrastructure pour gerer communication entre services.

### Fonctionnalites securite
- **mTLS automatique** : Chiffrement transparent
- **Authorization policies** : Controle d'acces fin
- **Traffic encryption** : Tout le trafic chiffre
- **Identity** : Identity forte pour chaque service

### Solutions
- Istio
- Linkerd
- Consul Connect

### Complexite
Important overhead, reserve aux clusters de taille moyenne/grande.

---

## 12. Pod Disruption Budget (PDB)

### Explication
Garantit disponibilite minimum pendant operations de maintenance.

### Configuration
- **minAvailable** : Nombre minimum de pods disponibles
- **maxUnavailable** : Nombre maximum de pods indisponibles

### But
Empeche qu'un drain/evict rende le service indisponible.

---

## 13. Security Scanning & Compliance

### Explication
Verification continue de la conformite securite.

### Outils

#### Cluster scanning
- **kube-bench** : Verifie conformite CIS Benchmark
- **kube-hunter** : Pentest du cluster
- **Falco** : Runtime security monitoring

#### Image scanning
- **Trivy** : Scan vulnerabilites images
- **Clair** : Analyse statique images
- **Snyk** : Scan vulnerabilites + suggestions

#### Policy compliance
- **OPA Gatekeeper** : Policies as code
- **Kyverno** : Policy engine declaratif

---

## 14. Runtime Security

### Explication
Securite pendant l'execution des workloads.

### Mecanismes

#### seccomp
Limite les syscalls disponibles pour les conteneurs.

#### AppArmor
Mandatory Access Control (MAC) pour limiter actions des processus.

#### SELinux
Context-based access control.

#### Falco
Detecte comportements anormaux en runtime :
- Acces fichiers sensibles
- Execution de shells
- Privilege escalation
- Network anomalies

---

## 15. Supply Chain Security

### Explication
Securise la chaine d'approvisionnement logicielle.

### Composants

#### Image Signing
- Signature cryptographique des images (Cosign)
- Verification avant deploiement

#### SBOM (Software Bill of Materials)
- Liste des composants et dependances
- Traçabilite complete

#### Binary Authorization
- Admission controller verifiant signatures
- Politique de deploiement basee sur attestations

---

## Hierarchie des Controles

### Preventive (Empecher)
1. RBAC
2. Pod Security Standards
3. Network Policies
4. Admission Controllers
5. Resource Quotas

### Detective (Detecter)
1. Audit Logging
2. Falco
3. Monitoring & Alerting

### Corrective (Corriger)
1. Automated remediation
2. Incident response procedures

---

## Strategie de Mise en Oeuvre

### Phase 1 : Fondations
1. RBAC
2. Security Contexts
3. Resource Quotas
4. Secrets management basique

### Phase 2 : Hardening
1. Pod Security Standards (enforce)
2. Network Policies
3. Admission controllers
4. Image scanning

### Phase 3 : Advanced
1. Service Mesh
2. Falco
3. OPA/Gatekeeper
4. Supply chain security

---

## Principe du Moindre Privilege

Appliquer partout :
- RBAC : Permissions minimales
- Security Context : Capabilities minimales
- Network Policies : Trafic minimal necessaire
- Resource Quotas : Ressources justes necessaires

---

## Defense en Profondeur

Multiplier les couches de securite :
- Pas une seule mesure
- Combinaison de multiples controles
- Si une couche echoue, les autres protegent

---

## Conformite

### Standards
- CIS Kubernetes Benchmark
- NIST Cybersecurity Framework
- PCI-DSS (pour paiements)
- HIPAA (pour sante)
- SOC 2

### Outils de verification
- kube-bench pour CIS
- Compliance operators pour standards specifiques
