import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/debug_capturing_logger.dart';

abstract class LocalizationState {}

class LocalizationInitial extends LocalizationState {}
class LocalizationLoaded extends LocalizationState {
  final String direction; // e.g., 'left', 'right', 'center'
  final double confidence;
  LocalizationLoaded(this.direction, this.confidence);
}

class LocalizationCubit extends Cubit<LocalizationState> {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  bool _isActive = false;

  LocalizationCubit() : super(LocalizationInitial());

  bool get isActive => _isActive;

  Future<void> start() async {
    if (_isActive) return;
    _logger.i('🧭 Starting Localization...');
    // In a real app, you would initialize the native localization here.
    _isActive = true;
    _logger.i('✅ Localization started.');
  }

  Future<void> stop() async {
    if (!_isActive) return;
    _logger.i('🧭 Stopping Localization...');
    // In a real app, you would stop the native localization here.
    _isActive = false;
    _logger.i('✅ Localization stopped.');
  }

  void localize(String direction, double confidence) {
    if (!_isActive) return;
    emit(LocalizationLoaded(direction, confidence));
  }
}