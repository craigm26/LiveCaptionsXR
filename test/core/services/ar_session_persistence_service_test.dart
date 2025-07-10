import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_state.dart';

void main() {
  group('ARSessionPersistenceService', () {
    late ARSessionPersistenceService persistenceService;

    setUp(() {
      // Set up mock shared preferences
      SharedPreferences.setMockInitialValues({});
      persistenceService = ARSessionPersistenceService();
    });

    group('Session State Persistence', () {
      test('saves and restores ARSessionReady state', () async {
        // Arrange
        const readyState = ARSessionReady(
          anchorPlaced: true,
          anchorId: 'test_anchor_123',
        );

        // Act
        await persistenceService.saveSessionState(readyState);
        final restoredState = await persistenceService.restoreSessionState();

        // Assert
        expect(restoredState, isA<ARSessionReady>());
        final restored = restoredState as ARSessionReady;
        expect(restored.anchorPlaced, true);
        expect(restored.anchorId, 'test_anchor_123');
      });

      test('saves and restores ARSessionPaused state', () async {
        // Arrange
        final pausedState = ARSessionPaused(
          previousAnchorPlaced: true,
          previousAnchorId: 'previous_anchor_456',
          pausedAt: DateTime.now(),
        );

        // Act
        await persistenceService.saveSessionState(pausedState);
        final restoredState = await persistenceService.restoreSessionState();

        // Assert
        expect(restoredState, isA<ARSessionPaused>());
        final restored = restoredState as ARSessionPaused;
        expect(restored.previousAnchorPlaced, true);
        expect(restored.previousAnchorId, 'previous_anchor_456');
        expect(restored.pausedAt, isNotNull);
      });

      test('saves and restores ARSessionCalibrating state', () async {
        // Arrange
        const calibratingState = ARSessionCalibrating(
          progress: 0.75,
          calibrationType: 'advanced',
        );

        // Act
        await persistenceService.saveSessionState(calibratingState);
        final restoredState = await persistenceService.restoreSessionState();

        // Assert
        expect(restoredState, isA<ARSessionCalibrating>());
        final restored = restoredState as ARSessionCalibrating;
        expect(restored.progress, 0.75);
        expect(restored.calibrationType, 'advanced');
      });

      test('returns null when no saved state exists', () async {
        // Act
        final restoredState = await persistenceService.restoreSessionState();

        // Assert
        expect(restoredState, isNull);
      });

      test('ignores states older than 24 hours', () async {
        // Arrange
        const readyState = ARSessionReady(anchorPlaced: true);
        
        // Mock SharedPreferences with old timestamp
        final prefs = await SharedPreferences.getInstance();
        final oldTimestamp = DateTime.now().subtract(const Duration(hours: 25));
        await prefs.setString('ar_session_state', '''
          {
            "stateType": "ready",
            "stateData": {"anchorPlaced": true},
            "savedAt": ${oldTimestamp.millisecondsSinceEpoch}
          }
        ''');

        // Act
        final restoredState = await persistenceService.restoreSessionState();

        // Assert
        expect(restoredState, isNull);
      });
    });

    group('Anchor Data Persistence', () {
      test('saves and restores anchor data', () async {
        // Arrange
        const anchorId = 'anchor_789';
        final transform = List.generate(16, (i) => i.toDouble());
        final metadata = {'test': 'data'};

        // Act
        await persistenceService.saveAnchorData(
          anchorId: anchorId,
          transform: transform,
          metadata: metadata,
        );
        final restoredData = await persistenceService.restoreAnchorData();

        // Assert
        expect(restoredData, isNotNull);
        expect(restoredData!['anchorId'], anchorId);
        expect(restoredData['transform'], transform);
        expect(restoredData['metadata'], metadata);
      });

      test('returns null when no anchor data exists', () async {
        // Act
        final restoredData = await persistenceService.restoreAnchorData();

        // Assert
        expect(restoredData, isNull);
      });

      test('ignores anchor data older than 1 hour', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        final oldTimestamp = DateTime.now().subtract(const Duration(hours: 2));
        await prefs.setString('ar_anchor_data', '''
          {
            "anchorId": "old_anchor",
            "transform": [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],
            "metadata": {},
            "savedAt": ${oldTimestamp.millisecondsSinceEpoch}
          }
        ''');

        // Act
        final restoredData = await persistenceService.restoreAnchorData();

        // Assert
        expect(restoredData, isNull);
      });
    });

    group('Session Configuration', () {
      test('saves and restores session configuration', () async {
        // Arrange
        final config = {
          'calibrationType': 'advanced',
          'trackingQuality': 'high',
          'autoAnchor': true,
        };

        // Act
        await persistenceService.saveSessionConfig(config);
        final restoredConfig = await persistenceService.restoreSessionConfig();

        // Assert
        expect(restoredConfig, isNotNull);
        expect(restoredConfig!['calibrationType'], 'advanced');
        expect(restoredConfig['trackingQuality'], 'high');
        expect(restoredConfig['autoAnchor'], true);
      });

      test('returns null when no configuration exists', () async {
        // Act
        final restoredConfig = await persistenceService.restoreSessionConfig();

        // Assert
        expect(restoredConfig, isNull);
      });
    });

    group('Data Management', () {
      test('clears all session data', () async {
        // Arrange
        const readyState = ARSessionReady(anchorPlaced: true);
        await persistenceService.saveSessionState(readyState);
        await persistenceService.saveAnchorData(
          anchorId: 'test',
          transform: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
        );
        await persistenceService.saveSessionConfig({'test': 'config'});

        // Act
        await persistenceService.clearAllSessionData();

        // Assert
        expect(await persistenceService.restoreSessionState(), isNull);
        expect(await persistenceService.restoreAnchorData(), isNull);
        expect(await persistenceService.restoreSessionConfig(), isNull);
      });

      test('checks for persisted data correctly', () async {
        // Arrange - No data initially
        expect(await persistenceService.hasPersistedData(), false);

        // Act - Save some data
        const readyState = ARSessionReady(anchorPlaced: true);
        await persistenceService.saveSessionState(readyState);

        // Assert
        expect(await persistenceService.hasPersistedData(), true);
      });

      test('clears only session state', () async {
        // Arrange
        const readyState = ARSessionReady(anchorPlaced: true);
        await persistenceService.saveSessionState(readyState);
        await persistenceService.saveAnchorData(
          anchorId: 'test',
          transform: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
        );

        // Act
        await persistenceService.clearSessionState();

        // Assert
        expect(await persistenceService.restoreSessionState(), isNull);
        expect(await persistenceService.restoreAnchorData(), isNotNull);
      });

      test('clears only anchor data', () async {
        // Arrange
        const readyState = ARSessionReady(anchorPlaced: true);
        await persistenceService.saveSessionState(readyState);
        await persistenceService.saveAnchorData(
          anchorId: 'test',
          transform: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
        );

        // Act
        await persistenceService.clearAnchorData();

        // Assert
        expect(await persistenceService.restoreSessionState(), isNotNull);
        expect(await persistenceService.restoreAnchorData(), isNull);
      });
    });
  });
}