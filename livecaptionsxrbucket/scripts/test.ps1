# LiveCaptionsXR Test Downloads Script
# Tests if model files are publicly accessible

Write-Host "🧪 Testing Model Downloads" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

$baseUrl = "https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr"

$files = @(
    @{name="Whisper Base Model"; file="whisper_base.bin"; size="141 MB"},
    @{name="Gemma 3N E2B Model"; file="gemma-3n-E2B-it-int4.task"; size="2.92 GB"},
    @{name="Gemma 3N E4B Model"; file="gemma-3n-E4B-it-int4.task"; size="4.11 GB"}
)

Write-Host "`n🔗 Download URLs:" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan

foreach ($model in $files) {
    $url = "$baseUrl/$($model.file)"
    Write-Host "`n📁 $($model.name) ($($model.size))" -ForegroundColor Yellow
    Write-Host "Test: curl -I `"$url`"" -ForegroundColor White
    Write-Host "Download: curl -L -o `"$($model.file)`" `"$url`"" -ForegroundColor White
}

Write-Host "`n`n🧪 Testing Head Requests:" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan

foreach ($model in $files) {
    $url = "$baseUrl/$($model.file)"
    Write-Host "`nTesting $($model.name)..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ $($model.name) is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
        } else {
            Write-Host "❌ $($model.name) returned status: $($response.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ $($model.name) failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n`n📋 Quick Commands:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan

foreach ($model in $files) {
    $url = "$baseUrl/$($model.file)"
    Write-Host "`n# Test $($model.name)" -ForegroundColor Yellow
    Write-Host "curl -I `"$url`"" -ForegroundColor White
} 