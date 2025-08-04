# Flutter Model Downloads Example

This is a complete Flutter implementation for downloading AI models from Cloudflare R2 storage.

## Features

- ✅ Real-time download progress tracking
- ✅ Download management (start, cancel, delete)
- ✅ Storage management with permissions
- ✅ Beautiful Material Design UI
- ✅ Error handling and user feedback
- ✅ Cross-platform (Android & iOS)
- ✅ Resume downloads capability
- ✅ Storage space checking

## Setup

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Add permissions to Android manifest:**
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   ```

3. **Add permissions to iOS Info.plist:**
   ```xml
   <!-- ios/Runner/Info.plist -->
   <key>NSAppTransportSecurity</key>
   <dict>
     <key>NSAllowsArbitraryLoads</key>
     <true/>
   </dict>
   ```

## Usage

Run the example:
```bash
flutter run
```

## File Structure

```
lib/
├── main.dart
└── features/
    └── model_downloads/
        ├── models/
        │   └── model_info.dart
        ├── services/
        │   └── model_download_service.dart
        ├── cubit/
        │   ├── model_downloads_cubit.dart
        │   └── model_downloads_state.dart
        ├── widgets/
        │   ├── model_card.dart
        │   └── download_progress_dialog.dart
        └── view/
            └── model_downloads_page.dart
```

## Integration

To integrate this into your app:

1. Copy the `features/model_downloads` folder to your app
2. Add the required dependencies to your `pubspec.yaml`
3. Import and use `ModelDownloadsPage` in your navigation

## Customization

- Update download URLs in `model_download_service.dart`
- Add more models in `model_downloads_cubit.dart`
- Customize UI styling in `model_card.dart` 