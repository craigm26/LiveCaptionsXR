# 🚀 LiveCaptionsXR R2 Setup Guide

Complete guide for uploading and managing AI models on Cloudflare R2.

## 📋 Prerequisites

- Cloudflare account with R2 enabled
- R2 bucket: `livecaptionsxr`
- R2 API credentials (Access Key ID, Secret Access Key)
- rclone installed: `choco install rclone`
- AWS CLI installed: `choco install awscli`

## 🔧 Setup Steps

### 1. Configure rclone
```powershell
rclone config
# Create new remote: livecaptionsxr
# Type: s3
# Provider: Cloudflare
# Endpoint: https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com
```

### 2. Upload Models
```powershell
.\scripts\upload.ps1
```

### 3. Make Files Public
```powershell
.\scripts\make_public.ps1
```

### 4. Test Downloads
```powershell
.\scripts\test.ps1
```

## 🔗 Download URLs

| Model | Size | URL |
|-------|------|-----|
| Whisper Base | 141 MB | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin) |
| Gemma 3N E2B | 2.92 GB | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E2B-it-int4.task) |
| Gemma 3N E4B | 4.11 GB | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E4B-it-int4.task) |

## 📱 Flutter Integration

### Dependencies
```yaml
dependencies:
  flutter_bloc: ^8.1.3
  http: ^1.1.0
  path_provider: ^2.1.1
  permission_handler: ^11.0.1
```

### Usage
```dart
// Navigate to downloads page
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ModelDownloadsPage()),
);

// Check if model is downloaded
final isDownloaded = await ModelDownloadService.isModelDownloaded('whisper_base.bin');
```

## 🔧 Curl Commands

### Test downloads:
```bash
curl -I "https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin"
```

### Download files:
```bash
curl -L -o "whisper_base.bin" "https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin"
```

## 🌐 Web Download Page

Open `web/download.html` in any browser for a professional download interface.

## 🚨 Troubleshooting

### Files return 403 Forbidden
1. Enable public access in Cloudflare dashboard
2. Go to R2 → Object Storage → livecaptionsxr → Settings → Public Access
3. Enable "Public Bucket"

### Files return 404 Not Found
1. Verify file names match exactly (case-sensitive)
2. Check bucket name is correct
3. Ensure files were uploaded successfully

### Upload fails
1. Check rclone configuration
2. Verify R2 credentials
3. Ensure sufficient storage space

## 📞 Support

- Check Cloudflare R2 documentation
- Review rclone configuration
- Test with provided scripts 