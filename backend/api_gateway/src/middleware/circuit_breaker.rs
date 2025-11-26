use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::RwLock;

#[derive(Clone)]
pub struct CircuitBreaker {
    state: Arc<RwLock<CircuitState>>,
    failure_threshold: u32,
    timeout: Duration,
}

#[derive(Debug)]
struct CircuitState {
    failures: u32,
    last_failure: Option<Instant>,
    is_open: bool,
}

impl CircuitBreaker {
    pub fn new(failure_threshold: u32, timeout_seconds: u64) -> Self {
        Self {
            state: Arc::new(RwLock::new(CircuitState {
                failures: 0,
                last_failure: None,
                is_open: false,
            })),
            failure_threshold,
            timeout: Duration::from_secs(timeout_seconds),
        }
    }

    pub async fn is_open(&self) -> bool {
        let state = self.state.read().await;

        if !state.is_open {
            return false;
        }

        // Vérifier si timeout expiré
        if let Some(last_failure) = state.last_failure {
            if Instant::now().duration_since(last_failure) > self.timeout {
                drop(state);
                self.reset().await;
                return false;
            }
        }

        true
    }

    pub async fn record_success(&self) {
        let mut state = self.state.write().await;
        state.failures = 0;
        state.is_open = false;
    }

    pub async fn record_failure(&self) {
        let mut state = self.state.write().await;
        state.failures += 1;
        state.last_failure = Some(Instant::now());

        if state.failures >= self.failure_threshold {
            state.is_open = true;
            tracing::warn!(
                "Circuit breaker opened after {} failures",
                state.failures
            );
        }
    }

    async fn reset(&self) {
        let mut state = self.state.write().await;
        state.failures = 0;
        state.is_open = false;
        tracing::info!("Circuit breaker reset");
    }
}