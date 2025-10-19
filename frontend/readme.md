
┌─────────────────────────────────────────────────────────────┐
│                    CLEAN ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  API (JSON)                                                 │
│      ↓                                                      │
│  Model (Freezed + JSON)  ← Data Layer                       │
│      ↓ toEntity()                                           │
│  Entity (Equatable)      ← Domain Layer (logique métier)    │
│      ↓ used by                                              │
│  UseCase                 ← Domain Layer                     │
│      ↓ returns                                              │
│  BLoC / State            ← Presentation Layer               │
│      ↓                                                      │
│  UI (Widget)             ← Presentation Layer               │
│                                                             │
└─────────────────────────────────────────────────────────────┘



frontend/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── config/
│   │   │   └── api_config.dart          # URLs des services
│   │   ├── network/
│   │   │   ├── dio_client.dart          # Client HTTP configuré
│   │   │   └── api_exception.dart       # Gestion erreurs
│   │   ├── router/
│   │   │   └── app_router.dart          # Routes de l'app
│   │   └── theme/
│   │       └── app_theme.dart           # Thème Material 3
│   │
│   ├── features/
│   │   │
│   │   ├── quiz/
│   │   │   ├── data/
│   │   │   │   ├── models/              # Quiz, Question, Session
│   │   │   │   ├── repositories/
│   │   │   │   └── datasources/         # API calls
│   │   │   ├── domain/
│   │   │   │   └── entities/            # Business objects
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── quiz_list_screen.dart
│   │   │       │   ├── quiz_play_screen.dart
│   │   │       │   └── quiz_result_screen.dart
│   │   │       ├── widgets/
│   │   │       └── providers/           # Riverpod providers
│   │   │
│   │   └── home/
│   │       └── presentation/
│   │           └── screens/
│   │               └── home_screen.dart
│   │
│   └── shared/
│       ├── widgets/                     # Widgets réutilisables
│       └── utils/                       # Helpers
│
└── pubspec.yaml






Points d'attention
Web :

Choisis le renderer : --web-renderer canvaskit (meilleur qualité) ou html (plus léger)
Configure web/index.html pour le SEO/PWA si besoin

iOS :

Nécessite Xcode et un Mac pour build
Configure les permissions dans ios/Runner/Info.plist

Android :

Configure les permissions dans android/app/src/main/AndroidManifest.xml
Génère un keystore pour la signature : keytool -genkey -v -keystore ~/key.jks