# 🔄 CI/CD - Intégration et Déploiement Continu

Guide complet pour la CI/CD du projet Quiz Géo.

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Backend CI/CD](#backend-cicd)
3. [Frontend CI/CD](#frontend-cicd)
4. [Secrets & Variables](#secrets--variables)
5. [Notifications](#notifications)
6. [Best Practices](#best-practices)

---

## 🎯 Vue d'Ensemble

### Architecture CI/CD
```
┌──────────────────────────────────────────────────┐
│              GitHub Repository                    │
└───────────────┬──────────────────────────────────┘
                │
       ┌────────┴────────┐
       │                 │
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│   Backend   │   │  Frontend   │
│   (Rust)    │   │  (Flutter)  │
└──────┬──────┘   └──────┬──────┘
       │                 │
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│   GitHub    │   │ Codemagic   │
│   Actions   │   │             │
└──────┬──────┘   └──────┬──────┘
       │                 │
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│   Docker    │   │ TestFlight  │
│   Registry  │   │   + APK     │
└──────┬──────┘   └─────────────┘
       │
       ▼
┌─────────────┐
│ Kubernetes  │
└─────────────┘
```

### Triggers

| Event | Backend | Frontend |
|-------|---------|----------|
| Push to `main` | ✅ Build + Deploy | ✅ Build + Deploy |
| Push to `develop` | ✅ Build + Test | ✅ Build + Test |
| Pull Request | ✅ Test only | ✅ Test only |
| Tag `v*` | ✅ Release | ✅ Release |

---

## 🦀 Backend CI/CD (GitHub Actions)

### Workflow 1 : Tests & Build

**Fichier** : `.github/workflows/backend-ci.yml`
```yaml
name: Backend CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'backend/**'
      - '.github/workflows/backend-ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'backend/**'

env:
  CARGO_TERM_COLOR: always
  RUST_BACKTRACE: 1

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: quiz_user
          POSTGRES_PASSWORD: quiz_test
          POSTGRES_DB: quiz_db_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Install Rust
        uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
          profile: minimal
          override: true
          components: rustfmt, clippy
      
      - name: Cache cargo registry
        uses: actions/cache@v3
        with:
          path: ~/.cargo/registry
          key: ${{ runner.os }}-cargo-registry-${{ hashFiles('**/Cargo.lock') }}
      
      - name: Cache cargo index
        uses: actions/cache@v3
        with:
          path: ~/.cargo/git
          key: ${{ runner.os }}-cargo-index-${{ hashFiles('**/Cargo.lock') }}
      
      - name: Cache cargo build
        uses: actions/cache@v3
        with:
          path: backend/target
          key: ${{ runner.os }}-cargo-build-target-${{ hashFiles('**/Cargo.lock') }}
      
      - name: Check formatting
        working-directory: backend/quiz_core_service
        run: cargo fmt -- --check
      
      - name: Run Clippy
        working-directory: backend/quiz_core_service
        run: cargo clippy -- -D warnings
      
      - name: Run migrations
        working-directory: backend/quiz_core_service
        env:
          DATABASE_URL: postgresql://quiz_user:quiz_test@localhost:5432/quiz_db_test
        run: |
          cargo install sqlx-cli --no-default-features --features postgres
          sqlx migrate run
      
      - name: Run tests
        working-directory: backend/quiz_core_service
        env:
          DATABASE_URL: postgresql://quiz_user:quiz_test@localhost:5432/quiz_db_test
          RUST_LOG: debug
        run: cargo test --verbose
      
      - name: Run integration tests
        working-directory: backend/quiz_core_service
        env:
          DATABASE_URL: postgresql://quiz_user:quiz_test@localhost:5432/quiz_db_test
        run: cargo test --test '*' --verbose

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'push'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}/quiz-backend
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: ./backend
          file: ./docker/backend.Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Scan image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ghcr.io/${{ github.repository }}/quiz-backend:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

### Workflow 2 : Déploiement

**Fichier** : `.github/workflows/backend-cd.yml`
```yaml
name: Backend CD

on:
  push:
    branches: [main]
    paths:
      - 'backend/**'
  workflow_dispatch:

jobs:
  deploy:
    name: Deploy to Kubernetes
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
        with:
          version: 'latest'
      
      - name: Configure kubectl
        env:
          KUBE_CONFIG: ${{ secrets.KUBE_CONFIG }}
        run: |
          mkdir -p ~/.kube
          echo "$KUBE_CONFIG" | base64 -d > ~/.kube/config
          chmod 600 ~/.kube/config
      
      - name: Update image in deployment
        run: |
          kubectl set image deployment/quiz-backend \
            quiz-backend=ghcr.io/${{ github.repository }}/quiz-backend:${{ github.sha }} \
            -n quiz-app
      
      - name: Wait for rollout
        run: |
          kubectl rollout status deployment/quiz-backend -n quiz-app --timeout=5m
      
      - name: Verify deployment
        run: |
          kubectl get pods -n quiz-app -l app=quiz-backend
      
      - name: Run health check
        run: |
          POD=$(kubectl get pod -n quiz-app -l app=quiz-backend -o jsonpath="{.items[0].metadata.name}")
          kubectl exec -n quiz-app $POD -- curl -f http://localhost:8080/health || exit 1
      
      - name: Rollback on failure
        if: failure()
        run: |
          kubectl rollout undo deployment/quiz-backend -n quiz-app
          kubectl rollout status deployment/quiz-backend -n quiz-app
```

---

## 📱 Frontend CI/CD (Codemagic)

### Configuration Codemagic

**Fichier** : `codemagic.yaml`
```yaml
workflows:
  # Workflow pour iOS
  ios-workflow:
    name: iOS Build
    max_build_duration: 60
    instance_type: mac_mini_m1
    
    environment:
      groups:
        - app_store_credentials
      vars:
        XCODE_WORKSPACE: "Runner.xcworkspace"
        XCODE_SCHEME: "Runner"
      flutter: stable
      xcode: latest
      cocoapods: default
    
    triggering:
      events:
        - push
      branch_patterns:
        - pattern: 'main'
          include: true
          source: true
        - pattern: 'develop'
          include: true
          source: true
      cancel_previous_builds: true
    
    scripts:
      - name: Set up code signing
        script: |
          keychain initialize
          app-store-connect fetch-signing-files \
            $(xcode-project detect-bundle-id) \
            --type IOS_APP_STORE \
            --create
          keychain add-certificates
          xcode-project use-profiles
      
      - name: Get Flutter packages
        script: |
          cd frontend
          flutter packages pub get
      
      - name: Flutter analyze
        script: |
          cd frontend
          flutter analyze
      
      - name: Run tests
        script: |
          cd frontend
          flutter test
        ignore_failure: false
      
      - name: Build iOS
        script: |
          cd frontend
          flutter build ipa \
            --release \
            --export-options-plist=/Users/builder/export_options.plist
    
    artifacts:
      - frontend/build/ios/ipa/*.ipa
      - frontend/build/ios/archive/Runner.xcarchive
    
    publishing:
      email:
        recipients:
          - ton-email@example.com
        notify:
          success: true
          failure: true
      
      app_store_connect:
        auth: integration
        submit_to_testflight: true
        beta_groups:
          - Internal Testers
        submit_to_app_store: false

  # Workflow pour Android
  android-workflow:
    name: Android Build
    max_build_duration: 60
    instance_type: linux_x2
    
    environment:
      groups:
        - google_play_credentials
      vars:
        PACKAGE_NAME: "com.example.quiz_geo_app"
      flutter: stable
      java: 17
    
    triggering:
      events:
        - push
      branch_patterns:
        - pattern: 'main'
          include: true
          source: true
        - pattern: 'develop'
          include: true
          source: true
      cancel_previous_builds: true
    
    scripts:
      - name: Set up local properties
        script: |
          echo "flutter.sdk=$HOME/programs/flutter" > "$CM_BUILD_DIR/frontend/android/local.properties"
      
      - name: Get Flutter packages
        script: |
          cd frontend
          flutter packages pub get
      
      - name: Flutter analyze
        script: |
          cd frontend
          flutter analyze
      
      - name: Run tests
        script: |
          cd frontend
          flutter test
        ignore_failure: false
      
      - name: Build APK
        script: |
          cd frontend
          flutter build apk --release
      
      - name: Build App Bundle
        script: |
          cd frontend
          flutter build appbundle --release
    
    artifacts:
      - frontend/build/app/outputs/**/*.apk
      - frontend/build/app/outputs/**/*.aab
    
    publishing:
      email:
        recipients:
          - ton-email@example.com
        notify:
          success: true
          failure: true
      
      google_play:
        credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
        track: internal
        submit_as_draft: true
```

---

## 🔐 Secrets & Variables

### GitHub Secrets
```bash
# Accéder aux secrets
GitHub Repository → Settings → Secrets and variables → Actions

# Secrets requis
KUBE_CONFIG          # Config kubectl (base64)
DOCKER_USERNAME      # Docker Hub username
DOCKER_PASSWORD      # Docker Hub token
DATABASE_URL_PROD    # URL PostgreSQL production
JWT_SECRET           # Secret pour JWT
```

### Codemagic Secrets
```bash
# Accéder aux secrets
Codemagic → App → Environment variables

# iOS Secrets
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_PRIVATE_KEY

# Android Secrets
GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
KEYSTORE_PASSWORD
KEY_PASSWORD
```

---

## 🔔 Notifications

### Slack Integration
```yaml
# Ajouter à la fin de backend-ci.yml
- name: Notify Slack on success
  if: success()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "✅ Backend CI passed for ${{ github.ref }}"
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}

- name: Notify Slack on failure
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "❌ Backend CI failed for ${{ github.ref }}"
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## ✅ Best Practices

### 1. Caching

- ✅ Utiliser `actions/cache` pour les dépendances
- ✅ Cache Rust : registry, index, target
- ✅ Cache Flutter : pub cache

### 2. Sécurité

- ✅ Scanner les images avec Trivy
- ✅ Ne jamais commit de secrets
- ✅ Utiliser GitHub Secrets
- ✅ Limiter les permissions des tokens

### 3. Performance

- ✅ Paralléliser les jobs
- ✅ Utiliser Docker layer caching
- ✅ Configurer des timeouts

### 4. Monitoring

- ✅ Notifications Slack/Email
- ✅ Métriques de build dans Grafana
- ✅ Logs centralisés

---

## 🧪 Tests Locaux

### Tester le workflow backend localement
```bash
# Installer act (GitHub Actions local runner)
brew install act

# Lancer le workflow
act -j test -s GITHUB_TOKEN=$GH_TOKEN
```

### Tester Codemagic localement
```bash
# Impossible de lancer Codemagic localement
# Mais on peut tester les commandes Flutter

cd frontend
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

---

## 📚 Ressources

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Codemagic Documentation](https://docs.codemagic.io/)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy)