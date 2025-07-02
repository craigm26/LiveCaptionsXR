# iOS Assets for gemma3n_multimodal Plugin

## Purpose
This directory contains iOS-specific assets for the gemma3n_multimodal plugin, including model files and resources that need to be embedded in the iOS app bundle.

## Model File Placement

### For .task Model Files
Place your Gemma 3n `.task` model files in one of these locations:

1. **Recommended**: `Assets/models/` - For plugin-bundled models
   ```
   ios/Assets/models/
   ├── gemma3n.task
   └── other_model.task
   ```

2. **App Bundle Root**: Directly in the iOS app's main bundle
   - Place files in your Flutter app's `ios/Runner/` directory
   - Add files to Xcode project via "Add Files to Runner"

### Bundle Integration Steps

1. **Add to Xcode Project**:
   - Open your iOS app in Xcode (`ios/Runner.xcworkspace`)
   - Right-click on "Runner" project
   - Select "Add Files to Runner"
   - Choose your `.task` files
   - Ensure "Copy items if needed" is checked
   - Select "Add to target: Runner"

2. **Verify Bundle Contents**:
   Use the plugin's `getBundleModelPaths` method to verify your models are properly embedded:
   ```dart
   final result = await plugin.getBundleModelPaths();
   print('Available models: ${result['bundleModels']}');
   ```

3. **Load Models**:
   ```dart
   // For bundled models, use relative paths
   await plugin.loadModel('gemma3n.task');
   
   // Or specify the assets path explicitly
   await plugin.loadModel('assets/models/gemma3n.task');
   ```

## Asset Path Resolution

The plugin automatically searches for models in these locations (in order):
1. Exact path (if absolute)
2. Main bundle root
3. `assets/models/` subdirectory in bundle
4. File system verification for absolute paths

## Best Practices

1. **Model Size**: Keep models under 100MB for reasonable app download sizes
2. **Multiple Models**: Use descriptive names for multiple model variants
3. **Asset Organization**: Group related models in subdirectories
4. **Xcode Integration**: Always add assets through Xcode to ensure proper bundle inclusion

## Troubleshooting

### Model Not Found Errors
- Verify the file is added to the Xcode project
- Check that the file is included in the app target
- Use `getBundleModelPaths()` to see available models
- Ensure file extensions match exactly (.task)

### Build Issues
- Clean build folder (Product → Clean Build Folder in Xcode)
- Verify iOS deployment target is 12.0+
- Check that model files don't exceed size limits

## Example Directory Structure
```
ios/
├── Assets/
│   ├── models/
│   │   ├── gemma3n-2b.task
│   │   ├── gemma3n-9b.task
│   │   └── specialized-model.task
│   └── README.md
├── Classes/
│   └── Gemma3nMultimodalPlugin.swift
├── gemma3n_multimodal.podspec
└── Runner.xcworkspace
```