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

/// AR session is being configured with initial settings
class ARSessionConfiguring extends ARSessionState {
  final String configurationType;
  final double progress;
  
  const ARSessionConfiguring({
    this.configurationType = 'basic',
    this.progress = 0.0,
  });

  @override
  List<Object?> get props => [configurationType, progress];
}

/// AR session is being initialized
class ARSessionInitializing extends ARSessionState {
  const ARSessionInitializing();
}

/// AR session is calibrating the device/environment
class ARSessionCalibrating extends ARSessionState {
  final double progress;
  final String calibrationType;
  
  const ARSessionCalibrating({
    this.progress = 0.0,
    this.calibrationType = 'basic',
  });

  @override
  List<Object?> get props => [progress, calibrationType];
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

/// AR session has lost tracking (temporary issue)
class ARSessionTrackingLost extends ARSessionState {
  final String reason;
  final DateTime lostAt;
  
  const ARSessionTrackingLost({
    required this.reason,
    required this.lostAt,
  });

  @override
  List<Object?> get props => [reason, lostAt];
}

/// AR session is attempting to reconnect/restore tracking
class ARSessionReconnecting extends ARSessionState {
  final int attempt;
  final String? previousAnchorId;
  
  const ARSessionReconnecting({
    this.attempt = 1,
    this.previousAnchorId,
  });

  @override
  List<Object?> get props => [attempt, previousAnchorId];
}

/// AR session is paused (e.g., app in background)
class ARSessionPaused extends ARSessionState {
  final bool previousAnchorPlaced;
  final String? previousAnchorId;
  final DateTime pausedAt;
  
  const ARSessionPaused({
    this.previousAnchorPlaced = false,
    this.previousAnchorId,
    required this.pausedAt,
  });

  @override
  List<Object?> get props => [previousAnchorPlaced, previousAnchorId, pausedAt];
}

/// AR session is resuming from paused state
class ARSessionResuming extends ARSessionState {
  final String? restoringAnchorId;
  final double progress;
  
  const ARSessionResuming({
    this.restoringAnchorId,
    this.progress = 0.0,
  });

  @override
  List<Object?> get props => [restoringAnchorId, progress];
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