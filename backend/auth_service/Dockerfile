# ============================================
# Stage 1: Planner
# ============================================
FROM rust:1.90-slim AS planner

WORKDIR /app
RUN cargo install cargo-chef

# Copier le workspace complet
COPY backend/Cargo.toml backend/Cargo.lock ./
COPY backend/auth_service ./auth_service
COPY backend/api_gateway ./api_gateway
COPY backend/shared ./shared
COPY backend/quiz_core_service ./quiz_core_service

# Analyser les dépendances pour api_gateway
RUN cargo chef prepare --recipe-path recipe.json --bin auth_service

# ============================================
# Stage 2: Cacher
# ============================================
FROM rust:1.90-slim AS cacher

WORKDIR /app
RUN cargo install cargo-chef

# Installer dépendances système
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=planner /app/recipe.json recipe.json

# Build UNIQUEMENT les dépendances
RUN cargo chef cook --release --recipe-path recipe.json --bin auth_service

# ============================================
# Stage 3: Builder
# ============================================
FROM rust:1.90-slim AS builder

WORKDIR /app

# Installer dépendances système
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copier les dépendances compilées
COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usr/local/cargo

# Copier le workspace
COPY backend/Cargo.toml backend/Cargo.lock ./
COPY backend/auth_service ./auth_service
COPY backend/shared ./shared
COPY backend/api_gateway ./api_gateway
COPY backend/quiz_core_service ./quiz_core_service

# Build le code applicatif
RUN cargo build --release --bin auth_service

# ============================================
# Stage 4: Runtime
# ============================================
FROM debian:trixie-slim

WORKDIR /app

# Installer runtime dependencies
RUN apt-get update && apt-get install -y \
    libc6 \
    ca-certificates \
    libssl3 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copier binaire
COPY --from=builder /app/target/release/auth_service /app/auth_service

# User non-root
RUN useradd -u 65532 -m appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

CMD ["/app/auth_service"]