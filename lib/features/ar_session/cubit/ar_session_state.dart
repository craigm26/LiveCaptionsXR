import 'package:equatable/equatable.dart';

/// Represents the different states of an AR session
abstract class ARSessionState extends Equatable {
  const ARSessionState();

  @override
  List<Object?> get props => [];
}

/// Initial state before AR session is started
class ARSessionInitial extends ARSessionState {
  const ARSessionInitial();
}

/// AR session is being initialized
class ARSessionInitializing extends ARSessionState {
  const ARSessionInitializing();
}

/// AR session is ready and operational
class ARSessionReady extends ARSessionState {
  final bool anchorPlaced;
  final String? anchorId;

  const ARSessionReady({
    this.anchorPlaced = false,
    this.anchorId,
  });

  @override
  List<Object?> get props => [anchorPlaced, anchorId];

  ARSessionReady copyWith({
    bool? anchorPlaced,
    String? anchorId,
  }) {
    return ARSessionReady(
      anchorPlaced: anchorPlaced ?? this.anchorPlaced,
      anchorId: anchorId ?? this.anchorId,
    );
  }
}

/// AR session encountered an error
class ARSessionError extends ARSessionState {
  final String message;
  final String? details;
  final String? errorCode;

  const ARSessionError({
    required this.message,
    this.details,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, details, errorCode];
}

/// AR session is stopping
class ARSessionStopping extends ARSessionState {
  const ARSessionStopping();
}