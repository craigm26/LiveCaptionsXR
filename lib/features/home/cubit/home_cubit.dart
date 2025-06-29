import 'package:flutter_bloc/flutter_bloc.dart';

class HomeState {
  final bool demoMode;
  HomeState({this.demoMode = false});

  HomeState copyWith({bool? demoMode}) => HomeState(demoMode: demoMode ?? this.demoMode);
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState());

  void toggleDemoMode() => emit(state.copyWith(demoMode: !state.demoMode));
  // Add methods and state for AR fusion here
} 