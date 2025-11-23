# ============================================
# Stage 1: Builder
# ============================================
FROM rust:1.90-slim AS builder

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Installer SQLx CLI
RUN cargo install sqlx-cli --no-default-features --features postgres,rustls

WORKDIR /app

# Copier les fichiers de configuration du workspace
COPY backend/Cargo.toml backend/Cargo.lock ./

# Créer la structure des crates et copier leurs Cargo.toml
COPY backend/quiz_core_service/Cargo.toml ./quiz_core_service/
COPY backend/shared/Cargo.toml ./shared/

# Créer des fichiers src fictifs pour le cache des dépendances
RUN mkdir -p quiz_core_service/src && \
    mkdir -p shared/src


# Maintenant copier le vrai code source
COPY backend/quiz_core_service ./quiz_core_service
COPY backend/shared ./shared

# Re-build avec le vrai code
RUN cargo build --release

# ============================================
# Stage 2: Runtime (CORRIGÉ)
# ============================================
FROM debian:bookworm-slim

# ✅ INSTALLER LES DÉPENDANCES RUNTIME
RUN apt-get update && apt-get install -y \
    libpq5 \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copier le binaire
COPY --from=builder /app/target/release/quiz_core_service /app/quiz_core_service

# Copier les migrations
COPY --from=builder /app/quiz_core_service/migrations /app/migrations

# User non-root
RUN useradd -u 65532 -m appuser
USER appuser

EXPOSE 8080

# Exécuter le binaire
ENTRYPOINT ["/app/quiz_core_service"]