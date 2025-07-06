import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../core/services/hybrid_localization_engine.dart';

class HomeState {
  final bool arMode;
  HomeState({this.arMode = false});

  HomeState copyWith({bool? arMode}) =>
      HomeState(arMode: arMode ?? this.arMode);
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  final HybridLocalizationEngine hybridLocalizationEngine =
      HybridLocalizationEngine();

  void toggleArMode() {
    final newMode = !state.arMode;
    _logger.i('🥽 Toggling AR mode: ${state.arMode} -> $newMode');
    emit(state.copyWith(arMode: newMode));
  }

  Future<void> updateWithAudioMeasurement({
    required double angle,
    required double confidence,
    required List<double> deviceTransform,
  }) async {
    _logger.i(
        '🎵 Updating with audio measurement - Angle: ${angle.toStringAsFixed(3)}, Confidence: ${confidence.toStringAsFixed(3)}');

    try {
      await hybridLocalizationEngine.updateWithAudioMeasurement(
        angle: angle,
        confidence: confidence,
        deviceTransform: deviceTransform,
      );
      _logger.i('✅ Audio measurement updated successfully');
    } catch (e) {
      _logger.e('❌ Failed to update audio measurement: $e');
      rethrow;
    }
  }

  Future<void> updateWithVisualMeasurement({
    required List<double> transform,
    required double confidence,
  }) async {
    _logger.i(
        '👁️ Updating with visual measurement - Confidence: ${confidence.toStringAsFixed(3)}, Transform: [${transform.take(4).map((v) => v.toStringAsFixed(2)).join(', ')}...]');

    try {
      await hybridLocalizationEngine.updateWithVisualMeasurement(
        transform: transform,
        confidence: confidence,
      );
      _logger.i('✅ Visual measurement updated successfully');
    } catch (e) {
      _logger.e('❌ Failed to update visual measurement: $e');
      rethrow;
    }
  }

  Future<List<double>> getFusedTransform() async {
    _logger.i('🔄 Getting fused transform from hybrid localization engine');

    try {
      final transform = await hybridLocalizationEngine.getFusedTransform();
      _logger.i(
          '✅ Fused transform retrieved: [${transform.take(4).map((v) => v.toStringAsFixed(2)).join(', ')}...]');
      return transform;
    } catch (e) {
      _logger.e('❌ Failed to get fused transform: $e');
      rethrow;
    }
  }
}
