# Dockerfile pour le développement local
FROM rust:1.75-slim

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Installer cargo-watch pour hot reload
RUN cargo install cargo-watch

WORKDIR /app

# Le code sera monté via volume
EXPOSE 8080

CMD ["cargo", "watch", "-x", "run"]