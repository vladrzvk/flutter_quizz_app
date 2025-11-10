FROM rust:1.90-slim as builder

WORKDIR /build

# Dépendances système
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copier fichiers cargo
COPY Cargo.toml Cargo.lock ./

# Créer projet dummy pour cache dépendances
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
RUN rm -rf src

# Copier source réel
COPY src ./src

# Build réel
RUN cargo build --release

# Image finale
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libpq5 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copier binaire
COPY --from=builder /build/target/release/quiz-core-service /app/quiz-core-service

# User non-root
RUN useradd -u 65532 -m appuser
USER 65532

EXPOSE 8080

CMD ["/app/quiz-core-service"]