import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../cubit/live_captions_cubit.dart';
import '../cubit/live_captions_state.dart';
import '../../../core/models/speech_result.dart';
import 'package:live_captions_xr/spatial_intel/predict/predictive_caption_engine.dart';
import 'package:live_captions_xr/spatial_intel/ui/ghost_caption_widget.dart';
import 'package:live_captions_xr/spatial_intel/decoding/decode_policy.dart';

/// Widget for displaying live captions in AR/XR style
class LiveCaptionsWidget extends StatefulWidget {
  final VoidCallback? onToggle;
  final VoidCallback? onClear;
  final EdgeInsets padding;
  final double maxWidth;
  final bool showHistory;

  const LiveCaptionsWidget({
    Key? key,
    this.onToggle,
    this.onClear,
    this.padding = const EdgeInsets.all(16.0),
    this.maxWidth = 400.0,
    this.showHistory = false,
  }) : super(key: key);

  @override
  State<LiveCaptionsWidget> createState() => _LiveCaptionsWidgetState();
}

class _LiveCaptionsWidgetState extends State<LiveCaptionsWidget>
    with TickerProviderStateMixin {
  

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LiveCaptionsCubit, LiveCaptionsState>(
      listener: (context, state) {
        if (state is LiveCaptionsActive && state.isListening) {
          _fadeController.forward();
        } else {
          _fadeController.reverse();
        }
      },
      builder: (context, state) {
        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: _buildCaptionsContent(context, state),
            );
          },
        );
      },
    );
  }

  Widget _buildCaptionsContent(BuildContext context, LiveCaptionsState state) {
    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, state),
          const SizedBox(height: 8),
          _buildCurrentCaption(context, state),
          if (widget.showHistory) ...[
            const SizedBox(height: 12),
            _buildCaptionHistory(context, state),
          ],
          if (state is LiveCaptionsActive && state.error != null) ...[
            const SizedBox(height: 8),
            _buildErrorMessage(state.error!),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LiveCaptionsState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIndicator(state),
        const SizedBox(width: 8),
        Text(
          'Live Captions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        _buildActionButtons(context, state),
      ],
    );
  }

  Widget _buildStatusIndicator(LiveCaptionsState state) {
    if (state is LiveCaptionsLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      );
    }

    if (state is LiveCaptionsActive && state.isListening) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      );
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.grey[600],
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, LiveCaptionsState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onClear != null)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white, size: 20),
            onPressed: widget.onClear,
            tooltip: 'Clear Captions',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        const SizedBox(width: 4),
        if (widget.onToggle != null)
          IconButton(
            icon: Icon(
              (state is LiveCaptionsActive && state.isListening)
                  ? Icons.stop
                  : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
            onPressed: widget.onToggle,
            tooltip: (state is LiveCaptionsActive && state.isListening)
                ? 'Stop Captions'
                : 'Start Captions',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildCurrentCaption(BuildContext context, LiveCaptionsState state) {
    if (state is! LiveCaptionsActive) {
      return _buildPlaceholder(context, state);
    }

    final SpeechResult? currentResult = _resolveCurrentResult(state);
    final currentText = currentResult?.text;
    final predictiveState = state.predictiveState;
    final DecodePolicy policy = GetIt.I.isRegistered<PredictiveCaptionEngine>()
        ? GetIt.I<PredictiveCaptionEngine>().policy
        : DecodePolicy.defaultPolicy();
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white,
          fontSize: 18,
          height: 1.4,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 18,
          height: 1.4,
        );

    if (currentText == null || currentText.isEmpty) {
      return _buildPlaceholder(context, state);
    }

    final isInterim = state.currentCaption != null;
    final speakerDetails = _extractSpeakerDetails(currentResult);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((255 * 0.8).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInterim
              ? Colors.orange.withAlpha((255 * 0.6).round())
              : Colors.blue.withAlpha((255 * 0.6).round()),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.5).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          predictiveState != null
              ? GhostCaptionWidget(
                  state: predictiveState,
                  policy: policy,
                  baseStyle: textStyle,
                )
              : Text(
                  currentText,
                  style: textStyle,
                ),
          if (state.currentCaption != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.mic,
                  size: 14,
                  color: Colors.orange.withAlpha((255 * 0.7).round()),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Processing...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.withAlpha((255 * 0.7).round()),
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'p=${((predictiveState?.spanProbability ??
                              state.currentCaption!.confidence) *
                          100)
                      .toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.withAlpha((255 * 0.7).round()),
                      ),
                ),
              ],
            ),
          ],
          if (speakerDetails != null) ...[
            const SizedBox(height: 10),
            _SpeakerAttributionChip(
              details: speakerDetails,
              isInterim: isInterim,
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildCaptionHistory(BuildContext context, LiveCaptionsState state) {
    if (state is! LiveCaptionsActive || state.captions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((255 * 0.5).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: state.captions.length,
        itemBuilder: (context, index) {
          final caption = state.captions[index];
          return _buildHistoryItem(context, caption, index);
        },
      ),
    );
  }

  Widget _buildPlaceholder(
      BuildContext context, LiveCaptionsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((255 * 0.8).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state is LiveCaptionsLoading 
              ? Colors.orange.withAlpha((255 * 0.6).round())
              : Colors.grey.withAlpha((255 * 0.6).round()),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state is LiveCaptionsLoading) ...[
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.message ?? 'Initializing...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.orange,
                          fontSize: 18,
                        ),
                  ),
                ),
              ],
            ),
            if (state.progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.grey.withAlpha((255 * 0.3).round()),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(state.progress! * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.withAlpha((255 * 0.7).round()),
                    ),
              ),
            ],
          ] else ...[
            Text(
              'Waiting for captions...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
      BuildContext context, SpeechResult caption, int index) {
    final speakerDetails = _extractSpeakerDetails(caption);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withAlpha((255 * 0.2).round()),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                if (speakerDetails != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Face ${speakerDetails.faceId} • ${(speakerDetails.confidence * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blueGrey[200],
                            fontSize: 11,
                          ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${(caption.confidence * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha((255 * 0.2).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withAlpha((255 * 0.5).round()),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  SpeechResult? _resolveCurrentResult(LiveCaptionsActive state) {
    return state.currentCaption ??
        (state.captions.isNotEmpty ? state.captions.last : null);
  }

  _SpeakerDetails? _extractSpeakerDetails(SpeechResult? result) {
    final metadata = result?.metadata;
    if (metadata == null) {
      return null;
    }
    final faceId = metadata['speakerFaceId'];
    final confidence = metadata['speakerConfidence'];
    if (faceId is! int || confidence is! num) {
      return null;
    }
    final state = metadata['speakerState'] as String?;
    Rect? bbox;
    final bboxMap = metadata['speakerBoundingBox'];
    if (bboxMap is Map) {
      final left = (bboxMap['left'] as num?)?.toDouble();
      final top = (bboxMap['top'] as num?)?.toDouble();
      final width = (bboxMap['width'] as num?)?.toDouble();
      final height = (bboxMap['height'] as num?)?.toDouble();
      if (left != null && top != null && width != null && height != null) {
        bbox = Rect.fromLTWH(left, top, width, height);
      }
    }
    final transform =
        (metadata['speakerWorldTransform'] as List<dynamic>?)?.cast<double>();
    return _SpeakerDetails(
      faceId: faceId,
      confidence: confidence.toDouble(),
      state: state ?? 'unknown',
      boundingBox: bbox,
      worldTransform: transform,
    );
  }
}

class _SpeakerAttributionChip extends StatelessWidget {
  const _SpeakerAttributionChip({
    required this.details,
    required this.isInterim,
  });

  final _SpeakerDetails details;
  final bool isInterim;

  @override
  Widget build(BuildContext context) {
    final color = isInterim ? Colors.orange : Colors.greenAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_pin_circle, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'Face ${details.faceId} • ${(details.confidence * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (details.boundingBox != null) ...[
            const SizedBox(width: 6),
            Text(
              '@ (${(details.boundingBox!.left * 100).toStringAsFixed(0)}%, ${(details.boundingBox!.top * 100).toStringAsFixed(0)}%)',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpeakerDetails {
  const _SpeakerDetails({
    required this.faceId,
    required this.confidence,
    required this.state,
    this.boundingBox,
    this.worldTransform,
  });

  final int faceId;
  final double confidence;
  final String state;
  final Rect? boundingBox;
  final List<double>? worldTransform;
}
