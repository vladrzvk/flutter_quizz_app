# ============================================
# Stage 1: Planner
# ============================================
FROM rust:1.90-slim AS planner

WORKDIR /app
RUN cargo install cargo-chef

COPY backend/Cargo.toml backend/Cargo.lock ./
COPY backend/quiz_core_service ./quiz_core_service
# ajouter les autres services ici
COPY backend/shared ./shared
COPY backend/auth_service ./auth_service
COPY backend/api_gateway ./api_gateway

RUN cargo chef prepare --recipe-path recipe.json --bin quiz_core_service

# ============================================
# Stage 2: Cacher
# ============================================
FROM rust:1.90-slim AS cacher

WORKDIR /app
RUN cargo install cargo-chef

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json --bin quiz_core_service

# ============================================
# Stage 3: Builder
# ============================================
FROM rust:1.90-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copier les dépendances compilées
COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo


# Copier le workspace
COPY backend/Cargo.toml backend/Cargo.lock ./
COPY backend/quiz_core_service ./quiz_core_service
# ajouter les autres services ici aussi
COPY backend/shared ./shared
COPY backend/auth_service ./auth_service
COPY backend/api_gateway ./api_gateway

# Build le code applicatif
RUN cargo build --release --bin quiz_core_service

# ============================================
# Stage 4: Runtime
# ============================================
FROM debian:trixie-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libc6 \
    libpq5 \
    libssl3 \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copier depuis le bon emplacement
COPY --from=builder /app/target/release/quiz_core_service /app/quiz_core_service

# User non-root
RUN useradd -u 65532 -m appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 8080
# Exécuter le binaire
ENTRYPOINT ["/app/quiz_core_service"]