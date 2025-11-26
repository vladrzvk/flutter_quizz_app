# INSTRUCTIONS:
# 1. Copier ce fichier vers backend/<service_name>/Dockerfile
# 2. Remplacer <SERVICE_NAME> par le nom du service (ex: auth_service)
# 3. Ajuster les dépendances système si nécessaire
# 4. Ajouter migrations/scripts si nécessaire

# ============================================
# Stage 1: Planner
# ============================================
FROM rust:1.90-slim AS planner
WORKDIR /app
RUN cargo install cargo-chef

COPY backend/Cargo.toml backend/Cargo.lock ./
COPY backend/<SERVICE_NAME> ./<SERVICE_NAME>
COPY backend/shared ./shared
# Copier autres membres du workspace si nécessaire

RUN cargo chef prepare --recipe-path recipe.json --bin <SERVICE_NAME>

# ============================================
# Stage 2: Cacher
# ============================================
FROM rust:1.90-slim AS cacher
WORKDIR /app
RUN cargo install cargo-chef

# Dépendances système (ajuster selon besoin)
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json --bin <SERVICE_NAME>

# ============================================
# Stage 3: Builder
# ============================================
FROM rust:1.90-slim AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo

COPY backend/Cargo.toml backend/Cargo.lock ./
COPY backend/<SERVICE_NAME> ./<SERVICE_NAME>
COPY backend/shared ./shared

RUN cargo build --release --bin <SERVICE_NAME>

# ============================================
# Stage 4: Runtime
# ============================================
FROM debian:bookworm-slim
WORKDIR /app

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/<SERVICE_NAME> /app/<SERVICE_NAME>

RUN useradd -u 65532 -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE <PORT>
CMD ["/app/<SERVICE_NAME>"]
