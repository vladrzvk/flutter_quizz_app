pub mod routes;
pub mod middleware;

// Ré-exports pour faciliter l'usage depuis main.rs
pub use routes::{auth_routes, user_routes, admin_routes, health_routes};
pub use middleware::{
    auth_middleware,
    optional_auth_middleware,
    require_permission,
    AuthContext,
    AppRateLimiter,
    IpRateLimiter
};