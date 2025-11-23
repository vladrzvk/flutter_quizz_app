# scripts/format-all.ps1
# Script pour formater tout le code (Rust + Flutter)
# Version Windows PowerShell

Write-Host " Formatage du code..." -ForegroundColor Cyan
Write-Host ""

# ========================================
# 1. Format Rust
# ========================================
Write-Host " Formatage Rust..." -ForegroundColor Yellow
Push-Location backend\quiz_core_service
cargo fmt
if ($LASTEXITCODE -eq 0) {
    Write-Host " Rust formaté" -ForegroundColor Green
} else {
    Write-Host " Erreur formatage Rust" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
Write-Host ""

# ========================================
# 2. Format Flutter
# ========================================
Write-Host " Formatage Flutter..." -ForegroundColor Yellow
Push-Location frontend
dart format .
if ($LASTEXITCODE -eq 0) {
    Write-Host " Flutter formaté" -ForegroundColor Green
} else {
    Write-Host " Erreur formatage Flutter" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
Write-Host ""

# ========================================
# 3. Fin
# ========================================
Write-Host " Tout le code est formaté !" -ForegroundColor Green
Write-Host ""
Write-Host " Prochaines étapes :" -ForegroundColor Cyan
Write-Host "  1. Vérifier les changements : git status"
Write-Host "  2. Ajouter les fichiers : git add ."
Write-Host "  3. Commiter : git commit -m 'chore: format code'"
Write-Host ""