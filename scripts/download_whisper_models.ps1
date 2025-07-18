# PowerShell script to download Whisper GGML models
# Run this script from the project root directory

Write-Host "🎤 Downloading Whisper GGML models..." -ForegroundColor Green

# Create models directory if it doesn't exist
$modelsDir = "assets/models"
if (!(Test-Path $modelsDir)) {
    New-Item -ItemType Directory -Path $modelsDir -Force
    Write-Host "📁 Created models directory: $modelsDir" -ForegroundColor Yellow
}

# Define models to download (Hugging Face URLs)
$models = @{
    "whisper_base.bin" = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
    "whisper_small.bin" = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin"
    "whisper_medium.bin" = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin"
    "whisper_large.bin" = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large.bin"
}

# Download each model
foreach ($model in $models.GetEnumerator()) {
    $fileName = $model.Key
    $url = $model.Value
    $filePath = Join-Path $modelsDir $fileName
    
    if (Test-Path $filePath) {
        Write-Host "✅ $fileName already exists, skipping..." -ForegroundColor Green
        continue
    }
    
    Write-Host "📥 Downloading $fileName..." -ForegroundColor Yellow
    Write-Host "   URL: $url" -ForegroundColor Gray
    
    try {
        # Download with progress
        Invoke-WebRequest -Uri $url -OutFile $filePath -UseBasicParsing
        
        # Get file size
        $fileSize = (Get-Item $filePath).Length
        $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
        
        Write-Host "✅ Downloaded $fileName ($fileSizeMB MB)" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to download $fileName`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "🎉 Whisper model download complete!" -ForegroundColor Green
Write-Host "📁 Models are now available in: $modelsDir" -ForegroundColor Cyan

# Show available models
Write-Host "`n📋 Available models:" -ForegroundColor Cyan
Get-ChildItem $modelsDir -Filter "whisper_*.bin" | ForEach-Object {
    $sizeMB = [math]::Round($_.Length / 1MB, 2)
    Write-Host "   - $($_.Name) ($sizeMB MB)" -ForegroundColor White
} 