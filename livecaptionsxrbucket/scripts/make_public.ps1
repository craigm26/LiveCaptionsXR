# LiveCaptionsXR Make Files Public Script
# Configures AWS CLI and makes R2 files publicly accessible

Write-Host "🔓 Making Files Public" -ForegroundColor Green
Write-Host "=====================" -ForegroundColor Green

# Configure AWS CLI for R2
Write-Host "`n⚙️ Configuring AWS CLI for R2..." -ForegroundColor Yellow

try {
    $rcloneConfig = rclone config show livecaptionsxr
    $accessKey = ($rcloneConfig | Select-String "access_key_id = (.+)").Matches.Groups[1].Value
    $secretKey = ($rcloneConfig | Select-String "secret_access_key = (.+)").Matches.Groups[1].Value
    
    aws configure set aws_access_key_id $accessKey
    aws configure set aws_secret_access_key $secretKey
    aws configure set region auto
    aws configure set endpoint_url https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com
    
    Write-Host "✅ AWS CLI configured" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to configure AWS CLI" -ForegroundColor Red
    Write-Host "Please run 'rclone config show livecaptionsxr' and manually enter credentials" -ForegroundColor Yellow
}

# Make files public
Write-Host "`n🌐 Making files publicly accessible..." -ForegroundColor Yellow

$bucketName = "livecaptionsxr"
$endpointUrl = "https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com"

$files = @(
    "whisper_base.bin",
    "gemma-3n-E2B-it-int4.task",
    "gemma-3n-E4B-it-int4.task"
)

foreach ($file in $files) {
    Write-Host "Making $file public..." -ForegroundColor Yellow
    
    $command = "aws s3api put-object-acl --bucket $bucketName --key $file --acl public-read --endpoint-url $endpointUrl"
    
    try {
        Invoke-Expression $command
        Write-Host "✅ Made $file public" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to make $file public" -ForegroundColor Red
    }
}

Write-Host "`n🔗 Public Download URLs:" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan

foreach ($file in $files) {
    $url = "$endpointUrl/$bucketName/$file"
    Write-Host "$file`n  $url" -ForegroundColor Green
    Write-Host ""
}

Write-Host "📝 Note: You may need to enable public access in Cloudflare dashboard" -ForegroundColor Yellow
Write-Host "Go to: R2 → Object Storage → livecaptionsxr → Settings → Public Access" -ForegroundColor Yellow 