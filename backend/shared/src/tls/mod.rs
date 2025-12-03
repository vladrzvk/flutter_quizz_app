// Module principal pour gestion mTLS (mutual TLS)

pub mod config;
pub mod validator;
pub mod client;
pub mod server;

// Re-exports publics
pub use config::{TlsConfig, TlsConfigError};
pub use validator::{CertificateValidator, ValidationError};
pub use client::{create_mtls_client, MtlsClient};
pub use server::{create_mtls_acceptor, MtlsAcceptor};

#[cfg(test)]
mod tests;