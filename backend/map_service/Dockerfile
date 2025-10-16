# Build stage
FROM rust:1.75-slim as builder
LABEL authors="Vlad"

WORKDIR /app

# Copier les fichiers de dépendances
COPY Cargo.toml Cargo.lock ./
COPY map_service/Cargo.toml ./map_service/

# Créer un fichier dummy pour pré-compiler les dépendances
RUN mkdir -p map_service/src && \
    echo "fn main() {}" > map_service/src/main.rs && \
    cargo build --release --bin map_service && \
    rm -rf map_service/src

# Copier le vrai code source
COPY map_service/src ./map_service/src

# Build de l'application
RUN cargo build --release --bin map_service

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copier le binaire depuis le builder
COPY --from=builder /app/target/release/map_service /app/map_service

EXPOSE 8082

CMD ["/app/map_service"]