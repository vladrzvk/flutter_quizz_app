use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::{User, UserStatus};
use crate::error::AuthError;

pub struct UserRepository;

impl UserRepository {
    /// Créer un utilisateur permanent (avec email/password)
    pub async fn create(
        pool: &PgPool,
        email: &str,
        password_hash: &str,
        display_name: Option<&str>,
        locale: Option<&str>,
        analytics_consent: bool,
        marketing_consent: bool,
    ) -> Result<User, AuthError> {
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO users (
                email, password_hash, status, is_guest,
                display_name, locale, analytics_consent, marketing_consent
            )
            VALUES ($1, $2, 'free', false, $3, $4, $5, $6)
            RETURNING *
            "#,
        )
            .bind(email)
            .bind(password_hash)
            .bind(display_name)
            .bind(locale.unwrap_or("fr"))
            .bind(analytics_consent)
            .bind(marketing_consent)
            .fetch_one(pool)
            .await?;

        Ok(user)
    }

    /// Créer un utilisateur guest (sans email/password)
    pub async fn create_guest(
        pool: &PgPool,
        locale: Option<&str>,
    ) -> Result<User, AuthError> {
        let user = sqlx::query_as::<_, User>(
            r#"
            INSERT INTO users (
                email, password_hash, status, is_guest, locale
            )
            VALUES (NULL, NULL, 'free', true, $1)
            RETURNING *
            "#,
        )
            .bind(locale.unwrap_or("fr"))
            .fetch_one(pool)
            .await?;

        Ok(user)
    }

    /// Trouver un utilisateur par ID
    pub async fn find_by_id(pool: &PgPool, user_id: Uuid) -> Result<User, AuthError> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT * FROM users
            WHERE id = $1 AND deleted_at IS NULL
            "#,
        )
            .bind(user_id)
            .fetch_optional(pool)
            .await?
            .ok_or(AuthError::NotFound)?;

        Ok(user)
    }

    /// Trouver un utilisateur par email
    pub async fn find_by_email(pool: &PgPool, email: &str) -> Result<Option<User>, AuthError> {
        let user = sqlx::query_as::<_, User>(
            r#"
            SELECT * FROM users
            WHERE email = $1 AND deleted_at IS NULL
            "#,
        )
            .bind(email)
            .fetch_optional(pool)
            .await?;

        Ok(user)
    }

    /// Vérifier si un email existe déjà
    pub async fn email_exists(pool: &PgPool, email: &str) -> Result<bool, AuthError> {
        let exists = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM users
                WHERE email = $1 AND deleted_at IS NULL
            )
            "#,
        )
            .bind(email)
            .fetch_one(pool)
            .await?;

        Ok(exists)
    }

    /// ✅ SÉCURITÉ : Mise à jour du profil utilisateur
    /// WHITELIST stricte des champs modifiables
    pub async fn update_profile(
        pool: &PgPool,
        user_id: Uuid,
        display_name: Option<&str>,
        avatar_url: Option<&str>,
        locale: Option<&str>,
        analytics_consent: Option<bool>,
        marketing_consent: Option<bool>,
    ) -> Result<User, AuthError> {
        // Construction dynamique de la requête
        let mut updates = Vec::new();
        let mut param_index = 2;

        let mut query = "UPDATE users SET updated_at = NOW()".to_string();

        if display_name.is_some() {
            updates.push(format!("display_name = ${}", param_index));
            param_index += 1;
        }
        if avatar_url.is_some() {
            updates.push(format!("avatar_url = ${}", param_index));
            param_index += 1;
        }
        if locale.is_some() {
            updates.push(format!("locale = ${}", param_index));
            param_index += 1;
        }
        if analytics_consent.is_some() {
            updates.push(format!("analytics_consent = ${}", param_index));
            param_index += 1;
        }
        if marketing_consent.is_some() {
            updates.push(format!("marketing_consent = ${}", param_index));
            param_index += 1;
        }

        if !updates.is_empty() {
            query.push_str(", ");
            query.push_str(&updates.join(", "));
        }

        query.push_str(" WHERE id = $1 AND deleted_at IS NULL RETURNING *");

        let mut query_builder = sqlx::query_as::<_, User>(&query).bind(user_id);

        if let Some(val) = display_name {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = avatar_url {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = locale {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = analytics_consent {
            query_builder = query_builder.bind(val);
        }
        if let Some(val) = marketing_consent {
            query_builder = query_builder.bind(val);
        }

        let user = query_builder
            .fetch_optional(pool)
            .await?
            .ok_or(AuthError::NotFound)?;

        Ok(user)
    }

    /// ✅ SÉCURITÉ : Changement de mot de passe
    /// Invalide toutes les sessions après changement
    pub async fn update_password(
        pool: &PgPool,
        user_id: Uuid,
        new_password_hash: &str,
    ) -> Result<(), AuthError> {
        let mut tx = pool.begin().await?;

        // 1. Mettre à jour le password
        sqlx::query(
            r#"
            UPDATE users
            SET password_hash = $1, updated_at = NOW()
            WHERE id = $2 AND deleted_at IS NULL
            "#,
        )
            .bind(new_password_hash)
            .bind(user_id)
            .execute(&mut *tx)
            .await?;

        // 2. Révoquer toutes les sessions existantes
        sqlx::query(
            r#"
            UPDATE jwt_sessions
            SET revoked_at = NOW(), revoke_reason = 'password_changed'
            WHERE user_id = $1 AND revoked_at IS NULL
            "#,
        )
            .bind(user_id)
            .execute(&mut *tx)
            .await?;

        tx.commit().await?;

        Ok(())
    }

    /// ✅ SÉCURITÉ : Admin uniquement - Changement de statut
    pub async fn update_status(
        pool: &PgPool,
        user_id: Uuid,
        status: UserStatus,
    ) -> Result<User, AuthError> {
        let user = sqlx::query_as::<_, User>(
            r#"
            UPDATE users
            SET status = $1, updated_at = NOW()
            WHERE id = $2 AND deleted_at IS NULL
            RETURNING *
            "#,
        )
            .bind(status)
            .bind(user_id)
            .fetch_optional(pool)
            .await?
            .ok_or(AuthError::NotFound)?;

        Ok(user)
    }

    /// Mettre à jour last_login_at
    pub async fn update_last_login(pool: &PgPool, user_id: Uuid) -> Result<(), AuthError> {
        sqlx::query(
            r#"
            UPDATE users
            SET last_login_at = NOW(), updated_at = NOW()
            WHERE id = $1
            "#,
        )
            .bind(user_id)
            .execute(pool)
            .await?;

        Ok(())
    }

    /// Soft delete d'un utilisateur
    pub async fn soft_delete(pool: &PgPool, user_id: Uuid) -> Result<(), AuthError> {
        let mut tx = pool.begin().await?;

        // 1. Soft delete user
        sqlx::query(
            r#"
            UPDATE users
            SET deleted_at = NOW(), updated_at = NOW()
            WHERE id = $1 AND deleted_at IS NULL
            "#,
        )
            .bind(user_id)
            .execute(&mut *tx)
            .await?;

        // 2. Révoquer toutes les sessions
        sqlx::query(
            r#"
            UPDATE jwt_sessions
            SET revoked_at = NOW(), revoke_reason = 'user_deleted'
            WHERE user_id = $1 AND revoked_at IS NULL
            "#,
        )
            .bind(user_id)
            .execute(&mut *tx)
            .await?;

        tx.commit().await?;

        Ok(())
    }

    /// Liste paginée des utilisateurs (admin)
    pub async fn list(
        pool: &PgPool,
        offset: i64,
        limit: i64,
        status: Option<UserStatus>,
        is_guest: Option<bool>,
        search: Option<&str>,
    ) -> Result<Vec<User>, AuthError> {
        let mut query = "SELECT * FROM users WHERE deleted_at IS NULL".to_string();
        let mut conditions = Vec::<String>::new();
        if status.is_some() {
            conditions.push("status = $1".parse().unwrap());
        }
        if is_guest.is_some() {
            conditions.push(format!(
                "is_guest = ${}",
                if status.is_some() { 2 } else { 1 }
            ));
        }
        if search.is_some() {
            let param_idx = 1 + conditions.len();
            conditions.push(format!(
                "(email ILIKE ${} OR display_name ILIKE ${})",
                param_idx, param_idx
            ));
        }

        if !conditions.is_empty() {
            query.push_str(" AND ");
            query.push_str(&conditions.join(" AND "));
        }

        query.push_str(" ORDER BY created_at DESC LIMIT $999 OFFSET $998");

        let mut query_builder = sqlx::query_as::<_, User>(&query);

        if let Some(s) = status {
            query_builder = query_builder.bind(s);
        }
        if let Some(g) = is_guest {
            query_builder = query_builder.bind(g);
        }
        if let Some(s) = search {
            let search_pattern = format!("%{}%", s);
            query_builder = query_builder.bind(search_pattern);
        }

        query_builder = query_builder.bind(limit).bind(offset);

        let users = query_builder.fetch_all(pool).await?;

        Ok(users)
    }

    /// Compter le total d'utilisateurs (pour pagination)
    pub async fn count(
        pool: &PgPool,
        status: Option<UserStatus>,
        is_guest: Option<bool>,
        search: Option<&str>,
    ) -> Result<i64, AuthError> {
        let mut query = "SELECT COUNT(*) FROM users WHERE deleted_at IS NULL".to_string();
        let mut conditions = Vec::<String>::new();

        if status.is_some() {
            conditions.push("status = $1".parse().unwrap());
        }
        if is_guest.is_some() {
            conditions.push(format!(
                "is_guest = ${}",
                if status.is_some() { 2 } else { 1 }
            ));
        }
        if search.is_some() {
            let param_idx = 1 + conditions.len();
            conditions.push(format!(
                "(email ILIKE ${} OR display_name ILIKE ${})",
                param_idx, param_idx
            ));
        }

        if !conditions.is_empty() {
            query.push_str(" AND ");
            query.push_str(&conditions.join(" AND "));
        }

        let mut query_builder = sqlx::query_scalar::<_, i64>(&query);

        if let Some(s) = status {
            query_builder = query_builder.bind(s);
        }
        if let Some(g) = is_guest {
            query_builder = query_builder.bind(g);
        }
        if let Some(s) = search {
            let search_pattern = format!("%{}%", s);
            query_builder = query_builder.bind(search_pattern);
        }

        let count = query_builder.fetch_one(pool).await?;

        Ok(count)
    }
}