import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_state.dart';
import 'app_logger.dart';

/// Service for persisting AR session state across app restarts
/// 
/// This service handles saving and restoring AR session state,
/// including anchor information and session configuration,
/// enabling seamless continuity when users restart the app.
class ARSessionPersistenceService {
  static const String _sessionStateKey = 'ar_session_state';
  static const String _anchorDataKey = 'ar_anchor_data';
  static const String _sessionConfigKey = 'ar_session_config';
  
  static final AppLogger _logger = AppLogger.instance;

  /// Save AR session state to persistent storage
  Future<void> saveSessionState(ARSessionState state) async {
    try {
      _logger.i('💾 Saving AR session state: ${state.runtimeType}');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Save basic session state
      String stateType = '';
      Map<String, dynamic> stateData = {};
      
      if (state is ARSessionReady) {
        stateType = 'ready';
        stateData = {
          'anchorPlaced': state.anchorPlaced,
          'anchorId': state.anchorId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      } else if (state is ARSessionPaused) {
        stateType = 'paused';
        stateData = {
          'previousAnchorPlaced': state.previousAnchorPlaced,
          'previousAnchorId': state.previousAnchorId,
          'pausedAt': state.pausedAt.millisecondsSinceEpoch,
        };
      } else if (state is ARSessionCalibrating) {
        stateType = 'calibrating';
        stateData = {
          'progress': state.progress,
          'calibrationType': state.calibrationType,
        };
      }
      
      final sessionData = {
        'stateType': stateType,
        'stateData': stateData,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_sessionStateKey, jsonEncode(sessionData));
      _logger.i('✅ AR session state saved successfully');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to save AR session state', 
          error: e, stackTrace: stackTrace);
    }
  }

  /// Restore AR session state from persistent storage
  Future<ARSessionState?> restoreSessionState() async {
    try {
      _logger.i('📂 Restoring AR session state from storage...');
      
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionStateKey);
      
      if (sessionJson == null) {
        _logger.i('ℹ️ No saved AR session state found');
        return null;
      }
      
      final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
      final stateType = sessionData['stateType'] as String;
      final stateData = sessionData['stateData'] as Map<String, dynamic>;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        sessionData['savedAt'] as int
      );
      
      // Don't restore states older than 24 hours
      if (DateTime.now().difference(savedAt).inHours > 24) {
        _logger.i('⏰ Saved AR session state too old, ignoring');
        await clearSessionState();
        return null;
      }
      
      ARSessionState? restoredState;
      
      switch (stateType) {
        case 'ready':
          restoredState = ARSessionReady(
            anchorPlaced: stateData['anchorPlaced'] as bool? ?? false,
            anchorId: stateData['anchorId'] as String?,
          );
          break;
        case 'paused':
          restoredState = ARSessionPaused(
            previousAnchorPlaced: stateData['previousAnchorPlaced'] as bool? ?? false,
            previousAnchorId: stateData['previousAnchorId'] as String?,
            pausedAt: DateTime.fromMillisecondsSinceEpoch(
              stateData['pausedAt'] as int
            ),
          );
          break;
        case 'calibrating':
          restoredState = ARSessionCalibrating(
            progress: stateData['progress'] as double? ?? 0.0,
            calibrationType: stateData['calibrationType'] as String? ?? 'basic',
          );
          break;
      }
      
      if (restoredState != null) {
        _logger.i('✅ AR session state restored: ${restoredState.runtimeType}');
      } else {
        _logger.w('⚠️ Unknown session state type: $stateType');
      }
      
      return restoredState;
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to restore AR session state', 
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Save anchor data for persistence
  Future<void> saveAnchorData({
    required String anchorId,
    required List<double> transform,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _logger.i('⚓ Saving anchor data for ID: $anchorId');
      
      final prefs = await SharedPreferences.getInstance();
      final anchorData = {
        'anchorId': anchorId,
        'transform': transform,
        'metadata': metadata ?? {},
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_anchorDataKey, jsonEncode(anchorData));
      _logger.i('✅ Anchor data saved successfully');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to save anchor data', 
          error: e, stackTrace: stackTrace);
    }
  }

  /// Restore anchor data from persistent storage
  Future<Map<String, dynamic>?> restoreAnchorData() async {
    try {
      _logger.i('📂 Restoring anchor data from storage...');
      
      final prefs = await SharedPreferences.getInstance();
      final anchorJson = prefs.getString(_anchorDataKey);
      
      if (anchorJson == null) {
        _logger.i('ℹ️ No saved anchor data found');
        return null;
      }
      
      final anchorData = jsonDecode(anchorJson) as Map<String, dynamic>;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        anchorData['savedAt'] as int
      );
      
      // Don't restore anchor data older than 1 hour
      if (DateTime.now().difference(savedAt).inHours > 1) {
        _logger.i('⏰ Saved anchor data too old, ignoring');
        await clearAnchorData();
        return null;
      }
      
      _logger.i('✅ Anchor data restored successfully');
      return anchorData;
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to restore anchor data', 
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Save session configuration
  Future<void> saveSessionConfig(Map<String, dynamic> config) async {
    try {
      _logger.i('⚙️ Saving AR session configuration...');
      
      final prefs = await SharedPreferences.getInstance();
      final configData = {
        ...config,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_sessionConfigKey, jsonEncode(configData));
      _logger.i('✅ Session configuration saved successfully');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to save session configuration', 
          error: e, stackTrace: stackTrace);
    }
  }

  /// Restore session configuration
  Future<Map<String, dynamic>?> restoreSessionConfig() async {
    try {
      _logger.i('📂 Restoring session configuration...');
      
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_sessionConfigKey);
      
      if (configJson == null) {
        _logger.i('ℹ️ No saved session configuration found');
        return null;
      }
      
      final config = jsonDecode(configJson) as Map<String, dynamic>;
      _logger.i('✅ Session configuration restored successfully');
      return config;
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to restore session configuration', 
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Clear all persisted AR session data
  Future<void> clearAllSessionData() async {
    try {
      _logger.i('🧹 Clearing all AR session data...');
      
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_sessionStateKey),
        prefs.remove(_anchorDataKey),
        prefs.remove(_sessionConfigKey),
      ]);
      
      _logger.i('✅ All AR session data cleared successfully');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to clear AR session data', 
          error: e, stackTrace: stackTrace);
    }
  }

  /// Clear only session state
  Future<void> clearSessionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionStateKey);
      _logger.i('✅ AR session state cleared');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to clear session state', 
          error: e, stackTrace: stackTrace);
    }
  }

  /// Clear only anchor data
  Future<void> clearAnchorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_anchorDataKey);
      _logger.i('✅ Anchor data cleared');
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to clear anchor data', 
          error: e, stackTrace: stackTrace);
    }
  }

  /// Check if there's any persisted session data
  Future<bool> hasPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_sessionStateKey) || 
             prefs.containsKey(_anchorDataKey) ||
             prefs.containsKey(_sessionConfigKey);
    } catch (e) {
      _logger.e('❌ Failed to check for persisted data', error: e);
      return false;
    }
  }
}