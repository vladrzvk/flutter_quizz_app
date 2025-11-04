FROM rust:1.90-slim

# Installer les dépendances système
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Installer cargo-watch pour hot reload
RUN cargo install cargo-watch

# Installer SQLx CLI
RUN cargo install sqlx-cli --no-default-features --features postgres

WORKDIR /app

EXPOSE 8080

# Le code sera monté via volume
# Lancer cargo watch depuis quiz_core_service
CMD ["bash", "-c", "cd quiz_core_service && cargo watch -x run"]