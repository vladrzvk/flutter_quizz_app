mod plugin_trait;
mod registry;
mod geography;

pub use plugin_trait::{QuizPlugin, ValidationResult};
pub use registry::PluginRegistry;
pub use geography::GeographyPlugin;