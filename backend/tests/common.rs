// backend/quiz_core_service/tests/common.rs
// Initialisation commune pour tous les tests

use std::sync::Once;

static INIT: Once = Once::new();

/// Initialize test environment
///
/// Cette fonction est appelée automatiquement au début de chaque test.
/// Elle charge les variables d'environnement et configure les logs.
pub fn init_test_env() {
    INIT.call_once(|| {
        // Charger .env.test
        dotenv::from_filename(".env.test").ok();

        // Configuration des logs pour les tests
        let _ = tracing_subscriber::fmt()
            .with_test_writer()
            .with_max_level(tracing::Level::DEBUG)
            .try_init();

        println!(" Test environment initialized");
    });
}

/// Helper pour afficher des infos de debug dans les tests
#[allow(dead_code)]
pub fn debug_test(message: &str) {
    println!(" DEBUG: {}", message);
}

/// Helper pour mesurer le temps d'exécution d'un test
#[allow(dead_code)]
pub struct TestTimer {
    name: String,
    start: std::time::Instant,
}

impl TestTimer {
    pub fn new(name: &str) -> Self {
        println!("⏱️  Starting: {}", name);
        Self {
            name: name.to_string(),
            start: std::time::Instant::now(),
        }
    }
}

impl Drop for TestTimer {
    fn drop(&mut self) {
        let elapsed = self.start.elapsed();
        println!("⏱️  {} took {:?}", self.name, elapsed);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_init_env() {
        // Devrait être idempotent (peut être appelé plusieurs fois)
        init_test_env();
        init_test_env();
        init_test_env();
    }

    #[test]
    fn test_timer() {
        let _timer = TestTimer::new("test_timer");
        std::thread::sleep(std::time::Duration::from_millis(10));
        // Timer affichera le temps à la fin
    }
}