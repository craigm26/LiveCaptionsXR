# Flutter Integration Guide

This guide explains how the `livecaptionsxrbucket` system integrates with the main LiveCaptionsXR Flutter application without conflicts.

## 🎯 **Dual-System Architecture**

### **System 1: LiveCaptionsXR Main App**
- **Location**: `lib/core/services/model_download_manager.dart`
- **Purpose**: Manages model downloads within the Flutter app
- **Configuration**: Hardcoded URLs pointing to `livecaptionsxrbucket.com`

### **System 2: LiveCaptionsXR Bucket (Distribution System)**
- **Location**: `livecaptionsxrbucket/` directory
- **Purpose**: Hosts models and provides web interface
- **Configuration**: Serves models at `livecaptionsxrbucket.com`

## 🔗 **Integration Points**

### **URL Consistency**
Both systems use the same URLs to ensure compatibility:

```dart
// In model_download_manager.dart
static const Map<String, ModelConfig> _modelConfigs = {
  'gemma-3n-E4B-it-int4': ModelConfig(
    fileName: 'gemma-3n-E4B-it-int4.task',
    url: 'https://livecaptionsxrbucket.com/gemma-3n-E4B-it-int4.task', // ✅ Matches
    expectedSize: 4398046511,
    type: ModelType.gemma,
    displayName: 'Gemma 3n Multimodal',
    assetPath: 'assets/models/gemma-3n-E4B-it-int4.task',
  ),
  'whisper-base': ModelConfig(
    fileName: 'ggml-base.bin',
    url: 'https://livecaptionsxrbucket.com/whisper_base.bin', // ✅ Matches
    expectedSize: 147951465,
    type: ModelType.whisper,
    displayName: 'Whisper Base',
    assetPath: 'assets/models/whisper_base.bin',
  ),
};
```

### **API Endpoints**
The bucket system provides API endpoints that the Flutter app can use:

```dart
// Health check
GET https://livecaptionsxrbucket.com/api/health

// Model information
GET https://livecaptionsxrbucket.com/api/models

// Setup guide
GET https://livecaptionsxrbucket.com/api/setup-guide
```

## 📁 **File Structure Compatibility**

### **No Conflicts**
- **Flutter App**: `lib/core/services/model_download_manager.dart`
- **Bucket System**: `livecaptionsxrbucket/web/model_downloads_page.html`
- **Result**: ✅ No file path conflicts

### **Shared Resources**
- **Models**: Both systems reference the same model files
- **URLs**: Both systems use the same download URLs
- **Configuration**: Both systems use consistent model metadata

## 🚀 **Deployment Workflow**

### **1. Deploy Bucket System First**
```bash
cd livecaptionsxrbucket
wrangler deploy
```

### **2. Verify Model URLs**
```bash
# Test model accessibility
curl -I https://livecaptionsxrbucket.com/whisper_base.bin
curl -I https://livecaptionsxrbucket.com/gemma-3n-E4B-it-int4.task
```

### **3. Deploy Flutter App**
The Flutter app will automatically use the correct URLs from the bucket system.

## 🔧 **Configuration Management**

### **Model URLs**
All model URLs are centralized in the bucket system:
- **Whisper Base**: `https://livecaptionsxrbucket.com/whisper_base.bin`
- **Gemma 3N E2B**: `https://livecaptionsxrbucket.com/gemma-3n-E2B-it-int4.task`
- **Gemma 3N E4B**: `https://livecaptionsxrbucket.com/gemma-3n-E4B-it-int4.task`

### **File Names**
Consistent file naming across both systems:
- **Whisper**: `whisper_base.bin` (Flutter expects `ggml-base.bin` but downloads `whisper_base.bin`)
- **Gemma E2B**: `gemma-3n-E2B-it-int4.task`
- **Gemma E4B**: `gemma-3n-E4B-it-int4.task`

## 📊 **Monitoring Integration**

### **Health Checks**
The Flutter app can monitor the bucket system:
```dart
// Check if bucket system is available
final response = await http.get(Uri.parse('https://livecaptionsxrbucket.com/api/health'));
if (response.statusCode == 200) {
  // Bucket system is healthy
}
```

### **Model Status**
Get real-time model information:
```dart
// Get model metadata
final response = await http.get(Uri.parse('https://livecaptionsxrbucket.com/api/models'));
final models = jsonDecode(response.body)['models'];
```

## 🎯 **Benefits of This Architecture**

### **Separation of Concerns**
- **Flutter App**: Focuses on app functionality and user experience
- **Bucket System**: Handles model distribution and hosting
- **No Coupling**: Each system can be updated independently

### **Scalability**
- **Bucket System**: Can be deployed to multiple regions
- **Flutter App**: Can switch between different bucket systems
- **CDN**: Models are served via Cloudflare's global network

### **Maintainability**
- **Centralized URLs**: All model URLs in one place
- **Version Control**: Each system has its own repository
- **Independent Updates**: Update models without touching the app

## 🔄 **Update Workflow**

### **Adding New Models**
1. **Upload model** to `livecaptionsxrbucket.com`
2. **Update API** in `src/index.js`
3. **Update Flutter config** in `model_download_manager.dart`
4. **Deploy both systems**

### **Updating Existing Models**
1. **Upload new version** to bucket system
2. **Update metadata** if needed
3. **Flutter app** automatically uses new version

## ✅ **Verification Checklist**

- [ ] Bucket system deployed and accessible
- [ ] Model URLs working in browser
- [ ] API endpoints responding correctly
- [ ] Flutter app can download models
- [ ] No file path conflicts between systems
- [ ] URLs consistent across both systems

## 🎉 **Result**

This architecture provides:
- **Zero conflicts** between the two systems
- **Full compatibility** with existing Flutter code
- **Scalable distribution** via Cloudflare
- **Easy maintenance** with clear separation
- **Future-proof** design for model updates 