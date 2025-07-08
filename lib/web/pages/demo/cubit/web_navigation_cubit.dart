import 'package:flutter_bloc/flutter_bloc.dart';

/// Sections available in the web demo page.
enum WebSection { home, sound, localization, visual, settings, technology, about }

/// State for [WebNavigationCubit].
class WebNavigationState {
  final bool isDemoActive;
  final WebSection currentSection;

  const WebNavigationState({
    this.isDemoActive = false,
    this.currentSection = WebSection.home,
  });

  WebNavigationState copyWith({bool? isDemoActive, WebSection? currentSection}) {
    return WebNavigationState(
      isDemoActive: isDemoActive ?? this.isDemoActive,
      currentSection: currentSection ?? this.currentSection,
    );
  }
}

/// Simple cubit used to navigate between sections of the web demo and to
/// toggle demo mode.
class WebNavigationCubit extends Cubit<WebNavigationState> {
  WebNavigationCubit() : super(const WebNavigationState());

  /// Navigate to a specific section.
  void navigateToSection(WebSection section) {
    emit(state.copyWith(currentSection: section));
  }

  /// Mark the demo as started.
  void startDemo() {
    emit(state.copyWith(isDemoActive: true));
  }

  /// Stop the demo.
  void stopDemo() {
    emit(state.copyWith(isDemoActive: false));
  }
}
