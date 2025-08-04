# LiveCaptionsXR Model Upload Script
# Uploads model files to Cloudflare R2 and configures access

param(
    [string]$BucketName = "livecaptionsxr",
    [string]$RemoteName = "livecaptionsxr"
)

Write-Host "🚀 LiveCaptionsXR Model Upload" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green

# Check if rclone is available
try {
    $rcloneVersion = rclone version
    Write-Host "✅ Rclone found" -ForegroundColor Green
} catch {
    Write-Host "❌ Rclone not found. Install with: choco install rclone" -ForegroundColor Red
    exit 1
}

# Define model files to upload
$modelFiles = @(
    @{name="Whisper Base Model"; file="whisper_base.bin"; size="141 MB"},
    @{name="Gemma 3N E2B Model"; file="gemma-3n-E2B-it-int4.task"; size="2.92 GB"},
    @{name="Gemma 3N E4B Model"; file="gemma-3n-E4B-it-int4.task"; size="4.11 GB"}
)

# Upload each model file
foreach ($model in $modelFiles) {
    Write-Host "`n📤 Uploading $($model.name) ($($model.size))..." -ForegroundColor Yellow
    
    $rcloneArgs = @(
        "copy",
        $model.file,
        "$RemoteName`:$BucketName",
        "--progress",
        "--transfers=1",
        "--checkers=1",
        "--retries=3",
        "--retries-sleep=10s"
    )
    
    try {
        rclone @rcloneArgs
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully uploaded $($model.name)" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to upload $($model.name)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Error uploading $($model.name): $_" -ForegroundColor Red
    }
}

Write-Host "`n🎉 Upload process completed!" -ForegroundColor Green

# List uploaded files
Write-Host "`n📋 Files in bucket:" -ForegroundColor Cyan
rclone ls "$RemoteName`:$BucketName" 