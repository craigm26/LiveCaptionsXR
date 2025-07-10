import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:live_captions_xr/features/ar_session/cubit/ar_session_cubit.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_state.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';

import 'features/ar_session/cubit/ar_session_cubit_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Issue #61 - AR Mode Button Backup Restoration Bug', () {
    late MockARSessionPersistenceService mockPersistenceService;
    late MockHybridLocalizationEngine mockHybridLocalizationEngine;
    late ARSessionCubit arSessionCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockPersistenceService = MockARSessionPersistenceService();
      mockHybridLocalizationEngine = MockHybridLocalizationEngine();
      arSessionCubit = ARSessionCubit(
        persistenceService: mockPersistenceService,
        hybridLocalizationEngine: mockHybridLocalizationEngine,
      );
    });

    tearDown(() {
      arSessionCubit.close();
    });

    test('ISSUE: AR mode button tries to restore from backup causing failure', () async {
      // Simulate the problematic scenario described in the issue
      // There's a saved AR session state that causes problems when restored
      const problematicSavedState = ARSessionReady(
        anchorPlaced: true,
        anchorId: 'stale-backup-anchor-bka', // This matches the "bka" from the logs
      );
      
      // Mock the persistence service to return the problematic saved state
      when(mockPersistenceService.restoreSessionState()).thenAnswer((_) async => problematicSavedState);
      when(mockPersistenceService.restoreAnchorData()).thenAnswer((_) async => {
        'anchorId': 'stale-backup-anchor-bka',
        'transform': List.filled(16, 1.0),
        'metadata': {},
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // BEFORE THE FIX: Calling initializeARSession() with default parameters
      // This would try to restore from backup, causing the AR mode to fail
      await arSessionCubit.initializeARSession(); // Default: restoreFromPersistence = true

      // Verify the problem: The system attempted to restore from backup
      verify(mockPersistenceService.restoreSessionState()).called(1);
      verify(mockPersistenceService.restoreAnchorData()).called(1);
      
      // The state was restored from backup instead of fresh initialization
      expect(arSessionCubit.state, isA<ARSessionReady>());
      final state = arSessionCubit.state as ARSessionReady;
      expect(state.anchorId, 'stale-backup-anchor-bka');
      expect(state.anchorPlaced, true);
      
      // This is the problematic scenario - we're using stale backup data
      // which causes AR mode to fail as described in the issue
    });

    test('SOLUTION: AR mode button starts fresh (restoreFromPersistence=false)', () async {
      // Setup the same problematic backup data
      const problematicSavedState = ARSessionReady(
        anchorPlaced: true,
        anchorId: 'stale-backup-anchor-bka',
      );
      
      when(mockPersistenceService.restoreSessionState()).thenAnswer((_) async => problematicSavedState);
      when(mockPersistenceService.saveSessionState(any)).thenAnswer((_) async {});

      // AFTER THE FIX: Calling initializeARSession(restoreFromPersistence: false)
      // This bypasses the backup restoration and starts fresh
      await arSessionCubit.initializeARSession(restoreFromPersistence: false);

      // Verify the fix: The system did NOT attempt to restore from backup
      verifyNever(mockPersistenceService.restoreSessionState());
      
      // The session was initialized fresh, not from backup
      expect(arSessionCubit.state, isA<ARSessionReady>());
      
      // Verify that we saved the new fresh state
      verify(mockPersistenceService.saveSessionState(any)).called(greaterThan(0));
      
      // This is the fixed scenario - we start fresh, avoiding stale backup data
      // which should allow AR mode to work properly
    });

    test('VERIFICATION: Fix only affects explicit AR mode button usage', () async {
      // Test that the fix is surgical - it only affects the AR mode button behavior
      // Other parts of the app should still use restoration when appropriate
      
      const savedState = ARSessionReady(anchorPlaced: true, anchorId: 'test-anchor');
      when(mockPersistenceService.restoreSessionState()).thenAnswer((_) async => savedState);
      when(mockPersistenceService.restoreAnchorData()).thenAnswer((_) async => {
        'anchorId': 'test-anchor',
        'transform': List.filled(16, 1.0),
        'metadata': {},
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Test that calling without parameters still uses restoration (default behavior)
      await arSessionCubit.initializeARSession(); // Uses default restoreFromPersistence = true
      
      // Verify that restoration was attempted (preserves existing behavior)
      verify(mockPersistenceService.restoreSessionState()).called(1);
      
      // Verify that the state was restored correctly
      expect(arSessionCubit.state, isA<ARSessionReady>());
      final state = arSessionCubit.state as ARSessionReady;
      expect(state.anchorId, 'test-anchor');
      expect(state.anchorPlaced, true);
      
      // This confirms that the fix is surgical and doesn't break existing functionality
    });

    test('LOGS VERIFICATION: Fix addresses the specific log pattern from issue', () async {
      // This test verifies that the fix addresses the exact pattern seen in the debug logs:
      // [2025-07-08T09:06:00.818712] INFO: 📂 Restoring AR session state from storage...
      // [2025-07-08T09:06:00.818831] INFO: ✅ AR session state restored: bka
      
      const savedStateMatchingLogs = ARSessionReady(
        anchorPlaced: true,
        anchorId: 'bka', // This matches the "bka" from the actual logs
      );
      
      when(mockPersistenceService.restoreSessionState()).thenAnswer((_) async => savedStateMatchingLogs);
      when(mockPersistenceService.saveSessionState(any)).thenAnswer((_) async {});

      // With the fix, this should bypass restoration entirely
      await arSessionCubit.initializeARSession(restoreFromPersistence: false);

      // Verify that we DON'T see the problematic log pattern
      // "📂 Restoring AR session state from storage..." should NOT happen
      verifyNever(mockPersistenceService.restoreSessionState());
      
      // Verify fresh initialization instead
      verify(mockPersistenceService.saveSessionState(any)).called(greaterThan(0));
      
      // This confirms that the fix addresses the exact scenario from the issue logs
    });
  });
}