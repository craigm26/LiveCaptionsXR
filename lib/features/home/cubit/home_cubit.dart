import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/hybrid_localization_engine.dart';

class HomeState {
  final bool demoMode;
  final bool arMode;
  HomeState({this.demoMode = false, this.arMode = false});

  HomeState copyWith({bool? demoMode, bool? arMode}) =>
      HomeState(demoMode: demoMode ?? this.demoMode, arMode: arMode ?? this.arMode);
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());

  final HybridLocalizationEngine hybridLocalizationEngine = HybridLocalizationEngine();

  void toggleDemoMode() => emit(state.copyWith(demoMode: !state.demoMode));
  void toggleArMode() => emit(state.copyWith(arMode: !state.arMode));

  Future<void> updateWithAudioMeasurement({
    required double angle,
    required double confidence,
    required List<double> deviceTransform,
  }) async {
    await hybridLocalizationEngine.updateWithAudioMeasurement(
      angle: angle,
      confidence: confidence,
      deviceTransform: deviceTransform,
    );
  }

  Future<void> updateWithVisualMeasurement({
    required List<double> transform,
    required double confidence,
  }) async {
    await hybridLocalizationEngine.updateWithVisualMeasurement(
      transform: transform,
      confidence: confidence,
    );
  }

  Future<List<double>> getFusedTransform() async {
    return await hybridLocalizationEngine.getFusedTransform();
  }
} 