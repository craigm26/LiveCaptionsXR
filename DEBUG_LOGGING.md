# Debug Logging Overlay

This feature provides a comprehensive debug logging system that lets developers view real-time logs directly on the device without needing a debugger connection. The overlay can be enabled in any build variant.

## Features

- **Real-time Log Display**: See logs as they happen in a transparent overlay
- **Multiple Log Levels**: Support for trace, debug, info, warning, error, and fatal logs
- **Color-coded Display**: Different colors for different log levels for easy identification
- **Copy to Clipboard**: Copy all logs to clipboard for easy sharing
- **Auto-scroll**: Automatically scroll to the latest logs
- **Privacy-aware**: Clears logs when disabled for user privacy
- **Memory Efficient**: Limits to 500 log entries to prevent memory issues
- **Expandable UI**: Tap to expand/collapse the logging overlay

## How to Use

### 1. Enable Debug Logging

1. Open the app and go to **Settings**
2. Scroll down to **Developer & Testing** (visible in all build variants)
3. Look for the prominent **"Debug Logging Overlay"** card with bug report icon
4. Toggle the switch to **ON** or tap anywhere on the card to enable
5. You'll see a confirmation message and instructions appear below the toggle
6. Navigate to the **Home screen** to see the transparent overlay at the top

### 2. Using the Overlay

- **Tap** the overlay header to expand/collapse the log view
- **Blue arrow button**: Toggle auto-scroll to latest logs
- **Copy button**: Copy all logs to clipboard
- **Clear button**: Clear all captured logs

### 3. Implementing in Your Code

Replace your existing `Logger` instances with `DebugCapturingLogger`:

```dart
// Old way
final Logger _logger = Logger(...);

// New way
final DebugCapturingLogger _logger = DebugCapturingLogger();

// Usage remains the same
_logger.d('Debug message');
_logger.i('Info message');
_logger.w('Warning message');
_logger.e('Error message', error: exception, stackTrace: stackTrace);
```

### 4. Testing the Feature

On the home screen, when debug logging is enabled, you'll see an orange test button. Tap it to generate sample logs of all types to test the overlay functionality.

## File Structure

```
lib/
├── core/services/
│   ├── debug_logger_service.dart      # Core logging service
│   └── debug_capturing_logger.dart    # Logger wrapper
├── shared/widgets/
│   └── debug_logging_overlay.dart     # UI overlay widget
└── features/settings/
    ├── cubit/settings_cubit.dart      # Settings management
    └── view/settings_screen.dart      # Settings UI
```

## Architecture

1. **DebugLoggerService**: Singleton service that manages log capture and storage
2. **DebugCapturingLogger**: Wrapper around the standard Logger that also sends logs to the service
3. **DebugLoggingOverlay**: UI widget that displays the logs in a transparent overlay
4. **SettingsCubit**: Manages the enable/disable state and persists it

## Security & Privacy

- Works in all build variants
- Automatically clears logs when disabled
- Logs are stored only in memory, not persisted to disk
- Limited to 500 entries to prevent memory issues

## Why It's Useful

This overlay is helpful when traditional debugging tools aren't available because it lets you:
- Capture logs from real user devices
- Troubleshoot issues reported by testers
- Verify log output in production-like environments


## Customization

You can customize the overlay appearance by modifying `debug_logging_overlay.dart`:
- Change colors and styling
- Adjust overlay size and position
- Modify log formatting
- Add additional controls or information
