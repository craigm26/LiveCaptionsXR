# Dependency Injection and AR Session State Improvements

This document describes the improvements made to implement proper dependency injection for `HybridLocalizationEngine` and move AR session state management to a dedicated cubit.

## Changes Made

### 1. Dependency Injection (DI) Setup

- **Service Locator**: Updated `lib/core/di/service_locator.dart` to register `HybridLocalizationEngine` as a singleton using `get_it`
- **App Initialization**: Modified `lib/app.dart` to call `setupServiceLocator()` and inject dependencies into cubits
- **Cubit Updates**: Updated `HomeCubit` and `LiveCaptionsCubit` to accept injected `HybridLocalizationEngine` instead of creating new instances

### 2. AR Session State Management

- **ARSessionCubit**: Created new cubit `lib/features/ar_session/cubit/ar_session_cubit.dart` to manage AR session lifecycle
- **AR States**: Defined proper state classes (Initial, Initializing, Ready, Error, Stopping) in `ar_session_state.dart`
- **Logic Migration**: Moved AR initialization, anchor placement, and service coordination from UI to cubit
- **UI Simplification**: Updated `HomeScreen` to use `ARSessionCubit` with `BlocListener` for state-driven UI updates

### 3. Benefits

- **Single Responsibility**: Each component has a clear, focused purpose
- **Testability**: Dependency injection makes testing easier with mocks
- **State Management**: Proper state management for AR session lifecycle
- **Maintainability**: Centralized AR logic reduces code duplication
- **Error Handling**: Improved error handling and user feedback

### 4. Testing

- **ARSessionCubit Tests**: Comprehensive test coverage for the new cubit
- **DI Tests**: Tests to ensure proper service locator configuration
- **Updated Tests**: Existing tests updated to work with dependency injection

## Usage

The `HybridLocalizationEngine` is now available as a singleton throughout the app:

```dart
// In a cubit or service
final hybridEngine = sl<HybridLocalizationEngine>();

// In BLoC providers (app.dart)
BlocProvider<HomeCubit>(
  create: (context) => HomeCubit(
    hybridLocalizationEngine: sl(),
  ),
),
```

AR session management is now handled by the dedicated cubit:

```dart
// Initialize AR session
final arSessionCubit = context.read<ARSessionCubit>();
await arSessionCubit.initializeARSession();

// Check if ready
if (arSessionCubit.isReady) {
  // Start services
}
```

## Future Enhancements

- ✅ **COMPLETED**: Added more services to the DI container (ARAnchorManager, AudioService, VisualIdentificationService, LocalizationService, CameraService, ARSessionPersistenceService)
- ✅ **COMPLETED**: Implemented AR session persistence across app restarts using SharedPreferences
- ✅ **COMPLETED**: Added more granular AR session states for better UX (Configuring, Calibrating, TrackingLost, Reconnecting, Paused, Resuming)
- ✅ **COMPLETED**: Enhanced state management pattern with persistence and recovery capabilities

## Recent Improvements (Completed)

### Enhanced Dependency Injection
- **Expanded Service Registration**: Added comprehensive service registration including ARAnchorManager, AudioService, VisualIdentificationService, LocalizationService, CameraService
- **Persistence Service**: New ARSessionPersistenceService for managing session state across app restarts
- **Factory vs Singleton Pattern**: Proper separation between singleton services (core infrastructure) and factory services (UI-dependent components)

### AR Session Persistence
- **State Persistence**: Save and restore AR session states including anchor information
- **Anchor Data Persistence**: Persist anchor transforms and metadata with automatic expiration
- **Session Configuration**: Save user preferences and session settings
- **Smart Recovery**: Automatic session restoration with validation and fallback

### Granular AR Session States
- **ARSessionConfiguring**: Initial setup and configuration phase
- **ARSessionCalibrating**: Device and environment calibration with progress tracking
- **ARSessionTrackingLost**: Temporary tracking loss with reason and timestamp
- **ARSessionReconnecting**: Automatic reconnection attempts with retry count
- **ARSessionPaused**: Background state preservation with previous session data
- **ARSessionResuming**: Recovery from paused state with progress indication

### Enhanced State Management
- **Automatic Persistence**: State changes are automatically saved to persistent storage
- **Session Recovery**: Seamless restoration of AR sessions across app restarts
- **Error Recovery**: Improved error handling with automatic reconnection attempts
- **Background/Foreground Handling**: Proper pause/resume functionality for app lifecycle

### Testing Coverage
- **Comprehensive Unit Tests**: Full test coverage for new services and states
- **Persistence Testing**: Validation of save/restore functionality
- **State Transition Testing**: Verification of proper state management
- **Error Scenario Testing**: Edge cases and error handling validation