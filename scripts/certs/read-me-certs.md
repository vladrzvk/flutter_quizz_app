# Scripts de Génération Certificats mTLS (PowerShell)

Documentation pour la génération et gestion des certificats mTLS en environnement de développement Windows/PowerShell.

## 🎯 Objectif

Générer une infrastructure PKI (Public Key Infrastructure) pour authentification mutuelle TLS (mTLS) entre les services backend.

## 📁 Structure

```
scripts/certs/
├── 01-generate-ca.ps1             # Génère la CA racine
├── 02-generate-service-certs.ps1  # Génère certificats services
├── 03-import-to-k8s.ps1           # Import dans Kubernetes
├── README.md                       # Cette documentation
└── generated/                      # Certificats générés (gitignored)
    ├── ca.key                      # Clé privée CA (SENSIBLE)
    ├── ca.crt                      # Certificat public CA
    ├── gateway.key                 # Clé privée Gateway (SENSIBLE)
    ├── gateway.crt                 # Certificat Gateway
    ├── quiz-service.key            # Clé privée Quiz Service (SENSIBLE)
    ├── quiz-service.crt            # Certificat Quiz Service
    ├── auth-service.key            # Clé privée Auth Service (SENSIBLE)
    └── auth-service.crt            # Certificat Auth Service
```

## 🚀 Utilisation

### Prérequis

**Windows avec PowerShell 5.1+ ou PowerShell Core 7+**

```powershell
# Vérifier version PowerShell
$PSVersionTable.PSVersion

# Doit afficher: 5.1+ ou 7.0+
```

**OpenSSL pour Windows**

```powershell
# Option 1: Chocolatey
choco install openssl

# Option 2: Scoop
scoop install openssl

# Option 3: Télécharger depuis https://slproweb.com/products/Win32OpenSSL.html
# Installer et ajouter au PATH
```

Vérifier installation :
```powershell
openssl version
# Doit afficher: OpenSSL 1.1.1+ ou 3.0+
```

**kubectl configuré**
```powershell
kubectl version --client
```

**Namespace Kubernetes**
```powershell
kubectl get namespace quiz-app
# Si n'existe pas, sera créé automatiquement
```

### Génération complète (première fois)

```powershell
# 1. Ouvrir PowerShell en tant qu'administrateur (recommandé)
# Aller dans le dossier scripts/certs
cd scripts/certs

# 2. Autoriser exécution scripts (une seule fois)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Générer la CA racine
.\01-generate-ca.ps1

# 4. Générer les certificats de services
.\02-generate-service-certs.ps1

# 5. Importer dans Kubernetes
.\03-import-to-k8s.ps1
```

### Rotation des certificats (tous les 90 jours)

```powershell
# Régénérer uniquement les certificats services (pas la CA)
cd scripts/certs
.\02-generate-service-certs.ps1
.\03-import-to-k8s.ps1

# Redémarrer les pods pour charger nouveaux certificats
kubectl rollout restart deployment -n quiz-app
```

### Vérification

```powershell
# Vérifier les secrets créés
kubectl get secrets -n quiz-app | Select-String "tls"

# Vérifier le contenu d'un secret
kubectl describe secret gateway-tls -n quiz-app

# Extraire et vérifier un certificat
kubectl get secret gateway-tls -n quiz-app -o jsonpath='{.data.tls\.crt}' | `
    ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) } | `
    Out-File -Encoding ASCII temp-cert.crt

openssl x509 -in temp-cert.crt -noout -text
Remove-Item temp-cert.crt
```

## 🔒 Sécurité

### Fichiers sensibles (NE JAMAIS COMMIT)

- `*.key` : Clés privées
- `ca.key` : **CRITIQUE** - Clé privée de la CA

### Protection des clés

Le dossier `generated/` doit être dans `.gitignore`:

```gitignore
# scripts/certs/.gitignore
generated/
*.key
*.csr
```

### Permissions Windows recommandées

```powershell
# Restreindre accès aux clés privées (admin uniquement)
$AclPath = ".\generated\ca.key"
$Acl = Get-Acl $AclPath
$Acl.SetAccessRuleProtection($true, $false)
$Rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
    "FullControl",
    "Allow"
)
$Acl.AddAccessRule($Rule)
Set-Acl -Path $AclPath -AclObject $Acl
```

## 📋 Détails techniques

### CA (Certificate Authority)

- **Algorithme** : RSA 4096 bits
- **Validité** : 10 ans
- **Usage** : Signature de certificats (keyCertSign, cRLSign)
- **Subject** : `/C=FR/ST=IDF/L=Paris/O=QuizApp/OU=DevTeam/CN=QuizApp-CA`

### Certificats Services

- **Algorithme** : RSA 2048 bits
- **Validité** : 1 an (365 jours)
- **Usage** : serverAuth, clientAuth
- **SANs** :
  - `DNS:<service>`
  - `DNS:<service>.quiz-app.svc.cluster.local`
  - `DNS:localhost`

### Common Names (CN)

- Gateway : `CN=gateway`
- Quiz Service : `CN=quiz-service`
- Auth Service : `CN=auth-service`

## 🔄 Cycle de vie

### Développement (actuel)

1. CA auto-signée générée manuellement
2. Certificats signés par script PowerShell
3. Import manuel dans Kubernetes
4. Rotation manuelle tous les 90 jours

### Production (futur avec Vault)

1. CA externe (Let's Encrypt ou CA entreprise)
2. Vault génère et signe certificats à la volée
3. Vault Agent injecte certificats dans pods
4. Rotation automatique tous les 30 jours

## 🐛 Troubleshooting

### Erreur : "openssl : Le terme 'openssl' n'est pas reconnu"

```powershell
# OpenSSL non installé ou pas dans le PATH
# Installer via Chocolatey:
choco install openssl

# Ou ajouter manuellement au PATH:
$env:Path += ";C:\Program Files\OpenSSL-Win64\bin"
```

### Erreur : "CA non trouvée"

```powershell
# Vérifier existence CA
Test-Path "scripts\certs\generated\ca.key"
Test-Path "scripts\certs\generated\ca.crt"

# Si absent, régénérer
.\01-generate-ca.ps1
```

### Erreur : "Certificate verify failed"

```powershell
# Vérifier chaîne de confiance
cd scripts\certs\generated
openssl verify -CAfile ca.crt gateway.crt

# Si échec, régénérer certificats
cd ..
.\02-generate-service-certs.ps1
```

### Erreur : "Secret already exists"

```powershell
# Supprimer anciens secrets
kubectl delete secret gateway-tls quiz-service-tls auth-service-tls -n quiz-app

# Réimporter
.\03-import-to-k8s.ps1
```

### Certificat expiré

```powershell
# Vérifier date expiration
openssl x509 -in generated\gateway.crt -noout -dates

# Si expiré, régénérer
.\02-generate-service-certs.ps1
.\03-import-to-k8s.ps1
kubectl rollout restart deployment -n quiz-app
```

### Erreur execution policy

```powershell
# Autoriser exécution scripts locaux
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Ou pour un script spécifique
PowerShell.exe -ExecutionPolicy Bypass -File .\01-generate-ca.ps1
```

## 📚 Références

- [OpenSSL for Windows](https://slproweb.com/products/Win32OpenSSL.html)
- [RFC 5280 - X.509 PKI](https://datatracker.ietf.org/doc/html/rfc5280)
- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [Kubernetes TLS Secrets](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)

## ⚠️ Notes importantes

1. **Ces scripts sont pour DÉVELOPPEMENT uniquement**
2. En production, utiliser Vault + cert-manager
3. Ne jamais exposer les clés privées (*.key)
4. Renouveler certificats avant expiration
5. La CA dev ne doit PAS être utilisée en production

## 🪟 Spécificités Windows

- Les chemins utilisent `\` au lieu de `/`
- Variables d'environnement : `$env:VARIABLE` au lieu de `$VARIABLE`
- Base64 encoding : `[Convert]::ToBase64String()` au lieu de `base64`
- Encoding UTF-8 : Important pour fichiers .ext