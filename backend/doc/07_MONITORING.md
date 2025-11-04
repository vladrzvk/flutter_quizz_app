# 📊 Monitoring & Observabilité

Stratégie de monitoring pour l'application Quiz Géo.

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Metrics (Prometheus)](#metrics-prometheus)
3. [Logs (Loki)](#logs-loki)
4. [Traces (Jaeger)](#traces-jaeger)
5. [Dashboards (Grafana)](#dashboards-grafana)
6. [Alerting](#alerting)
7. [SLOs & SLIs](#slos--slis)

---

## 🎯 Vue d'Ensemble

### Les 3 Piliers de l'Observabilité
```
┌─────────────────────────────────────────────┐
│           OBSERVABILITY                      │
├─────────────────────────────────────────────┤
│                                             │
│  📊 METRICS      📝 LOGS      🔍 TRACES    │
│  (Prometheus)    (Loki)       (Jaeger)     │
│       │            │              │         │
│       └────────────┴──────────────┘         │
│                    │                        │
│              ┌─────▼─────┐                 │
│              │  GRAFANA  │                 │
│              │ (Dashboards)                 │
│              └───────────┘                 │
│                                             │
└─────────────────────────────────────────────┘
```

### Métriques Clés à Surveiller

| Catégorie | Métrique | Seuil Alerte |
|-----------|----------|--------------|
| **Disponibilité** | Uptime | < 99.9% |
| **Performance** | Response time (p95) | > 500ms |
| **Erreurs** | Error rate | > 1% |
| **Infrastructure** | CPU usage | > 80% |
| **Infrastructure** | Memory usage | > 85% |
| **Base de données** | Connection pool | > 80% utilisé |
| **Base de données** | Query time | > 100ms |

---

## 📊 Metrics (Prometheus)

### Installation
```bash
# Via Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values k8s/production/monitoring/prometheus-values.yaml
```

**Fichier** : `k8s/production/monitoring/prometheus-values.yaml`
```yaml
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
    
    # Scrape configs
    additionalScrapeConfigs:
    - job_name: 'quiz-backend'
      kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
          - quiz-app
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: quiz-backend
      - source_labels: [__meta_kubernetes_pod_ip]
        target_label: __address__
        replacement: ${1}:8080

grafana:
  adminPassword: "your-secure-password"
  persistence:
    enabled: true
    size: 10Gi
  
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default

  dashboards:
    default:
      quiz-app-overview:
        url: https://raw.githubusercontent.com/your-repo/dashboards/quiz-app-overview.json
      quiz-app-backend:
        url: https://raw.githubusercontent.com/your-repo/dashboards/quiz-app-backend.json

alertmanager:
  config:
    global:
      slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'slack'
      routes:
      - match:
          severity: critical
        receiver: 'pagerduty'
    
    receivers:
    - name: 'slack'
      slack_configs:
      - channel: '#alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
    
    - name: 'pagerduty'
      pagerduty_configs:
      - service_key: 'your-pagerduty-key'
```

### Métriques Backend (Rust)

**Fichier** : `backend/quiz_core_service/src/monitoring/metrics.rs`
```rust
use prometheus::{
    Counter, Histogram, IntGauge, Registry, Encoder, TextEncoder,
    opts, register_counter_with_registry, register_histogram_with_registry,
    register_int_gauge_with_registry,
};
use lazy_static::lazy_static;

lazy_static! {
    pub static ref REGISTRY: Registry = Registry::new();
    
    // HTTP Metrics
    pub static ref HTTP_REQUESTS_TOTAL: Counter = register_counter_with_registry!(
        opts!("http_requests_total", "Total HTTP requests"),
        REGISTRY
    ).unwrap();
    
    pub static ref HTTP_REQUEST_DURATION: Histogram = register_histogram_with_registry!(
        "http_request_duration_seconds",
        "HTTP request duration in seconds",
        vec![0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0, 5.0],
        REGISTRY
    ).unwrap();
    
    pub static ref HTTP_ERRORS_TOTAL: Counter = register_counter_with_registry!(
        opts!("http_errors_total", "Total HTTP errors"),
        REGISTRY
    ).unwrap();
    
    // Quiz Metrics
    pub static ref QUIZ_SESSIONS_ACTIVE: IntGauge = register_int_gauge_with_registry!(
        opts!("quiz_sessions_active", "Number of active quiz sessions"),
        REGISTRY
    ).unwrap();
    
    pub static ref QUIZ_ANSWERS_SUBMITTED: Counter = register_counter_with_registry!(
        opts!("quiz_answers_submitted_total", "Total quiz answers submitted"),
        REGISTRY
    ).unwrap();
    
    pub static ref QUIZ_ANSWERS_CORRECT: Counter = register_counter_with_registry!(
        opts!("quiz_answers_correct_total", "Total correct quiz answers"),
        REGISTRY
    ).unwrap();
    
    // Database Metrics
    pub static ref DB_CONNECTIONS_ACTIVE: IntGauge = register_int_gauge_with_registry!(
        opts!("db_connections_active", "Number of active database connections"),
        REGISTRY
    ).unwrap();
    
    pub static ref DB_QUERY_DURATION: Histogram = register_histogram_with_registry!(
        "db_query_duration_seconds",
        "Database query duration in seconds",
        vec![0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0],
        REGISTRY
    ).unwrap();
}

pub fn metrics_handler() -> Result<String, Box<dyn std::error::Error>> {
    let encoder = TextEncoder::new();
    let metric_families = REGISTRY.gather();
    let mut buffer = vec![];
    encoder.encode(&metric_families, &mut buffer)?;
    Ok(String::from_utf8(buffer)?)
}
```

**Intégration dans Axum** :
```rust
// backend/quiz_core_service/src/main.rs

use axum::{
    routing::get,
    Router,
};

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/health", get(health_check))
        .route("/metrics", get(metrics_endpoint))  // ← Endpoint Prometheus
        .route("/api/v1/quizzes", get(get_quizzes))
        // ... autres routes
        .layer(middleware::from_fn(track_metrics));  // ← Middleware

    // ...
}

async fn metrics_endpoint() -> String {
    metrics::metrics_handler().unwrap_or_else(|e| {
        eprintln!("Error gathering metrics: {}", e);
        String::new()
    })
}

async fn track_metrics<B>(
    req: Request<B>,
    next: Next<B>,
) -> Response {
    let start = std::time::Instant::now();
    
    // Incrémenter le compteur de requêtes
    metrics::HTTP_REQUESTS_TOTAL.inc();
    
    // Exécuter la requête
    let response = next.run(req).await;
    
    // Enregistrer la durée
    let duration = start.elapsed().as_secs_f64();
    metrics::HTTP_REQUEST_DURATION.observe(duration);
    
    // Compter les erreurs
    if response.status().is_server_error() || response.status().is_client_error() {
        metrics::HTTP_ERRORS_TOTAL.inc();
    }
    
    response
}
```

### Exemples de Requêtes PromQL
```promql
# Taux de requêtes HTTP par seconde
rate(http_requests_total[5m])

# Latence p95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Taux d'erreur
rate(http_errors_total[5m]) / rate(http_requests_total[5m])

# Sessions actives
quiz_sessions_active

# Taux de réussite des quiz
rate(quiz_answers_correct_total[5m]) / rate(quiz_answers_submitted_total[5m])

# Connexions DB
db_connections_active

# Query time p99
histogram_quantile(0.99, rate(db_query_duration_seconds_bucket[5m]))
```

---

## 📝 Logs (Loki)

### Installation
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set promtail.enabled=true \
  --set grafana.enabled=false
```

### Configuration Logging Backend

**Fichier** : `backend/quiz_core_service/src/main.rs`
```rust
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() {
    // Configuration du logging structuré
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "quiz_core_service=info,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer().json()) // Format JSON pour Loki
        .init();

    tracing::info!("Starting Quiz Backend");
    
    // ...
}
```

### Logs Structurés
```rust
use tracing::{info, warn, error};

pub async fn submit_answer(
    State(state): State<Arc<AppState>>,
    Path(session_id): Path<String>,
    Json(answer): Json<SubmitAnswerRequest>,
) -> Result<Json<ReponseUtilisateur>, AppError> {
    // Log structuré
    info!(
        session_id = %session_id,
        question_id = %answer.question_id,
        time_spent = answer.temps_reponse_sec,
        "Submitting answer"
    );
    
    match service::submit_answer(&state.pool, &session_id, answer).await {
        Ok(result) => {
            info!(
                session_id = %session_id,
                is_correct = result.is_correct,
                points = result.points_obtenus,
                "Answer submitted successfully"
            );
            Ok(Json(result))
        }
        Err(e) => {
            error!(
                session_id = %session_id,
                error = %e,
                "Failed to submit answer"
            );
            Err(e)
        }
    }
}
```

### Requêtes LogQL
```logql
# Tous les logs du backend
{app="quiz-backend"}

# Logs d'erreur uniquement
{app="quiz-backend"} |= "error"

# Logs d'une session spécifique
{app="quiz-backend"} | json | session_id="abc-123"

# Compter les erreurs par minute
sum(count_over_time({app="quiz-backend"} |= "error" [1m]))

# Durée moyenne des requêtes
avg(avg_over_time({app="quiz-backend"} | json | unwrap duration [5m]))
```

---

## 🔍 Traces (Jaeger)

### Installation
```bash
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

helm install jaeger jaegertracing/jaeger \
  --namespace monitoring \
  --set collector.service.type=ClusterIP
```

### Configuration Backend (Opentelemetry)

**Fichier** : `backend/quiz_core_service/Cargo.toml`
```toml
[dependencies]
opentelemetry = "0.21"
opentelemetry-jaeger = "0.20"
tracing-opentelemetry = "0.22"
```

**Fichier** : `backend/quiz_core_service/src/tracing.rs`
```rust
use opentelemetry::sdk::trace::TracerProvider;
use opentelemetry_jaeger::JaegerPipeline;
use tracing_subscriber::layer::SubscriberExt;

pub fn init_tracing() -> Result<(), Box<dyn std::error::Error>> {
    let tracer = JaegerPipeline::new()
        .with_service_name("quiz-backend")
        .with_agent_endpoint("jaeger-agent.monitoring.svc.cluster.local:6831")
        .install_batch(opentelemetry::runtime::Tokio)?;

    let telemetry = tracing_opentelemetry::layer().with_tracer(tracer);

    tracing_subscriber::registry()
        .with(telemetry)
        .with(tracing_subscriber::fmt::layer())
        .init();

    Ok(())
}
```

**Usage** :
```rust
use tracing::instrument;

#[instrument(skip(pool))]
pub async fn submit_answer(
    pool: &PgPool,
    session_id: &str,
    answer: SubmitAnswerRequest,
) -> Result<ReponseUtilisateur, AppError> {
    // Le span est automatiquement créé
    // ...
}
```

---

## 📈 Dashboards (Grafana)

### Dashboard "Quiz App Overview"

**Fichier** : `k8s/production/monitoring/dashboards/quiz-app-overview.json`
```json
{
  "dashboard": {
    "title": "Quiz App - Overview",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{app=\"quiz-backend\"}[5m]))"
          }
        ]
      },
      {
        "title": "Response Time (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{app=\"quiz-backend\"}[5m]))"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "sum(rate(http_errors_total{app=\"quiz-backend\"}[5m])) / sum(rate(http_requests_total{app=\"quiz-backend\"}[5m]))"
          }
        ]
      },
      {
        "title": "Active Sessions",
        "targets": [
          {
            "expr": "quiz_sessions_active"
          }
        ]
      }
    ]
  }
}
```

### Accéder à Grafana
```bash
# Port-forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Ouvrir http://localhost:3000
# Login : admin / <password from values.yaml>
```

---

## 🚨 Alerting

### Règles d'Alerte

**Fichier** : `k8s/production/monitoring/alerts/quiz-app-alerts.yaml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alerts
  namespace: monitoring
data:
  quiz-app.rules: |
    groups:
    - name: quiz-app
      interval: 30s
      rules:
      
      # Alerte : Taux d'erreur élevé
      - alert: HighErrorRate
        expr: |
          sum(rate(http_errors_total{app="quiz-backend"}[5m])) 
          / 
          sum(rate(http_requests_total{app="quiz-backend"}[5m])) 
          > 0.05
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Taux d'erreur élevé"
          description: "Le taux d'erreur est de {{ $value | humanizePercentage }}"
      
      # Alerte : Latence élevée
      - alert: HighLatency
        expr: |
          histogram_quantile(0.95, 
            rate(http_request_duration_seconds_bucket{app="quiz-backend"}[5m])
          ) > 0.5
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Latence p95 élevée"
          description: "La latence p95 est de {{ $value }}s"
      
      # Alerte : Service down
      - alert: ServiceDown
        expr: up{app="quiz-backend"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Service quiz-backend down"
          description: "Le service quiz-backend ne répond plus"
      
      # Alerte : CPU élevé
      - alert: HighCPUUsage
        expr: |
          sum(rate(container_cpu_usage_seconds_total{pod=~"quiz-backend-.*"}[5m])) 
          / 
          sum(kube_pod_container_resource_limits{pod=~"quiz-backend-.*",resource="cpu"}) 
          > 0.8
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "CPU usage élevé"
          description: "CPU usage est à {{ $value | humanizePercentage }}"
      
      # Alerte : Mémoire élevée
      - alert: HighMemoryUsage
        expr: |
          sum(container_memory_working_set_bytes{pod=~"quiz-backend-.*"}) 
          / 
          sum(kube_pod_container_resource_limits{pod=~"quiz-backend-.*",resource="memory"}) 
          > 0.85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Memory usage élevé"
          description: "Memory usage est à {{ $value | humanizePercentage }}"
      
      # Alerte : Database slow queries
      - alert: SlowDatabaseQueries
        expr: |
          histogram_quantile(0.99, 
            rate(db_query_duration_seconds_bucket{app="quiz-backend"}[5m])
          ) > 0.1
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Requêtes DB lentes"
          description: "Les requêtes DB p99 sont à {{ $value }}s"
```

---

## 📏 SLOs & SLIs

### Service Level Indicators (SLIs)

| SLI | Métrique | Méthode de mesure |
|-----|----------|-------------------|
| **Disponibilité** | % de requêtes réussies | `(total_requests - errors) / total_requests` |
| **Latence** | p95 response time | Histogram p95 |
| **Durabilité** | % sessions terminées avec succès | `completed_sessions / started_sessions` |

### Service Level Objectives (SLOs)

| SLO | Cible | Budget d'erreur mensuel |
|-----|-------|-------------------------|
| **Disponibilité** | 99.9% | 43 minutes |
| **Latence (p95)** | < 500ms | - |
| **Latence (p99)** | < 1s | - |
| **Taux d'erreur** | < 0.1% | - |

### Calcul du Budget d'Erreur
```promql
# Budget d'erreur restant (en %)
100 - ( sum(rate(http_errors_total{app="quiz-backend"}[30d])) / sum(rate(http_requests_total{app="quiz-backend"}[30d])) * 100 )

# Si SLO = 99.9%, budget d'erreur = 0.1%
# Si actuellement à 99.95%, il reste 50% du budget
```

---

## 📚 Ressources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Loki](https://grafana.com/docs/loki/)
- [Jaeger Tracing](https://www.jaegertracing.io/docs/)
- [SRE Book - Monitoring](https://sre.google/sre-book/monitoring-distributed-systems/)
- [The Four Golden Signals](https://sre.google/sre-book/monitoring-distributed-systems/#xref_monitoring_golden-signals)