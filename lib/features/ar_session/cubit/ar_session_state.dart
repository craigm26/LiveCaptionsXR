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

/// AR session is starting services
class ARSessionStartingServices extends ARSessionState {
  final Map<String, ServiceStatus> serviceStatuses;
  final double overallProgress;
  
  const ARSessionStartingServices({
    this.serviceStatuses = const {},
    this.overallProgress = 0.0,
  });

  @override
  List<Object?> get props => [serviceStatuses, overallProgress];

  ARSessionStartingServices copyWith({
    Map<String, ServiceStatus>? serviceStatuses,
    double? overallProgress,
  }) {
    return ARSessionStartingServices(
      serviceStatuses: serviceStatuses ?? this.serviceStatuses,
      overallProgress: overallProgress ?? this.overallProgress,
    );
  }
}

/// AR session is ready and fully initialized
class ARSessionReady extends ARSessionState {
  final bool anchorPlaced;
  final String? anchorId;
  final bool servicesStarted;

  const ARSessionReady({
    this.anchorPlaced = false,
    this.anchorId,
    this.servicesStarted = false,
  });

  @override
  List<Object?> get props => [anchorPlaced, anchorId, servicesStarted];

  ARSessionReady copyWith({
    bool? anchorPlaced,
    String? anchorId,
    bool? servicesStarted,
  }) {
    return ARSessionReady(
      anchorPlaced: anchorPlaced ?? this.anchorPlaced,
      anchorId: anchorId ?? this.anchorId,
      servicesStarted: servicesStarted ?? this.servicesStarted,
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

/// Represents the status of individual services during startup
class ServiceStatus extends Equatable {
  final String serviceName;
  final ServiceState state;
  final String? message;
  final double? progress;

  const ServiceStatus({
    required this.serviceName,
    required this.state,
    this.message,
    this.progress,
  });

  @override
  List<Object?> get props => [serviceName, state, message, progress];

  ServiceStatus copyWith({
    String? serviceName,
    ServiceState? state,
    String? message,
    double? progress,
  }) {
    return ServiceStatus(
      serviceName: serviceName ?? this.serviceName,
      state: state ?? this.state,
      message: message ?? this.message,
      progress: progress ?? this.progress,
    );
  }
}

/// Enum for service states
enum ServiceState {
  pending,
  starting,
  running,
  error,
  stopped,
}

/// AR session is processing speech-to-text (STT)
class ARSessionSTTProcessing extends ARSessionState {
  final String backend; // e.g., 'Google', 'Azure', 'Whisper'
  final bool isOnline;
  final double progress;
  final String? message;

  const ARSessionSTTProcessing({
    required this.backend,
    required this.isOnline,
    this.progress = 0.0,
    this.message,
  });

  @override
  List<Object?> get props => [backend, isOnline, progress, message];
}

/// AR session is running contextual enhancement (Gemma 3n)
class ARSessionContextualEnhancement extends ARSessionState {
  final double progress;
  final String? message;

  const ARSessionContextualEnhancement({
    this.progress = 0.0,
    this.message,
  });

  @override
  List<Object?> get props => [progress, message];
}