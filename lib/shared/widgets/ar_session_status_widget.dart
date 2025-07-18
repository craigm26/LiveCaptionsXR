import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/ar_session/cubit/ar_session_cubit.dart';
import '../../features/ar_session/cubit/ar_session_state.dart';

/// Widget that displays AR session status with progress indicators
class ARSessionStatusWidget extends StatelessWidget {
  final VoidCallback? onClose;
  final bool showCloseButton;

  const ARSessionStatusWidget({
    super.key,
    this.onClose,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ARSessionCubit, ARSessionState>(
      builder: (context, state) {
        return _buildStatusContent(context, state);
      },
    );
  }

  Widget _buildStatusContent(BuildContext context, ARSessionState state) {
    if (state is ARSessionInitial) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, state),
          const SizedBox(height: 12),
          _buildStatusBody(context, state),
          if (showCloseButton && state is ARSessionReady) ...[
            const SizedBox(height: 12),
            _buildCloseButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ARSessionState state) {
    IconData icon;
    String title;
    Color color;

    switch (state.runtimeType) {
      case ARSessionConfiguring:
        icon = Icons.settings;
        title = 'Configuring AR Session';
        color = Colors.blue;
        break;
      case ARSessionInitializing:
        icon = Icons.view_in_ar;
        title = 'Initializing AR Session';
        color = Colors.blue;
        break;
      case ARSessionCalibrating:
        icon = Icons.tune;
        title = 'Calibrating Device';
        color = Colors.orange;
        break;
      case ARSessionStartingServices:
        icon = Icons.rocket_launch;
        title = 'Starting Services';
        color = Colors.green;
        break;
      case ARSessionReady:
        icon = Icons.check_circle;
        title = 'AR Session Ready';
        color = Colors.green;
        break;
      case ARSessionError:
        icon = Icons.error;
        title = 'AR Session Error';
        color = Colors.red;
        break;
      case ARSessionStopping:
        icon = Icons.stop;
        title = 'Stopping AR Session';
        color = Colors.orange;
        break;
      default:
        icon = Icons.info;
        title = 'AR Session Status';
        color = Colors.grey;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBody(BuildContext context, ARSessionState state) {
    switch (state.runtimeType) {
      case ARSessionConfiguring:
        return _buildConfiguringStatus(state as ARSessionConfiguring);
      case ARSessionInitializing:
        return _buildInitializingStatus();
      case ARSessionCalibrating:
        return _buildCalibratingStatus(state as ARSessionCalibrating);
      case ARSessionStartingServices:
        return _buildStartingServicesStatus(state as ARSessionStartingServices);
      case ARSessionSTTProcessing:
        return _buildSTTProcessingStatus(state as ARSessionSTTProcessing);
      case ARSessionContextualEnhancement:
        return _buildContextualEnhancementStatus(state as ARSessionContextualEnhancement);
      case ARSessionReady:
        return _buildReadyStatus(state as ARSessionReady);
      case ARSessionError:
        return _buildErrorStatus(state as ARSessionError);
      case ARSessionStopping:
        return _buildStoppingStatus();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildConfiguringStatus(ARSessionConfiguring state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Setting up AR environment...',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(
          '${(state.progress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInitializingStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Initializing AR components...',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        const LinearProgressIndicator(
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 4),
        const Text(
          'Please wait...',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCalibratingStatus(ARSessionCalibrating state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calibrating ${state.calibrationType}...',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
        const SizedBox(height: 4),
        Text(
          '${(state.progress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStartingServicesStatus(ARSessionStartingServices state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Starting AR services...',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: state.overallProgress,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
        const SizedBox(height: 4),
        Text(
          '${(state.overallProgress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...state.serviceStatuses.values.map((service) => _buildServiceStatus(service)),
      ],
    );
  }

  Widget _buildSTTProcessingStatus(ARSessionSTTProcessing state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(state.isOnline ? Icons.cloud : Icons.phone_android, color: state.isOnline ? Colors.blue : Colors.green, size: 18),
            const SizedBox(width: 8),
            Text(
              'Speech-to-Text (${state.backend})',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Text(
              state.isOnline ? 'Cloud' : 'On-device',
              style: TextStyle(color: state.isOnline ? Colors.blue : Colors.green, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(state.isOnline ? Colors.blue : Colors.green),
        ),
        const SizedBox(height: 4),
        Text(
          state.message ?? '',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildContextualEnhancementStatus(ARSessionContextualEnhancement state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.auto_awesome, color: Colors.purple, size: 18),
            SizedBox(width: 8),
            Text(
              'Contextual Enhancement (Gemma 3n)',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
        ),
        const SizedBox(height: 4),
        Text(
          state.message ?? '',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildServiceStatus(ServiceStatus service) {
    IconData icon;
    Color color;
    String statusText;

    switch (service.state) {
      case ServiceState.pending:
        icon = Icons.schedule;
        color = Colors.grey;
        statusText = 'Pending';
        break;
      case ServiceState.starting:
        icon = Icons.play_arrow;
        color = Colors.blue;
        statusText = 'Starting...';
        break;
      case ServiceState.running:
        icon = Icons.check_circle;
        color = Colors.green;
        statusText = 'Running';
        break;
      case ServiceState.error:
        icon = Icons.error;
        color = Colors.red;
        statusText = 'Error';
        break;
      case ServiceState.stopped:
        icon = Icons.stop;
        color = Colors.orange;
        statusText = 'Stopped';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              service.serviceName,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Text(
            statusText,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyStatus(ARSessionReady state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AR session is ready!',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              state.servicesStarted ? Icons.check_circle : Icons.info,
              color: state.servicesStarted ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              state.servicesStarted ? 'All services running' : 'Services not started',
              style: TextStyle(
                color: state.servicesStarted ? Colors.green : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        if (state.anchorPlaced) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.anchor, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              const Text(
                'AR anchor placed',
                style: TextStyle(color: Colors.blue, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildErrorStatus(ARSessionError state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.message,
          style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        if (state.details != null) ...[
          const SizedBox(height: 4),
          Text(
            state.details!,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildStoppingStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stopping AR session...',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        const LinearProgressIndicator(
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
        const SizedBox(height: 4),
        const Text(
          'Please wait...',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onClose ?? () {
          context.read<ARSessionCubit>().stopARSession();
        },
        icon: const Icon(Icons.close, size: 18),
        label: const Text('Close AR Session'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
} 