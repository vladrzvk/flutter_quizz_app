# test-quiz-api.ps1
param([string]$BaseUrl = "http://localhost:8080")

function Test-QuizAPI {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   TEST API QUIZ SERVICE - V0           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Cyan

    try {
        # Health Check
        Write-Host "→ Health check..." -ForegroundColor Yellow
        $health = Invoke-WebRequest -Uri "$BaseUrl/health" -Method GET
        $healthData = $health.Content | ConvertFrom-Json
        Write-Host "  ✓ $($healthData.service) is $($healthData.status)" -ForegroundColor Green

        # Create Quiz
        Write-Host "`n→ Création d'un quiz..." -ForegroundColor Yellow
        $quiz = @{
            titre = "Quiz Test - $(Get-Date -Format 'HH:mm:ss')"
            description = "Test automatique"
            niveau_difficulte = "facile"
            version_app = "v0"
            region_scope = "france"
            mode = "texte"
            nb_questions = 2
        } | ConvertTo-Json

        $quizResp = Invoke-WebRequest -Uri "$BaseUrl/api/v1/quizzes" -Method POST -ContentType "application/json" -Body $quiz
        $quizData = $quizResp.Content | ConvertFrom-Json
        Write-Host "  ✓ Quiz créé: $($quizData.id)" -ForegroundColor Green

        # Add Questions
        Write-Host "`n→ Ajout de 2 questions..." -ForegroundColor Yellow
        $questions = @(
            @{
                quiz_id = $quizData.id
                ordre = 1
                type_question = "choix_multiple"
                question_data = @{ text = "Test Q1" }
                points = 10
            },
            @{
                quiz_id = $quizData.id
                ordre = 2
                type_question = "choix_multiple"
                question_data = @{ text = "Test Q2" }
                points = 15
            }
        )

        $questionIds = @()
        foreach ($q in $questions) {
            $qResp = Invoke-WebRequest -Uri "$BaseUrl/api/v1/questions" -Method POST -ContentType "application/json" -Body ($q | ConvertTo-Json -Depth 10)
            $qData = $qResp.Content | ConvertFrom-Json
            $questionIds += $qData.id
        }
        Write-Host "  ✓ Questions créées: $($questionIds.Count)" -ForegroundColor Green

        # Start Session
        Write-Host "`n→ Démarrage d'une session..." -ForegroundColor Yellow
        $sessionBody = @{ user_id = [Guid]::NewGuid().ToString() } | ConvertTo-Json
        $sessionResp = Invoke-WebRequest -Uri "$BaseUrl/api/v1/quizzes/$($quizData.id)/sessions" -Method POST -ContentType "application/json" -Body $sessionBody
        $sessionData = $sessionResp.Content | ConvertFrom-Json
        Write-Host "  ✓ Session: $($sessionData.id)" -ForegroundColor Green
        Write-Host "    Score max: $($sessionData.score_max)" -ForegroundColor Gray

        # Submit Answers
        Write-Host "`n→ Soumission des réponses..." -ForegroundColor Yellow
        foreach ($qId in $questionIds) {
            $answerBody = @{
                question_id = $qId
                valeur_saisie = "Test Answer"
                temps_reponse_sec = Get-Random -Minimum 5 -Maximum 20
            } | ConvertTo-Json

            $answerResp = Invoke-WebRequest -Uri "$BaseUrl/api/v1/sessions/$($sessionData.id)/answers" -Method POST -ContentType "application/json" -Body $answerBody
            $answerData = $answerResp.Content | ConvertFrom-Json
            Write-Host "  ✓ Réponse soumise - Points: $($answerData.points_obtenus)" -ForegroundColor Green
        }

        # Finalize
        Write-Host "`n→ Finalisation..." -ForegroundColor Yellow
        $finalResp = Invoke-WebRequest -Uri "$BaseUrl/api/v1/sessions/$($sessionData.id)/finalize" -Method POST
        $finalData = $finalResp.Content | ConvertFrom-Json
        Write-Host "  ✓ Session finalisée" -ForegroundColor Green
        Write-Host "    Score: $($finalData.score)/$($finalData.score_max)" -ForegroundColor Gray
        Write-Host "    Pourcentage: $($finalData.pourcentage)%" -ForegroundColor Gray

        Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║       ✓ TOUS LES TESTS RÉUSSIS        ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Green

        return $true
    }
    catch {
        Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║         ✗ ERREUR DÉTECTÉE              ║" -ForegroundColor Red
        Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Red
        Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Test-QuizAPI
