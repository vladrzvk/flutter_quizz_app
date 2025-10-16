5.1 Structure du Workspace Cargo

backend/
├── Cargo.toml                    # Workspace root
├── .cargo/
│   └── config.toml
├── docker-compose.yml            # Dev local
├── shared/                       # Crate partagé
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── models/               # DTOs communs
│       │   ├── mod.rs
│       │   ├── geojson.rs
│       │   └── pagination.rs
│       ├── errors/               # Gestion d'erreurs commune
│       │   ├── mod.rs
│       │   └── api_error.rs
│       ├── middleware/           # Middleware communs
│       │   ├── mod.rs
│       │   ├── auth.rs
│       │   ├── cors.rs
│       │   └── logging.rs
│       └── utils/                # Utilitaires
│           ├── mod.rs
│           ├── crypto.rs
│           └── validation.rs
│
├── map_service/                  # Service Carte
│   ├── Cargo.toml
│   ├── Dockerfile
│   ├── migrations/               # sqlx migrations
│   │   ├── 001_create_geometries.sql
│   │   ├── 002_create_collections.sql
│   │   └── 003_create_layers.sql
│   └── src/
│       ├── main.rs
│       ├── config.rs             # Configuration
│       ├── models/               # Domain models
│       │   ├── mod.rs
│       │   ├── geometry.rs
│       │   ├── collection.rs
│       │   └── layer.rs
│       ├── repositories/         # Data access
│       │   ├── mod.rs
│       │   ├── geometry_repo.rs
│       │   ├── collection_repo.rs
│       │   └── layer_repo.rs
│       ├── services/             # Business logic
│       │   ├── mod.rs
│       │   ├── spatial_service.rs
│       │   ├── tile_service.rs
│       │   └── collection_service.rs
│       ├── handlers/             # HTTP handlers
│       │   ├── mod.rs
│       │   ├── geometry_handler.rs
│       │   ├── collection_handler.rs
│       │   ├── spatial_handler.rs
│       │   └── tile_handler.rs
│       ├── dto/                  # Data Transfer Objects
│       │   ├── mod.rs
│       │   ├── geometry_dto.rs
│       │   └── collection_dto.rs
│       └── routes.rs             # Route definitions
│
├── geography_service/            # Service Géographie
│   ├── Cargo.toml
│   ├── Dockerfile
│   ├── migrations/
│   │   ├── 001_create_regions.sql
│   │   └── 002_create_translations.sql
│   └── src/
│       ├── main.rs
│       ├── config.rs
│       ├── models/
│       │   ├── mod.rs
│       │   ├── region.rs
│       │   └── translation.rs
│       ├── repositories/
│       │   ├── mod.rs
│       │   └── region_repo.rs
│       ├── services/
│       │   ├── mod.rs
│       │   ├── geography_service.rs
│       │   └── translation_service.rs
│       ├── clients/              # Clients vers autres services
│       │   ├── mod.rs
│       │   └── map_client.rs
│       ├── handlers/
│       │   ├── mod.rs
│       │   └── region_handler.rs
│       ├── dto/
│       │   ├── mod.rs
│       │   └── region_dto.rs
│       └── routes.rs
│
├── quiz_service/                 # Service Quiz
│   ├── Cargo.toml
│   ├── Dockerfile
│   ├── migrations/
│   │   ├── 001_create_quizzes.sql
│   │   ├── 002_create_questions.sql
│   │   ├── 003_create_reponses.sql
│   │   └── 004_create_sessions.sql
│   └── src/
│       ├── main.rs
│       ├── config.rs
│       ├── models/
│       │   ├── mod.rs
│       │   ├── quiz.rs
│       │   ├── question.rs
│       │   ├── reponse.rs
│       │   └── session.rs
│       ├── repositories/
│       │   ├── mod.rs
│       │   ├── quiz_repo.rs
│       │   ├── question_repo.rs
│       │   └── session_repo.rs
│       ├── services/
│       │   ├── mod.rs
│       │   ├── quiz_service.rs
│       │   ├── session_service.rs
│       │   └── validation_service.rs
│       ├── clients/
│       │   ├── mod.rs
│       │   ├── geography_client.rs
│       │   └── map_client.rs
│       ├── handlers/
│       │   ├── mod.rs
│       │   ├── quiz_handler.rs
│       │   └── session_handler.rs
│       ├── dto/
│       │   ├── mod.rs
│       │   ├── quiz_dto.rs
│       │   └── session_dto.rs
│       └── routes.rs
│
└── api_gateway/                  # API Gateway (optionnel si Envoy)
├── Cargo.toml
├── Dockerfile
└── src/
├── main.rs
├── config.rs
├── middleware/
│   ├── mod.rs
│   ├── auth.rs
│   └── rate_limiting.rs
├── proxy/
│   ├── mod.rs
│   └── router.rs
