use std::collections::HashMap;
use std::sync::Arc;

use super::QuizPlugin;

/// Registry centralisé des plugins de domaine
#[derive(Clone)]
pub struct PluginRegistry {
    plugins: HashMap<String, Arc<dyn QuizPlugin>>,
}

impl PluginRegistry {
    /// Créer un nouveau registry vide
    pub fn new() -> Self {
        Self {
            plugins: HashMap::new(),
        }
    }

    /// Enregistrer un plugin
    pub fn register(&mut self, plugin: Arc<dyn QuizPlugin>) {
        let domain = plugin.domain_name().to_string();
        tracing::info!(
            domain = %domain,
            display_name = %plugin.display_name(),
            "Registering quiz plugin"
        );
        self.plugins.insert(domain, plugin);
    }

    /// Récupérer un plugin par nom de domaine
    pub fn get(&self, domain: &str) -> Option<&Arc<dyn QuizPlugin>> {
        self.plugins.get(domain)
    }

    /// Lister tous les domaines enregistrés
    pub fn list_domains(&self) -> Vec<String> {
        self.plugins.keys().cloned().collect()
    }

    /// Nombre de plugins enregistrés
    pub fn count(&self) -> usize {
        self.plugins.len()
    }

    /// Vérifier si un domaine est enregistré
    pub fn has_domain(&self, domain: &str) -> bool {
        self.plugins.contains_key(domain)
    }
}

impl Default for PluginRegistry {
    fn default() -> Self {
        Self::new()
    }
}