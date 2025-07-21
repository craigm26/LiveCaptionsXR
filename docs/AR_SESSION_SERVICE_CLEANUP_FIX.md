# AR Session Service Cleanup Fix

## Problem Description

The LiveCaptionsXR app was experiencing an issue where services (Whisper, Gemma3n, audio capture, etc.) were being initialized and logged **after** the AR session ended, instead of being properly contained within the AR session lifecycle.

### Symptoms
- Services were being initialized after user closed AR mode
- Logs showed service startup messages appearing after AR session cleanup
- LiveCaptionsWidget was being shown on home screen when not in AR mode
- Potential resource leaks and unnecessary service initialization

### Root Cause Analysis

The issue was caused by two main problems:

1. **LiveCaptionsWidget Display Logic**: The home screen was automatically showing the `LiveCaptionsWidget` whenever the user was not in AR mode (`!inARMode`), which could potentially trigger service initialization.

2. **Insufficient Service Cleanup**: While services were being stopped during AR session cleanup, there was no verification that all services were actually stopped, and no prevention of automatic re-initialization.

## Solution Implemented

### 1. Fixed LiveCaptionsWidget Display Logic

**File**: `lib/features/home/view/home_screen.dart`

**Before**:
```dart
bool showOverlay = false;
if (!inARMode) {
  showOverlay = true;  // Always show when not in AR mode
}
```

**After**:
```dart
// Only show overlay when in AR mode and captions are active
// or when explicitly requested for fallback
bool showOverlay = false;
if (inARMode && captionsState is LiveCaptionsActive) {
  showOverlay = true;
} else if (inARMode && captionsState is LiveCaptionsActive &&
    captionsState.showOverlayFallback) {
  showOverlay = true;
}
// Remove the automatic showing of LiveCaptionsWidget when not in AR mode
```

### 2. Enhanced AR Session Cleanup

**File**: `lib/features/ar_session/cubit/ar_session_cubit.dart`

Added additional logging and verification:
```dart
emit(const ARSessionInitial());
_logger.i('✅ AR session stopped and persistence cleared');
_logger.i('🔄 AR session state reset to initial - no services should be running');
```

### 3. Added Service Verification in Home Screen

**File**: `lib/features/home/view/home_screen.dart`

Added comprehensive service cleanup verification in the AR session listener:
```dart
} else if (state is ARSessionInitial) {
  // AR mode was closed - ensure all services are stopped
  _logger.i('✅ AR mode closed and all services stopped');
  
  // Double-check that live captions are stopped
  final liveCaptionsCubit = context.read<LiveCaptionsCubit>();
  if (liveCaptionsCubit.state is LiveCaptionsActive &&
      (liveCaptionsCubit.state as LiveCaptionsActive).isListening) {
    _logger.w('⚠️ Live captions still active after AR session end, stopping...');
    liveCaptionsCubit.stopCaptions();
  }
  
  // Double-check that other services are stopped
  final soundDetectionCubit = context.read<SoundDetectionCubit>();
  if (soundDetectionCubit.isActive) {
    _logger.w('⚠️ Sound detection still active after AR session end, stopping...');
    soundDetectionCubit.stop();
  }
  
  final localizationCubit = context.read<LocalizationCubit>();
  if (localizationCubit.isActive) {
    _logger.w('⚠️ Localization still active after AR session end, stopping...');
    localizationCubit.stop();
  }
  
  final visualIdentificationCubit = context.read<VisualIdentificationCubit>();
  if (visualIdentificationCubit.isActive) {
    _logger.w('⚠️ Visual identification still active after AR session end, stopping...');
    visualIdentificationCubit.stop();
  }
  
  _logger.i('✅ All services verified as stopped after AR session end');
}
```

## Expected Behavior After Fix

1. **AR Session Start**: Services are initialized only when entering AR mode
2. **AR Session Active**: Services run normally during AR mode
3. **AR Session End**: All services are properly stopped and verified
4. **Home Screen**: No automatic service initialization when not in AR mode
5. **Logging**: Service initialization logs appear only during AR session, not after

## Testing

To verify the fix:

1. Start the app and enter AR mode
2. Verify that services initialize properly during AR session
3. Close AR mode
4. Verify that no service initialization logs appear after AR session ends
5. Verify that the home screen shows no LiveCaptionsWidget when not in AR mode
6. Check that all services are properly stopped and verified

## Related Files

- `lib/features/home/view/home_screen.dart` - Main UI and service management
- `lib/features/ar_session/cubit/ar_session_cubit.dart` - AR session state management
- `lib/features/live_captions/cubit/live_captions_cubit.dart` - Live captions management
- `lib/core/services/enhanced_speech_processor.dart` - Speech processing service
- `lib/core/services/whisper_service.dart` - Whisper STT service 