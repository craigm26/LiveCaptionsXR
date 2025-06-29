// Placeholder for LocalizationCubit
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LocalizationState {}

class LocalizationInitial extends LocalizationState {}
class LocalizationLoaded extends LocalizationState {
  final String direction; // e.g., 'left', 'right', 'center'
  final double confidence;
  LocalizationLoaded(this.direction, this.confidence);
}

class LocalizationCubit extends Cubit<LocalizationState> {
  LocalizationCubit() : super(LocalizationInitial());

  void localize(String direction, double confidence) {
    emit(LocalizationLoaded(direction, confidence));
  }
} 