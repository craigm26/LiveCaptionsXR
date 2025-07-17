import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

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

  void toggleArMode() {
    final newMode = !state.arMode;
    _logger.i('🥽 Toggling AR mode: ${state.arMode} -> $newMode');
    emit(state.copyWith(arMode: newMode));
  }
}
