import 'package:flutter_bloc/flutter_bloc.dart';

class HomeState {
  final bool demoMode;
  final bool arMode;
  HomeState({this.demoMode = false, this.arMode = false});

  HomeState copyWith({bool? demoMode, bool? arMode}) =>
      HomeState(demoMode: demoMode ?? this.demoMode, arMode: arMode ?? this.arMode);
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());

  void toggleDemoMode() => emit(state.copyWith(demoMode: !state.demoMode));
  void toggleArMode() => emit(state.copyWith(arMode: !state.arMode));
  // Add methods and state for AR fusion here
} 