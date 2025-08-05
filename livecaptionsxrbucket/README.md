# 🤖 LiveCaptionsXR Model Distribution System

> **⚠️ IMPORTANT: This is a separate model distribution system, not part of the main LiveCaptionsXR application.**

## 🎯 Purpose & Separation

This folder contains a **standalone model distribution system** that provides AI models for the LiveCaptionsXR application. It operates independently from the main project and serves multiple purposes:

### **Why Separate?**
- **Model Distribution**: Provides a centralized location for downloading AI models
- **Independent Hosting**: Can be deployed separately from the main application
- **Multiple Access Methods**: Web downloads, direct URLs, and Flutter integration
- **Cloudflare R2 Integration**: Uses Cloudflare R2 for reliable, fast model hosting

### **Target Audiences**
1. **End Users**: Download models directly via web interface
2. **Developers**: Integrate model downloads into their applications
3. **System Administrators**: Manage model distribution infrastructure

---

## 📦 Available Models

| Model | Size | Purpose | Download |
|-------|------|---------|----------|
| **Whisper Base** | 141 MB | Speech recognition | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin) |
| **Gemma 3N E2B** | 2.92 GB | Text enhancement | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E2B-it-int4.task) |
| **Gemma 3N E4B** | 4.11 GB | Advanced text enhancement | [Download](https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E4B-it-int4.task) |

---

## 🌐 Web Download Interface

### **For End Users**
Open `web/download.html` in any browser for a professional download interface.

**Features:**
- ✅ Clean, responsive design
- ✅ Direct download links
- ✅ File size information
- ✅ Download progress indicators
- ✅ Mobile-friendly interface

### **Quick Access**
```bash
# Open the web interface
open web/download.html
```

---

## 📱 Flutter Integration

### **For Developers**
Complete Flutter implementation for integrating model downloads into your application.

**Location:** `flutter/` folder

**Features:**
- ✅ Real-time download progress
- ✅ Download management (start/cancel/delete)
- ✅ Storage management
- ✅ Beautiful Material Design UI
- ✅ Error handling
- ✅ Cross-platform support

### **Quick Integration**
```dart
// Add to your app
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ModelDownloadsPage()),
);

// Check if model is downloaded
final isDownloaded = await ModelDownloadService.isModelDownloaded('whisper_base.bin');
```

### **Dependencies**
```yaml
dependencies:
  flutter_bloc: ^8.1.3
  http: ^1.1.0
  path_provider: ^2.1.1
  permission_handler: ^11.0.1
```

---

## 🔧 System Administration

### **For System Administrators**
PowerShell scripts for managing the Cloudflare R2 storage and model distribution.

**Location:** `scripts/` folder

### **Quick Setup**
```powershell
# 1. Upload models to R2
.\scripts\upload.ps1

# 2. Make files publicly accessible
.\scripts\make_public.ps1

# 3. Test download URLs
.\scripts\test.ps1
```

### **Available Scripts**
- `upload.ps1` - Upload model files to Cloudflare R2
- `make_public.ps1` - Configure public access for downloads
- `test.ps1` - Test download URLs and accessibility

---

## 🔗 Direct Download URLs

### **For Programmatic Access**
```bash
# Test downloads
curl -I "https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin"

# Download files
curl -L -o "whisper_base.bin" "https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin"
```

---

## 📁 Folder Structure

```
livecaptionsxrbucket/
├── README.md                    # This file - System overview
├── CONSOLIDATED_SUMMARY.md      # Technical summary
├── scripts/                     # System administration scripts
│   ├── upload.ps1              # Upload models to R2
│   ├── make_public.ps1         # Configure public access
│   └── test.ps1                # Test download URLs
├── docs/                        # Documentation
│   └── SETUP_GUIDE.md          # Complete setup guide
├── web/                         # Web download interface
│   ├── download.html           # Main download page
│   └── model_downloads_page.html # Advanced download interface
└── flutter/                     # Flutter integration
    ├── README.md               # Flutter setup guide
    ├── pubspec.yaml            # Dependencies
    └── lib/                    # Flutter implementation
```

---

## ⚠️ Important Notes

### **Separation from Main Project**
- This system operates independently from the main LiveCaptionsXR application
- Models are hosted on Cloudflare R2, not in the main repository
- The main app downloads models from these URLs automatically
- This system can be deployed separately for custom model distribution

### **Usage Guidelines**
- **End Users**: Use the web interface for simple downloads
- **Developers**: Use the Flutter integration for app integration
- **Administrators**: Use PowerShell scripts for system management
- **Direct Access**: Use curl commands for programmatic access

### **Support**
- For model download issues: Check the web interface
- For integration issues: Review the Flutter documentation
- For system issues: Check the PowerShell scripts and setup guide

---

## 🚀 Quick Start for Different Users

### **End Users (Web Downloads)**
1. Open `web/download.html` in your browser
2. Click the download button for your desired model
3. Wait for download to complete (large files, 2-4GB)

### **Developers (Flutter Integration)**
1. Copy the `flutter/` folder contents to your project
2. Add the required dependencies to `pubspec.yaml`
3. Use the `ModelDownloadsPage` in your app

### **System Administrators**
1. Configure Cloudflare R2 credentials
2. Run `.\scripts\upload.ps1` to upload models
3. Run `.\scripts\make_public.ps1` to enable downloads
4. Test with `.\scripts\test.ps1`

---

**🎯 This model distribution system provides reliable, fast access to AI models for the LiveCaptionsXR ecosystem.** 