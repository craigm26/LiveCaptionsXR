# iOS Integration Checklist

Use this checklist to integrate the improved iOS plugin into your Flutter app.

## Prerequisites
- [ ] Flutter development environment set up
- [ ] Xcode installed (latest version recommended)  
- [ ] iOS deployment target set to 12.0+ in your app
- [ ] Gemma 3n model file in `.task` format obtained

## Integration Steps

### 1. Plugin Integration
- [ ] Add plugin dependency to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Verify plugin appears in `.flutter-plugins` file

### 2. iOS Configuration
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Verify iOS deployment target is 12.0+
- [ ] Check that MediaPipe pods are included in Podfile.lock

### 3. Model Asset Setup
- [ ] Place `.task` model file in `ios/Assets/models/` directory
- [ ] Add model file to Xcode project:
  - [ ] Right-click "Runner" in Xcode
  - [ ] Select "Add Files to Runner"
  - [ ] Choose your `.task` file
  - [ ] Ensure "Copy items if needed" is checked
  - [ ] Select "Add to target: Runner"
- [ ] Verify file appears in Xcode project navigator

### 4. Build Verification
- [ ] Run `flutter clean && flutter pub get`
- [ ] Run `cd ios && pod install`
- [ ] Run `flutter build ios --debug`
- [ ] Verify build completes without errors

### 5. Testing Integration
- [ ] Test model discovery:
  ```dart
  final info = await plugin.getBundleModelPaths();
  print('Available models: ${info['bundleModels']}');
  ```

- [ ] Test model loading:
  ```dart
  try {
    await plugin.loadModel('your-model.task');
    print('Model loaded successfully');
  } catch (e) {
    print('Model loading failed: $e');
  }
  ```

- [ ] Test model info:
  ```dart
  final info = await plugin.getModelInfo();
  print('Model loaded: ${info['isLoaded']}');
  ```

### 6. Device Testing
- [ ] Test on iOS Simulator (if supported)
- [ ] Test on physical iOS device (recommended)
- [ ] Verify model loading works correctly
- [ ] Test inference functionality
- [ ] Check memory usage and performance

## Troubleshooting

### Build Issues
- [ ] Verify MediaPipe pods are correctly installed
- [ ] Check iOS deployment target consistency
- [ ] Clear derived data: Xcode → Product → Clean Build Folder
- [ ] Delete and reinstall pods: `cd ios && rm -rf Pods && pod install`

### Model Loading Issues
- [ ] Verify model file is added to Xcode target
- [ ] Check file name matches exactly (case-sensitive)
- [ ] Use `getBundleModelPaths()` to see available models
- [ ] Check model file size isn't too large for bundle

### Runtime Issues
- [ ] Check device has sufficient memory (1GB+ recommended)
- [ ] Verify iOS version compatibility (12.0+)
- [ ] Check console logs for detailed error messages
- [ ] Test with different model files if available

## Advanced Configuration

### Custom Parameters
```dart
await plugin.loadModel('model.task', {
  'useANE': true,          // Apple Neural Engine
  'useGPU': false,         // GPU acceleration
  'maxTokens': 1000,       // Max response length
  'topK': 40,              // Top-K sampling
  'topP': 0.9,             // Top-P sampling
  'temperature': 0.8,      // Response randomness
});
```

### Error Handling
```dart
try {
  await plugin.loadModel('model.task');
} on FlutterError catch (e) {
  print('Error Code: ${e.code}');
  print('Message: ${e.message}');
  print('Details: ${e.details}');
}
```

## Performance Tips

### Memory Management
- [ ] Unload model when not needed: `await plugin.unloadModel()`
- [ ] Monitor app memory usage during inference
- [ ] Consider smaller model variants for constrained devices

### Battery Optimization
- [ ] Use Apple Neural Engine when available (`useANE: true`)
- [ ] Adjust inference parameters for efficiency
- [ ] Batch processing for multiple requests

## Documentation References
- [ ] Read `ios/Assets/README.md` for detailed asset handling
- [ ] Review `ios/IMPROVEMENTS_SUMMARY.md` for technical details
- [ ] Check MediaPipe iOS documentation for advanced usage
- [ ] Refer to plugin README.md for API documentation

## Support
If you encounter issues:
1. Check the troubleshooting section above
2. Review plugin logs and error messages
3. Verify all checklist items are completed
4. Test with a minimal example project
5. Check MediaPipe iOS requirements and compatibility