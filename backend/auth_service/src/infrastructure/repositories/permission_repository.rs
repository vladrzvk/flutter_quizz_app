use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::{Permission, Role, UserRole};
use crate::error::AuthError;

pub struct PermissionRepository;

impl PermissionRepository {
    /// Créer une nouvelle permission
    pub async fn create(
        pool: &PgPool,
        service: &str,
        action: &str,
        resource: &str,
        name: &str,
        description: Option<&str>,
    ) -> Result<Permission, AuthError> {
        let permission = sqlx::query_as::<_, Permission>(
            r#"
            INSERT INTO permissions (service, action, resource, name, description)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
            "#,
        )
            .bind(service)
            .bind(action)
            .bind(resource)
            .bind(name)
            .bind(description)
            .fetch_one(pool)
            .await?;

        Ok(permission)
    }

    /// Trouver une permission par nom
    pub async fn find_by_name(
        pool: &PgPool,
        name: &str,
    ) -> Result<Option<Permission>, AuthError> {
        let permission = sqlx::query_as::<_, Permission>(
            r#"
            SELECT * FROM permissions WHERE name = $1
            "#,
        )
            .bind(name)
            .fetch_optional(pool)
            .await?;

        Ok(permission)
    }

    /// ✅ SÉCURITÉ : Vérifier si un utilisateur a une permission
    /// Utilise la vue user_effective_permissions pour performance
    pub async fn user_has_permission(
        pool: &PgPool,
        user_id: Uuid,
        permission_name: &str,
    ) -> Result<bool, AuthError> {
        let has_permission = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM user_effective_permissions
                WHERE user_id = $1 AND permission_name = $2
            )
            "#,
        )
            .bind(user_id)
            .bind(permission_name)
            .fetch_one(pool)
            .await?;

        Ok(has_permission)
    }

    /// ✅ SÉCURITÉ : Récupérer toutes les permissions effectives d'un utilisateur
    pub async fn get_user_permissions(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<Vec<String>, AuthError> {
        let permissions = sqlx::query_scalar::<_, String>(
            r#"
            SELECT DISTINCT permission_name
            FROM user_effective_permissions
            WHERE user_id = $1
            ORDER BY permission_name
            "#,
        )
            .bind(user_id)
            .fetch_all(pool)
            .await?;

        Ok(permissions)
    }

    /// Lister toutes les permissions
    pub async fn list_all(pool: &PgPool) -> Result<Vec<Permission>, AuthError> {
        let permissions = sqlx::query_as::<_, Permission>(
            r#"
            SELECT * FROM permissions
            ORDER BY service, action, resource
            "#,
        )
            .fetch_all(pool)
            .await?;

        Ok(permissions)
    }

    /// Lister les permissions d'un rôle
    pub async fn list_role_permissions(
        pool: &PgPool,
        role_id: Uuid,
    ) -> Result<Vec<Permission>, AuthError> {
        let permissions = sqlx::query_as::<_, Permission>(
            r#"
            SELECT p.* FROM permissions p
            INNER JOIN role_permissions rp ON p.id = rp.permission_id
            WHERE rp.role_id = $1
            ORDER BY p.service, p.action, p.resource
            "#,
        )
            .bind(role_id)
            .fetch_all(pool)
            .await?;

        Ok(permissions)
    }

    /// Assigner une permission à un rôle
    pub async fn assign_to_role(
        pool: &PgPool,
        role_id: Uuid,
        permission_id: Uuid,
    ) -> Result<(), AuthError> {
        sqlx::query(
            r#"
            INSERT INTO role_permissions (role_id, permission_id)
            VALUES ($1, $2)
            ON CONFLICT (role_id, permission_id) DO NOTHING
            "#,
        )
            .bind(role_id)
            .bind(permission_id)
            .execute(pool)
            .await?;

        Ok(())
    }

    /// Retirer une permission d'un rôle
    pub async fn remove_from_role(
        pool: &PgPool,
        role_id: Uuid,
        permission_id: Uuid,
    ) -> Result<(), AuthError> {
        sqlx::query(
            r#"
            DELETE FROM role_permissions
            WHERE role_id = $1 AND permission_id = $2
            "#,
        )
            .bind(role_id)
            .bind(permission_id)
            .execute(pool)
            .await?;

        Ok(())
    }
}

pub struct RoleRepository;

impl RoleRepository {
    /// Créer un nouveau rôle
    pub async fn create(
        pool: &PgPool,
        name: &str,
        description: Option<&str>,
        priority: i32,
    ) -> Result<Role, AuthError> {
        let role = sqlx::query_as::<_, Role>(
            r#"
            INSERT INTO roles (name, description, priority, is_system)
            VALUES ($1, $2, $3, false)
            RETURNING *
            "#,
        )
            .bind(name)
            .bind(description)
            .bind(priority)
            .fetch_one(pool)
            .await?;

        Ok(role)
    }

    /// Trouver un rôle par nom
    pub async fn find_by_name(pool: &PgPool, name: &str) -> Result<Option<Role>, AuthError> {
        let role = sqlx::query_as::<_, Role>(
            r#"
            SELECT * FROM roles WHERE name = $1
            "#,
        )
            .bind(name)
            .fetch_optional(pool)
            .await?;

        Ok(role)
    }

    /// Trouver un rôle par ID
    pub async fn find_by_id(pool: &PgPool, role_id: Uuid) -> Result<Role, AuthError> {
        let role = sqlx::query_as::<_, Role>(
            r#"
            SELECT * FROM roles WHERE id = $1
            "#,
        )
            .bind(role_id)
            .fetch_optional(pool)
            .await?
            .ok_or(AuthError::NotFound)?;

        Ok(role)
    }

    /// Lister tous les rôles
    pub async fn list_all(pool: &PgPool) -> Result<Vec<Role>, AuthError> {
        let roles = sqlx::query_as::<_, Role>(
            r#"
            SELECT * FROM roles
            ORDER BY priority DESC, name
            "#,
        )
            .fetch_all(pool)
            .await?;

        Ok(roles)
    }

    /// Lister les rôles d'un utilisateur
    pub async fn list_user_roles(pool: &PgPool, user_id: Uuid) -> Result<Vec<Role>, AuthError> {
        let roles = sqlx::query_as::<_, Role>(
            r#"
            SELECT r.* FROM roles r
            INNER JOIN user_roles ur ON r.id = ur.role_id
            WHERE ur.user_id = $1
              AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
            ORDER BY r.priority DESC
            "#,
        )
            .bind(user_id)
            .fetch_all(pool)
            .await?;

        Ok(roles)
    }

    /// ✅ SÉCURITÉ : Assigner un rôle à un utilisateur
    pub async fn assign_to_user(
        pool: &PgPool,
        user_id: Uuid,
        role_id: Uuid,
        granted_by: Option<Uuid>,
        expires_at: Option<chrono::DateTime<chrono::Utc>>,
    ) -> Result<(), AuthError> {
        sqlx::query(
            r#"
            INSERT INTO user_roles (user_id, role_id, granted_by, expires_at)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (user_id, role_id) DO UPDATE
            SET expires_at = EXCLUDED.expires_at,
                granted_by = EXCLUDED.granted_by,
                granted_at = NOW()
            "#,
        )
            .bind(user_id)
            .bind(role_id)
            .bind(granted_by)
            .bind(expires_at)
            .execute(pool)
            .await?;

        Ok(())
    }

    /// Retirer un rôle d'un utilisateur
    pub async fn remove_from_user(
        pool: &PgPool,
        user_id: Uuid,
        role_id: Uuid,
    ) -> Result<(), AuthError> {
        sqlx::query(
            r#"
            DELETE FROM user_roles
            WHERE user_id = $1 AND role_id = $2
            "#,
        )
            .bind(user_id)
            .bind(role_id)
            .execute(pool)
            .await?;

        Ok(())
    }

    /// Supprimer un rôle (sauf système)
    pub async fn delete(pool: &PgPool, role_id: Uuid) -> Result<(), AuthError> {
        let result = sqlx::query(
            r#"
            DELETE FROM roles
            WHERE id = $1 AND is_system = false
            "#,
        )
            .bind(role_id)
            .execute(pool)
            .await?;

        if result.rows_affected() == 0 {
            return Err(AuthError::NotFound);
        }

        Ok(())
    }
}