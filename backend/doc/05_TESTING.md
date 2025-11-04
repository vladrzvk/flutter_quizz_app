# 🧪 Stratégie de Tests

Guide complet des tests pour l'application Quiz Géo.

## 📋 Table des Matières

1. [Pyramide de Tests](#pyramide-de-tests)
2. [Backend Tests (Rust)](#backend-tests-rust)
3. [Frontend Tests (Flutter)](#frontend-tests-flutter)
4. [Tests d'Intégration](#tests-dintégration)
5. [Tests E2E](#tests-e2e)
6. [Performance Tests](#performance-tests)
7. [CI/CD Integration](#cicd-integration)

---

## 🔺 Pyramide de Tests
```
              ┌───────────┐
              │    E2E    │  ← 5%
              │  (Lent)   │
              └───────────┘
           ┌─────────────────┐
           │   Integration   │  ← 15%
           │   (Moyen)       │
           └─────────────────┘
       ┌───────────────────────────┐
       │        Unit Tests         │  ← 80%
       │        (Rapide)           │
       └───────────────────────────┘
```

### Distribution des Tests

| Type | Proportion | Temps d'exécution | Couverture cible |
|------|-----------|-------------------|------------------|
| **Unit** | 80% | < 1s | 90% |
| **Integration** | 15% | 1-10s | 70% |
| **E2E** | 5% | 10s-1min | 50% |

---

## 🦀 Backend Tests (Rust)

### Structure
```
backend/quiz_core_service/
├── src/
│   └── (code principal)
├── tests/
│   ├── integration/
│   │   ├── quiz_api_test.rs
│   │   ├── session_api_test.rs
│   │   └── plugin_test.rs
│   └── unit/
│       ├── services/
│       │   ├── quiz_service_test.rs
│       │   └── session_service_test.rs
│       └── plugins/
│           └── geography_plugin_test.rs
└── Cargo.toml
```

### Tests Unitaires

#### 1. Tests de Service

**Fichier** : `tests/unit/services/quiz_service_test.rs`
```rust
#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::PgPool;

    // Helper pour setup la DB de test
    async fn setup_test_db() -> PgPool {
        let database_url = std::env::var("DATABASE_URL_TEST")
            .unwrap_or_else(|_| "postgresql://quiz_user:quiz_test@localhost:5432/quiz_db_test".to_string());
        
        let pool = PgPool::connect(&database_url)
            .await
            .expect("Failed to connect to test DB");
        
        // Exécuter les migrations
        sqlx::migrate!("./migrations")
            .run(&pool)
            .await
            .expect("Failed to run migrations");
        
        pool
    }

    // Helper pour cleanup
    async fn cleanup_test_db(pool: &PgPool) {
        sqlx::query("TRUNCATE TABLE quizzes CASCADE")
            .execute(pool)
            .await
            .expect("Failed to cleanup test DB");
    }

    #[tokio::test]
    async fn test_get_all_active_quizzes() {
        // Arrange
        let pool = setup_test_db().await;
        seed_test_data(&pool).await;
        
        // Act
        let result = QuizService::get_all_active(&pool).await;
        
        // Assert
        assert!(result.is_ok());
        let quizzes = result.unwrap();
        assert_eq!(quizzes.len(), 1);
        assert_eq!(quizzes[0].domain, "geography");
        
        // Cleanup
        cleanup_test_db(&pool).await;
    }

    #[tokio::test]
    async fn test_get_quiz_by_id_not_found() {
        let pool = setup_test_db().await;
        
        let quiz_id = Uuid::new_v4();
        let result = QuizService::get_by_id(&pool, &quiz_id).await;
        
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), AppError::NotFound(_)));
        
        cleanup_test_db(&pool).await;
    }

    #[tokio::test]
    async fn test_create_quiz() {
        let pool = setup_test_db().await;
        
        let request = CreateQuizRequest {
            domain: "geography".to_string(),
            titre: "Test Quiz".to_string(),
            niveau_difficulte: "facile".to_string(),
            scope: "france".to_string(),
            mode: "decouverte".to_string(),
            nb_questions: 10,
            temps_limite_sec: None,
        };
        
        let result = QuizService::create(&pool, request).await;
        
        assert!(result.is_ok());
        let quiz = result.unwrap();
        assert_eq!(quiz.titre, "Test Quiz");
        assert!(quiz.is_active);
        
        cleanup_test_db(&pool).await;
    }

    // Helper pour seed
    async fn seed_test_data(pool: &PgPool) {
        sqlx::query(
            "INSERT INTO domains (name, display_name) VALUES ('geography', 'Géographie')"
        )
        .execute(pool)
        .await
        .ok();

        sqlx::query(
            "INSERT INTO quizzes (id, domain, titre, niveau_difficulte, scope, mode, nb_questions, is_active)
             VALUES ($1, 'geography', 'Test', 'facile', 'france', 'decouverte', 10, true)"
        )
        .bind(Uuid::new_v4())
        .execute(pool)
        .await
        .ok();
    }
}
```

#### 2. Tests de Plugin

**Fichier** : `tests/unit/plugins/geography_plugin_test.rs`
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_validate_qcm_correct_answer() {
        let pool = setup_test_db().await;
        let plugin = GeographyPlugin;
        
        // Créer une question de test
        let question = create_test_question(&pool, "qcm").await;
        let correct_answer_id = get_correct_answer_id(&pool, &question.id).await;
        
        let answer = SubmitAnswerRequest {
            question_id: question.id,
            reponse_id: Some(correct_answer_id),
            valeur_saisie: None,
            temps_reponse_sec: 5,
        };
        
        // Act
        let result = plugin.validate_answer(&pool, &question, &answer).await;
        
        // Assert
        assert!(result.is_ok());
        let validation = result.unwrap();
        assert!(validation.is_correct);
        
        cleanup_test_db(&pool).await;
    }

    #[tokio::test]
    async fn test_validate_saisie_texte_case_insensitive() {
        let pool = setup_test_db().await;
        let plugin = GeographyPlugin;
        
        let question = create_test_question(&pool, "saisie_texte").await;
        
        // Test avec différentes casses
        let answers = vec!["seine", "Seine", "SEINE", "la seine"];
        
        for answer_text in answers {
            let answer = SubmitAnswerRequest {
                question_id: question.id,
                reponse_id: None,
                valeur_saisie: Some(answer_text.to_string()),
                temps_reponse_sec: 5,
            };
            
            let result = plugin.validate_answer(&pool, &question, &answer).await;
            
            assert!(result.is_ok());
            assert!(result.unwrap().is_correct, "Failed for: {}", answer_text);
        }
        
        cleanup_test_db(&pool).await;
    }

    #[test]
    fn test_calculate_score_speed_bonus() {
        let plugin = GeographyPlugin;
        
        // Réponse très rapide (3s sur 15s limite = 20% du temps)
        let score = plugin.calculate_score(
            10,    // base_points
            &ValidationResult { is_correct: true, feedback: "Test".to_string() },
            3,     // time_spent
            Some(15), // time_limit
            0,     // no streak
        );
        
        // Devrait avoir un gros bonus vitesse (+50%)
        assert_eq!(score, 15);
    }

    #[test]
    fn test_calculate_score_streak_bonus() {
        let plugin = GeographyPlugin;
        
        let score = plugin.calculate_score(
            10,    // base_points
            &ValidationResult { is_correct: true, feedback: "Test".to_string() },
            8,     // time_spent (normal, pas de bonus vitesse)
            Some(15),
            5,     // 5 bonnes réponses consécutives
        );
        
        // Bonus streak : +25% = 12.5 → arrondi à 13
        assert!(score >= 12 && score <= 13);
    }

    #[test]
    fn test_calculate_score_incorrect_answer() {
        let plugin = GeographyPlugin;
        
        let score = plugin.calculate_score(
            10,
            &ValidationResult { is_correct: false, feedback: "Wrong".to_string() },
            5,
            Some(15),
            0,
        );
        
        // Réponse incorrecte = 0 points
        assert_eq!(score, 0);
    }
}
```

### Tests d'Intégration

**Fichier** : `tests/integration/quiz_api_test.rs`
```rust
use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use tower::ServiceExt;
use serde_json::json;

#[tokio::test]
async fn test_get_quizzes_endpoint() {
    // Setup
    let app = create_test_app().await;
    
    // Act
    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/v1/quizzes")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    
    // Assert
    assert_eq!(response.status(), StatusCode::OK);
    
    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let quizzes: Vec = serde_json::from_slice(&body).unwrap();
    
    assert!(!quizzes.is_empty());
}

#[tokio::test]
async fn test_start_session_endpoint() {
    let app = create_test_app().await;
    
    let quiz_id = "00000000-0000-0000-0000-000000000001";
    let body = json!({
        "user_id": "11111111-1111-1111-1111-111111111111"
    });
    
    let response = app
        .oneshot(
            Request::builder()
                .method("POST")
                .uri(format!("/api/v1/quizzes/{}/sessions", quiz_id))
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&body).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let session: SessionQuiz = serde_json::from_slice(&body).unwrap();
    
    assert_eq!(session.score, 0);
    assert_eq!(session.status, "en_cours");
}

#[tokio::test]
async fn test_submit_answer_qcm() {
    let app = create_test_app().await;
    
    // Démarrer une session
    let session = start_test_session(&app).await;
    
    // Soumettre une réponse
    let body = json!({
        "question_id": "00000000-0000-0000-0001-000000000001",
        "reponse_id": "5e8ca02d-2547-438e-9900-8049b5fceb79",
        "temps_reponse_sec": 5
    });
    
    let response = app
        .oneshot(
            Request::builder()
                .method("POST")
                .uri(format!("/api/v1/sessions/{}/answers", session.id))
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&body).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let answer: ReponseUtilisateur = serde_json::from_slice(&body).unwrap();
    
    assert!(answer.is_correct);
    assert!(answer.points_obtenus > 0);
}

// Helper pour créer l'app de test
async fn create_test_app() -> Router {
    let pool = setup_test_db().await;
    let state = Arc::new(AppState {
        pool,
        plugin_registry: PluginRegistry::new(),
    });
    
    create_router(state)
}
```

### Configuration Tests

**Fichier** : `backend/quiz_core_service/Cargo.toml`
```toml
[dev-dependencies]
tokio-test = "0.4"
mockall = "0.12"
rstest = "0.18"
```

### Lancer les Tests
```bash
# Tous les tests
cargo test

# Tests unitaires seulement
cargo test --lib

# Tests d'intégration seulement
cargo test --test '*'

# Test spécifique
cargo test test_validate_qcm_correct_answer

# Avec logs
RUST_LOG=debug cargo test -- --nocapture

# Coverage
cargo tarpaulin --out Html
```

---

## 📱 Frontend Tests (Flutter)

### Structure
```
frontend/
├── lib/
│   └── (code principal)
├── test/
│   ├── unit/
│   │   ├── models/
│   │   │   └── quiz_model_test.dart
│   │   └── blocs/
│   │       └── quiz_session_bloc_test.dart
│   ├── widget/
│   │   └── quiz_card_test.dart
│   └── fixtures/
│       └── mock_data.dart
└── integration_test/
    ├── app_test.dart
    └── quiz_flow_test.dart
```

### Tests Unitaires

#### 1. Tests de Model

**Fichier** : `test/unit/models/quiz_model_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geo_app/features/quiz/data/models/quiz_model.dart';

void main() {
  group('QuizModel', () {
    test('fromJson should parse JSON correctly', () {
      // Arrange
      final json = {
        'id': '00000000-0000-0000-0000-000000000001',
        'domain': 'geography',
        'titre': 'Test Quiz',
        'description': 'Test description',
        'niveau_difficulte': 'facile',
        'version_app': '1.0.0',
        'scope': 'france',
        'mode': 'decouverte',
        'nb_questions': 10,
        'is_active': true,
        'created_at': '2025-11-01T00:00:00Z',
      };

      // Act
      final quiz = QuizModel.fromJson(json);

      // Assert
      expect(quiz.id, '00000000-0000-0000-0000-000000000001');
      expect(quiz.domain, 'geography');
      expect(quiz.titre, 'Test Quiz');
      expect(quiz.niveauDifficulte, 'facile');
      expect(quiz.nbQuestions, 10);
      expect(quiz.isActive, true);
    });

    test('toJson should serialize correctly', () {
      // Arrange
      const quiz = QuizModel(
        id: '00000000-0000-0000-0000-000000000001',
        domain: 'geography',
        titre: 'Test Quiz',
        niveauDifficulte: 'facile',
        versionApp: '1.0.0',
        scope: 'france',
        mode: 'decouverte',
        nbQuestions: 10,
        isActive: true,
        createdAt: '2025-11-01T00:00:00Z',
      );

      // Act
      final json = quiz.toJson();

      // Assert
      expect(json['domain'], 'geography');
      expect(json['titre'], 'Test Quiz');
    });
  });
}
```

#### 2. Tests de BLoC

**Fichier** : `test/unit/blocs/quiz_session_bloc_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_geo_app/features/quiz/presentation/bloc/quiz_session/quiz_session_bloc.dart';
import 'package:flutter_geo_app/features/quiz/domain/usecases/start_quiz_session.dart';

class MockStartQuizSession extends Mock implements StartQuizSession {}
class MockSubmitAnswer extends Mock implements SubmitAnswer {}

void main() {
  late QuizSessionBloc bloc;
  late MockStartQuizSession mockStartQuizSession;
  late MockSubmitAnswer mockSubmitAnswer;

  setUp(() {
    mockStartQuizSession = MockStartQuizSession();
    mockSubmitAnswer = MockSubmitAnswer();
    bloc = QuizSessionBloc(
      getQuizQuestions: mockGetQuizQuestions,
      startQuizSession: mockStartQuizSession,
      submitAnswer: mockSubmitAnswer,
      finalizeSession: mockFinalizeSession,
      getSession: mockGetSession,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('StartQuizSessionEvent', () {
    blocTest(
      'emits [Loading, InProgress] when session starts successfully',
      build: () {
        when(() => mockGetQuizQuestions(any()))
            .thenAnswer((_) async => Right(mockQuestions));
        when(() => mockStartQuizSession(any()))
            .thenAnswer((_) async => Right(mockSession));
        return bloc;
      },
      act: (bloc) => bloc.add(
        StartQuizSessionEvent(
          quizId: 'quiz-1',
          userId: 'user-1',
        ),
      ),
      expect: () => [
        const QuizSessionLoading(),
        isA()
            .having((s) => s.questions.length, 'questions count', 10)
            .having((s) => s.currentQuestionIndex, 'current index', 0),
      ],
      verify: (_) {
        verify(() => mockGetQuizQuestions(any())).called(1);
        verify(() => mockStartQuizSession(any())).called(1);
      },
    );

    blocTest(
      'emits [Loading, Error] when questions loading fails',
      build: () {
        when(() => mockGetQuizQuestions(any()))
            .thenAnswer((_) async => Left(ServerFailure('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(
        StartQuizSessionEvent(
          quizId: 'quiz-1',
          userId: 'user-1',
        ),
      ),
      expect: () => [
        const QuizSessionLoading(),
        isA()
            .having((s) => s.message, 'message', contains('Error')),
      ],
    );
  });

  group('SubmitAnswerEvent', () {
    blocTest(
      'emits [AnswerSubmitted] when answer is correct',
      build: () {
        when(() => mockSubmitAnswer(any()))
            .thenAnswer((_) async => Right(mockCorrectAnswer));
        return bloc;
      },
      seed: () => QuizSessionInProgress(
        session: mockSession,
        questions: mockQuestions,
        currentQuestionIndex: 0,
        submittedAnswers: const [],
      ),
      act: (bloc) => bloc.add(
        SubmitAnswerEvent(
          questionId: 'question-1',
          answer: 'answer-1',
          timeSpentSeconds: 5,
        ),
      ),
      expect: () => [
        isA()
            .having((s) => s.lastAnswer.isCorrect, 'is correct', true)
            .having((s) => s.lastAnswer.pointsObtenus, 'points', greaterThan(0)),
      ],
    );
  });
}
```

### Tests de Widget

**Fichier** : `test/widget/quiz_card_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_geo_app/features/quiz/presentation/widgets/quiz_card.dart';
import 'package:flutter_geo_app/features/quiz/domain/entities/quiz_entity.dart';

void main() {
  testWidgets('QuizCard displays quiz information', (tester) async {
    // Arrange
    final quiz = QuizEntity(
      id: 'quiz-1',
      domain: 'geography',
      titre: 'Test Quiz',
      description: 'Test description',
      niveauDifficulte: 'facile',
      versionApp: '1.0.0',
      scope: 'france',
      mode: 'decouverte',
      nbQuestions: 10,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizCard(quiz: quiz),
        ),
      ),
    );

    // Assert
    expect(find.text('Test Quiz'), findsOneWidget);
    expect(find.text('Test description'), findsOneWidget);
    expect(find.text('10 questions'), findsOneWidget);
    expect(find.text('🟢'), findsOneWidget); // Emoji difficulté facile
  });

  testWidgets('QuizCard tap triggers callback', (tester) async {
    // Arrange
    bool tapped = false;
    final quiz = createTestQuiz();

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizCard(
            quiz: quiz,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(QuizCard));
    await tester.pumpAndSettle();

    // Assert
    expect(tapped, true);
  });
}
```

### Tests d'Intégration

**Fichier** : `integration_test/quiz_flow_test.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_geo_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Quiz Flow E2E', () {
    testWidgets('Complete quiz session', (tester) async {
      // Lancer l'app
      app.main();
      await tester.pumpAndSettle();

      // 1. Voir la liste des quiz
      expect(find.text('Quiz Disponibles'), findsOneWidget);
      expect(find.byType(QuizCard), findsWidgets);

      // 2. Cliquer sur un quiz
      await tester.tap(find.byType(QuizCard).first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 3. Voir les détails du quiz
      expect(find.text('Commencer'), findsOneWidget);

      // 4. Démarrer le quiz
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 5. Voir la première question
      expect(find.text('Question 1'), findsOneWidget);
      expect(find.byType(AnswerButton), findsWidgets);

      // 6. Sélectionner une réponse
      await tester.tap(find.byType(AnswerButton).first);
      await tester.pumpAndSettle();

      // 7. Valider
      await tester.tap(find.text('Valider'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 8. Voir le feedback
      expect(find.textContaining('points'), findsOneWidget);

      // 9. Passer à la question suivante
      await tester.tap(find.text('Question suivante'));
      await tester.pumpAndSettle();

      // 10. Vérifier qu'on est à la question 2
      expect(find.text('Question 2'), findsOneWidget);
    });

    testWidgets('Answer timeout triggers auto-submit', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Démarrer un quiz
      await tester.tap(find.byType(QuizCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      // Attendre que le timer arrive à 0 (15 secondes)
      await tester.pumpAndSettle(const Duration(seconds: 16));

      // Vérifier qu'on est passé automatiquement au feedback
      expect(find.textContaining('Temps écoulé'), findsOneWidget);
      expect(find.text('0 points'), findsOneWidget);
    });
  });
}
```

### Lancer les Tests
```bash
# Tests unitaires
flutter test

# Test spécifique
flutter test test/unit/models/quiz_model_test.dart

# Tests d'intégration
flutter test integration_test

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🔗 Tests d'Intégration (Backend ↔ Frontend)

### Postman/Newman

**Collection** : `tests/postman/quiz-api.postman_collection.json`
```json
{
  "info": {
    "name": "Quiz API Tests",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Get Quizzes",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test('Status code is 200', function () {",
              "    pm.response.to.have.status(200);",
              "});",
              "",
              "pm.test('Response is an array', function () {",
              "    var jsonData = pm.response.json();",
              "    pm.expect(jsonData).to.be.an('array');",
              "});",
              "",
              "pm.test('Quiz has required fields', function () {",
              "    var jsonData = pm.response.json();",
              "    pm.expect(jsonData[0]).to.have.property('id');",
              "    pm.expect(jsonData[0]).to.have.property('domain');",
              "    pm.expect(jsonData[0]).to.have.property('titre');",
              "});"
            ]
          }
        }
      ],
      "request": {
        "method": "GET",
        "url": "{{baseUrl}}/api/v1/quizzes"
      }
    },
    {
      "name": "Start Session",
      "event": [
        {
          "listen": "test",
          "script": {
            "exec": [
              "pm.test('Status code is 200', function () {",
              "    pm.response.to.have.status(200);",
              "});",
              "",
              "pm.test('Session created with score 0', function () {",
              "    var jsonData = pm.response.json();",
              "    pm.expect(jsonData.score).to.equal(0);",
              "    pm.expect(jsonData.status).to.equal('en_cours');",
              "});",
              "",
              "// Save session ID for next tests",
              "pm.environment.set('sessionId', pm.response.json().id);"
            ]
          }
        }
      ],
      "request": {
        "method": "POST",
        "url": "{{baseUrl}}/api/v1/quizzes/{{quizId}}/sessions",
        "body": {
          "mode": "raw",
          "raw": "{\n  \"user_id\": \"{{userId}}\"\n}",
          "options": {
            "raw": {
              "language": "json"
            }
          }
        }
      }
    }
  ]
}
```

Lancer avec Newman :
```bash
newman run tests/postman/quiz-api.postman_collection.json \
  --environment tests/postman/local.postman_environment.json \
  --reporters cli,html \
  --reporter-html-export newman-report.html
```

---

## ⚡ Performance Tests

### K6 Load Testing

**Fichier** : `tests/performance/load_test.js`
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export const options = {
  stages: [
    { duration: '30s', target: 10 },   // Ramp up to 10 users
    { duration: '1m', target: 50 },    // Ramp up to 50 users
    { duration: '2m', target: 50 },    // Stay at 50 users
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% des requêtes < 500ms
    errors: ['rate<0.1'],              // < 10% erreurs
  },
};

export default function () {
  // 1. Get quizzes
  let res = http.get(`${BASE_URL}/api/v1/quizzes`);
  check(res, {
    'get quizzes status is 200': (r) => r.status === 200,
    'get quizzes response time < 200ms': (r) => r.timings.duration < 200,
  }) || errorRate.add(1);

  sleep(1);

  // 2. Start session
  const quizId = '00000000-0000-0000-0000-000000000001';
  const userId = '11111111-1111-1111-1111-111111111111';
  
  res = http.post(
    `${BASE_URL}/api/v1/quizzes/${quizId}/sessions`,
    JSON.stringify({ user_id: userId }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  
  check(res, {
    'start session status is 200': (r) => r.status === 200,
    'start session response time < 300ms': (r) => r.timings.duration < 300,
  }) || errorRate.add(1);

  const sessionId = JSON.parse(res.body).id;

  sleep(1);

  // 3. Submit answer
  res = http.post(
    `${BASE_URL}/api/v1/sessions/${sessionId}/answers`,
    JSON.stringify({
      question_id: '00000000-0000-0000-0001-000000000001',
      reponse_id: '5e8ca02d-2547-438e-9900-8049b5fceb79',
      temps_reponse_sec: 5,
    }),
    { headers: { 'Content-Type': 'application/json' } }
  );

  check(res, {
    'submit answer status is 200': (r) => r.status === 200,
    'submit answer response time < 200ms': (r) => r.timings.duration < 200,
  }) || errorRate.add(1);

  sleep(1);
}
```

Lancer :
```bash
k6 run tests/performance/load_test.js
```

---

## 🤖 CI/CD Integration

### GitHub Actions - Tests Backend
```yaml
# Dans .github/workflows/backend-ci.yml (déjà créé)
# Section tests déjà présente
```

### GitHub Actions - Tests Frontend
```yaml
name: Frontend Tests

on:
  push:
    branches: [main, develop]
    paths:
      - 'frontend/**'
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'
          channel: 'stable'
      
      - name: Get dependencies
        working-directory: frontend
        run: flutter pub get
      
      - name: Analyze
        working-directory: frontend
        run: flutter analyze
      
      - name: Run tests
        working-directory: frontend
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./frontend/coverage/lcov.info
```

---

## 📊 Coverage Goals

| Composant | Coverage Cible | Actuel |
|-----------|---------------|--------|
| Backend (Rust) | 90% | - |
| Frontend (Flutter) | 80% | - |
| Integration | 70% | - |

---

## 📚 Ressources

- [Rust Testing](https://doc.rust-lang.org/book/ch11-00-testing.html)
- [Flutter Testing](https://docs.flutter.dev/testing)
- [BLoC Testing](https://bloclibrary.dev/#/testing)
- [K6 Documentation](https://k6.io/docs/)
- [Newman CLI](https://learning.postman.com/docs/running-collections/using-newman-cli/command-line-integration-with-newman/)