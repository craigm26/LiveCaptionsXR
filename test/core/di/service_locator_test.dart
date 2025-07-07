import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/di/service_locator.dart';
import 'package:live_captions_xr/core/services/hybrid_localization_engine.dart';

void main() {
  group('Service Locator', () {
    setUp(() {
      // Reset service locator before each test
      sl.reset();
    });

    tearDown(() {
      // Clean up after each test
      sl.reset();
    });

    test('setupServiceLocator registers HybridLocalizationEngine as singleton', () {
      // Act
      setupServiceLocator();

      // Assert
      expect(sl.isRegistered<HybridLocalizationEngine>(), true);
      
      // Verify it's a singleton - same instance should be returned
      final instance1 = sl<HybridLocalizationEngine>();
      final instance2 = sl<HybridLocalizationEngine>();
      expect(identical(instance1, instance2), true);
    });

    test('HybridLocalizationEngine is registered as lazy singleton', () {
      // Arrange
      setupServiceLocator();

      // Act - Get the instance
      final instance = sl<HybridLocalizationEngine>();

      // Assert
      expect(instance, isA<HybridLocalizationEngine>());
    });

    test('can resolve HybridLocalizationEngine after setup', () {
      // Arrange
      setupServiceLocator();

      // Act & Assert - Should not throw
      expect(() => sl<HybridLocalizationEngine>(), returnsNormally);
    });

    test('throws error when trying to resolve unregistered service', () {
      // Arrange - Don't call setupServiceLocator

      // Act & Assert
      expect(() => sl<HybridLocalizationEngine>(), throwsA(isA<AssertionError>()));
    });
  });
}