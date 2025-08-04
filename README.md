# 🚀 LiveCaptionsXR Model Downloads & R2 Integration

This folder contains everything you need to upload, manage, and download AI models from Cloudflare R2 storage for the LiveCaptionsXR project.

## 📁 Folder Structure

```
livecaptionsxrbucket/
├── scripts/                    # PowerShell scripts for R2 management
├── docs/                       # Documentation and setup guides
├── flutter_examples/           # Complete Flutter implementation
└── web_assets/                 # Web-based download page
```

## 🎯 Quick Start

### 1. Upload Models to R2
```powershell
# Run the upload script
.\scripts\upload_models_to_r2.ps1
```

### 2. Make Files Public
```powershell
# Configure AWS CLI for R2
.\scripts\configure_aws_cli_for_r2.ps1

# Make files publicly accessible
.\scripts\make_all_files_public.ps1
```

### 3. Test Downloads
```powershell
# Test if files are accessible
.\scripts\test_downloads.ps1
```

## 📱 Flutter Integration

### Complete Model Downloads Feature
The `flutter_examples/` folder contains a full Flutter implementation with:

- ✅ Real-time download progress
- ✅ Download management (start/cancel/delete)
- ✅ Storage management
- ✅ Beautiful Material Design UI
- ✅ Error handling
- ✅ Cross-platform support

### Quick Integration
```dart
// Add to your app
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ModelDownloadsPage(),
  ),
);
```

## 🌐 Web Download Page

The `web_assets/model_downloads.html` provides a professional download page for web users.

## 📋 Available Models

| Model | Size | URL |
|-------|------|-----|
| Whisper Base | 141 MB | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin) |
| Gemma 3N E2B | 2.92 GB | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E2B-it-int4.task) |
| Gemma 3N E4B | 4.11 GB | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E4B-it-int4.task) |

## 🔧 Scripts Overview

### Upload Scripts
- `upload_models_to_r2.ps1` - Upload model files to R2
- `configure_aws_cli_for_r2.ps1` - Configure AWS CLI for R2 access
- `rclone_config_template.txt` - Rclone configuration template

### Management Scripts
- `make_files_public.ps1` - Make files publicly accessible
- `make_all_files_public.ps1` - Make all model files public
- `test_downloads.ps1` - Test download URLs

## 📚 Documentation

### Setup Guides
- `R2_UPLOAD_SETUP.md` - Complete R2 upload setup
- `PUBLIC_ACCESS_SETUP.md` - Making files publicly accessible
- `FINAL_DOWNLOAD_URLS.md` - Final download URLs and status
- `DOWNLOAD_COMMANDS_AND_FLUTTER_EXAMPLES.md` - Curl commands and Flutter examples

## 🚀 Features

### ✅ Upload Management
- Automated model uploads to R2
- Progress tracking and error handling
- Support for large files (3GB+)

### ✅ Download System
- Multiple download methods (curl, Flutter, web)
- Progress tracking and resume capability
- Storage management and permissions

### ✅ User Experience
- Professional UI for both mobile and web
- Download confirmation for large files
- Error handling and user feedback

### ✅ Cross-Platform
- PowerShell scripts for Windows
- Flutter implementation for mobile
- Web-based download page
- Curl commands for any platform

## 🔗 Quick Commands

### Test Downloads
```bash
# Test Whisper model
curl -I "https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin"

# Download Whisper model
curl -L -o "whisper_base.bin" "https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin"
```

### Flutter Usage
```dart
// Check if model is downloaded
final isDownloaded = await ModelDownloadService.isModelDownloaded('whisper_base.bin');

// Get model path
final modelPath = await ModelDownloadService.getModelPath('whisper_base.bin');
```

## 🎯 Next Steps

1. **Enable public access** in Cloudflare dashboard
2. **Test the download URLs** using curl commands
3. **Integrate Flutter code** into your app
4. **Customize the UI** to match your design
5. **Set up monitoring** for download usage

## 📞 Support

For issues or questions:
- Check the documentation in `docs/`
- Test with the provided scripts
- Review the Flutter examples for integration help

---

**Happy downloading! 🎊**
