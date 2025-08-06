# LiveCaptionsXR Model Distribution System

Dual-purpose platform: Direct model downloads for LiveCaptionsXR applications and comprehensive guide for setting up Gemma 3N model distribution systems.

## 📋 Gemma Terms of Use Compliance

This distribution system includes Gemma 3N models and must comply with Google's Gemma Terms of Use:

### Required Notices
- **NOTICE file**: Must be included with all distributions (see `NOTICE` file in root)
- **Terms notice**: Displayed on web pages and in Flutter app for Gemma models
- **Use restrictions**: Users must comply with the Gemma Prohibited Use Policy

### Compliance Requirements
1. **Include use restrictions** in any agreement governing use/distribution
2. **Provide notice to users** about the use restrictions in Section 3.2
3. **Include prominent notices** for any modified files
4. **Accompany distributions** with the required NOTICE text file

### Links
- [Gemma Terms of Use](https://ai.google.dev/gemma/terms)
- [Gemma Prohibited Use Policy](https://ai.google.dev/gemma/prohibited_use_policy)

## 🚀 Quick Start

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