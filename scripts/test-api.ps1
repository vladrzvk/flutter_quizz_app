Write-Host "🧪 Test API Quiz Geo" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080"

# Test 1: Health Check
Write-Host "1️⃣ Health Check" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/health" -TimeoutSec 5
    Write-Host "   ✅ Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "   Response: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ ERREUR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Vérifications:" -ForegroundColor Yellow
    Write-Host "   - Le conteneur backend est-il lancé ? docker ps" -ForegroundColor Gray
    Write-Host "   - Le backend écoute-t-il sur 0.0.0.0 ? docker logs quiz-backend" -ForegroundColor Gray
    exit 1
}

Write-Host ""

# Test 2: Liste des Quiz
Write-Host "2️⃣ GET /api/v1/quizzes" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/v1/quizzes" -TimeoutSec 5
    Write-Host "   ✅ Status: $($response.StatusCode)" -ForegroundColor Green

    $quizzes = $response.Content | ConvertFrom-Json
    Write-Host "   📊 Nombre de quiz: $($quizzes.Count)" -ForegroundColor Cyan

    foreach ($quiz in $quizzes) {
        Write-Host "      📋 $($quiz.titre)" -ForegroundColor Gray
        Write-Host "         ID: $($quiz.id)" -ForegroundColor DarkGray
        Write-Host "         Questions: $($quiz.nb_questions)" -ForegroundColor DarkGray
        Write-Host ""
    }
} catch {
    Write-Host "   ❌ ERREUR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Questions d'un Quiz
Write-Host "3️⃣ GET /api/v1/quizzes/{id}/questions" -ForegroundColor Yellow
$quizId = "00000000-0000-0000-0000-000000000001"
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/v1/quizzes/$quizId/questions" -TimeoutSec 5
    Write-Host "   ✅ Status: $($response.StatusCode)" -ForegroundColor Green

    $questions = $response.Content | ConvertFrom-Json
    Write-Host "   📊 Nombre de questions: $($questions.Count)" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "   Aperçu des questions:" -ForegroundColor Gray
    $questions | Select-Object -First 3 | ForEach-Object {
        Write-Host "      ❓ $($_.question_data.text)" -ForegroundColor Cyan
        Write-Host "         Points: $($_.points) | Temps: $($_.temps_limite_sec)s" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "   ❌ ERREUR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 4: Démarrer une Session
Write-Host "4️⃣ POST /api/v1/quizzes/{id}/sessions" -ForegroundColor Yellow
try {
    $body = @{
        user_id = "11111111-1111-1111-1111-111111111111"
    } | ConvertTo-Json

    $response = Invoke-WebRequest `
        -Uri "$baseUrl/api/v1/quizzes/$quizId/sessions" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body `
        -TimeoutSec 5

    Write-Host "   ✅ Status: $($response.StatusCode)" -ForegroundColor Green

    $session = $response.Content | ConvertFrom-Json
    Write-Host "   📊 Session créée:" -ForegroundColor Cyan
    Write-Host "      ID: $($session.id)" -ForegroundColor Gray
    Write-Host "      Score: $($session.score)/$($session.score_max)" -ForegroundColor Gray
    Write-Host "      Status: $($session.status)" -ForegroundColor Gray
} catch {
    Write-Host "   ❌ ERREUR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║       ✅ Tests terminés !              ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 URLs disponibles:" -ForegroundColor Cyan
Write-Host "   Health:    http://localhost:8080/health" -ForegroundColor Gray
Write-Host "   Quizzes:   http://localhost:8080/api/v1/quizzes" -ForegroundColor Gray
Write-Host "   Questions: http://localhost:8080/api/v1/quizzes/$quizId/questions" -ForegroundColor Gray