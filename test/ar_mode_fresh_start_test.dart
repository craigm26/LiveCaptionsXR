import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:live_captions_xr/features/ar_session/cubit/ar_session_cubit.dart';
import 'package:live_captions_xr/features/ar_session/cubit/ar_session_state.dart';
import 'package:live_captions_xr/core/services/ar_session_persistence_service.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';

import 'features/ar_session/cubit/ar_session_cubit_test.mocks.dart';

// Generate mocks for testing  
@GenerateMocks([
  ARSessionPersistenceService,
  HybridLocalizationEngine,
])

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AR Session Fresh Start Tests', () {
    late MockARSessionPersistenceService mockPersistenceService;
    late MockHybridLocalizationEngine mockHybridLocalizationEngine;
    late ARSessionCubit arSessionCubit;

    setUp(() {
      // Set up mock shared preferences
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

    test('initializeARSession with restoreFromPersistence=false bypasses backup restoration', () async {
      // Setup mock persistence service to return a saved state
      const savedState = ARSessionReady(
        anchorPlaced: true,
        anchorId: 'old-backup-anchor',
      );
      
      when(mockPersistenceService.restoreSessionState()).thenAnswer((_) async => savedState);
      when(mockPersistenceService.saveSessionState(any)).thenAnswer((_) async {});

      // Call initializeARSession with restoreFromPersistence=false (the fix)
      await arSessionCubit.initializeARSession(restoreFromPersistence: false);

      // Verify that restoreSessionState was NOT called
      // This is the key test - it proves we bypass backup restoration
      verifyNever(mockPersistenceService.restoreSessionState());
      
      // Verify that we saved the new session state (part of fresh init)
      verify(mockPersistenceService.saveSessionState(any)).called(greaterThan(0));
    });

    test('initializeARSession with restoreFromPersistence=true attempts backup restoration', () async {
      // Setup mock persistence service to return a saved state
      const savedState = ARSessionReady(
        anchorPlaced: true,
        anchorId: 'old-backup-anchor',
      );
      
      when(mockPersistenceService.restoreSessionState()).thenAnswer((_) async => savedState);
      when(mockPersistenceService.restoreAnchorData()).thenAnswer((_) async => {
        'anchorId': 'old-backup-anchor',
        'transform': List.filled(16, 1.0),
        'metadata': {},
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Call initializeARSession with restoreFromPersistence=true (default behavior)
      await arSessionCubit.initializeARSession(restoreFromPersistence: true);

      // Verify that restoreSessionState WAS called
      verify(mockPersistenceService.restoreSessionState()).called(1);
      
      // Verify that the session was restored to the saved state
      expect(arSessionCubit.state, isA<ARSessionReady>());
      final state = arSessionCubit.state as ARSessionReady;
      expect(state.anchorId, 'old-backup-anchor');
      expect(state.anchorPlaced, true);
    });

    test('initializeARSession with restoreFromPersistence=false starts fresh when no backup exists', () async {
      // Setup mock persistence service to return null (no saved state)
      when(mockPersistenceService.restoreSessionState()).thenAnswer((_) async => null);
      when(mockPersistenceService.saveSessionState(any)).thenAnswer((_) async {});

      // Call initializeARSession with restoreFromPersistence=false
      await arSessionCubit.initializeARSession(restoreFromPersistence: false);

      // Verify that restoreSessionState was NOT called even though there's no backup
      verifyNever(mockPersistenceService.restoreSessionState());
      
      // Verify that we saved the new session state (part of fresh init)
      verify(mockPersistenceService.saveSessionState(any)).called(greaterThan(0));
      
      // Verify that session reached ready state
      expect(arSessionCubit.state, isA<ARSessionReady>());
    });
  });
}