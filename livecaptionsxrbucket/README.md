# 🚀 LiveCaptionsXR Model Downloads

Complete solution for uploading and downloading AI models from Cloudflare R2 storage.

## 📋 Quick Start

### 1. Upload Models
```powershell
# Upload your model files to R2
.\scripts\upload.ps1
```

### 2. Make Public
```powershell
# Configure and make files publicly accessible
.\scripts\make_public.ps1
```

### 3. Test Downloads
```powershell
# Test if files are accessible
.\scripts\test.ps1
```

## 🔗 Download URLs

| Model | Size | URL |
|-------|------|-----|
| Whisper Base | 141 MB | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin) |
| Gemma 3N E2B | 2.92 GB | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E2B-it-int4.task) |
| Gemma 3N E4B | 4.11 GB | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E4B-it-int4.task) |

## 📱 Flutter Integration

### Add to your app:
```dart
// Navigate to downloads page
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ModelDownloadsPage()),
);

// Check if model is downloaded
final isDownloaded = await ModelDownloadService.isModelDownloaded('whisper_base.bin');
```

### Dependencies:
```yaml
dependencies:
  flutter_bloc: ^8.1.3
  http: ^1.1.0
  path_provider: ^2.1.1
  permission_handler: ^11.0.1
```

## 🌐 Web Download Page

Open `web/download.html` in any browser for a professional download interface.

## 🔧 Curl Commands

### Test downloads:
```bash
curl -I "https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin"
```

### Download files:
```bash
curl -L -o "whisper_base.bin" "https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin"
```

## 📁 Files

- `scripts/` - PowerShell automation scripts
- `flutter/` - Complete Flutter implementation
- `web/` - Web download page
- `docs/` - Setup and troubleshooting guides

## 🎯 Next Steps

1. Enable public access in Cloudflare dashboard
2. Test download URLs
3. Integrate Flutter code into your app
4. Customize UI to match your design

---

**Ready to use! 🎊** 