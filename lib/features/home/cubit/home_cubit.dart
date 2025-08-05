import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/app_logger.dart';

class HomeState {
  final bool arMode;
  HomeState({this.arMode = false});

  HomeState copyWith({bool? arMode}) =>
      HomeState(arMode: arMode ?? this.arMode);
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());

  final AppLogger _logger = AppLogger.instance;

  void toggleArMode() {
    final newMode = !state.arMode;
    _logger.i('🥽 Toggling AR mode: ${state.arMode} -> $newMode', category: LogCategory.ui);
    emit(state.copyWith(arMode: newMode));
  }
}
