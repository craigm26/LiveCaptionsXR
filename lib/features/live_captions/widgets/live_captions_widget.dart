import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/live_captions_cubit.dart';
import '../cubit/live_captions_state.dart';
import '../../../core/models/speech_result.dart';
import '../../localization/cubit/localization_cubit.dart';
import '../../translation/cubit/translation_cubit.dart';
import '../../translation/cubit/translation_state.dart';

/// Widget for displaying live captions with spatial awareness, speaker diarization,
/// and translation support in AR/XR style.
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
  late AnimationController _slideController;
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

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
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
        const SizedBox(width: 8),
        // Spatial direction badge
        _buildDirectionBadge(context),
        const Spacer(),
        // Translation status indicator
        _buildTranslationBadge(context),
        const SizedBox(width: 4),
        _buildActionButtons(context, state),
      ],
    );
  }

  /// Direction badge from LocalizationCubit
  Widget _buildDirectionBadge(BuildContext context) {
    return BlocBuilder<LocalizationCubit, LocalizationState>(
      builder: (context, state) {
        if (state is! LocalizationLoaded) return const SizedBox.shrink();

        final icon = switch (state.direction) {
          'left' => Icons.arrow_back,
          'right' => Icons.arrow_forward,
          'center' => Icons.arrow_upward,
          _ => Icons.hearing,
        };

        final color = state.confidence >= 0.7
            ? Colors.greenAccent
            : Colors.orangeAccent;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 2),
              Text(
                state.direction,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Translation active indicator
  Widget _buildTranslationBadge(BuildContext context) {
    try {
      return BlocBuilder<TranslationCubit, TranslationState>(
        builder: (context, state) {
          if (state is! TranslationReady || !state.isEnabled) {
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate, color: Colors.lightBlueAccent, size: 12),
                const SizedBox(width: 3),
                Text(
                  '${state.sourceLanguage.code}→${state.targetLanguage.code}',
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      // TranslationCubit not provided — skip
      return const SizedBox.shrink();
    }
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

    final currentText = state.currentCaption?.text ??
        (state.captions.isNotEmpty ? state.captions.last.text : null);

    if (currentText == null || currentText.isEmpty) {
      return _buildPlaceholder(context, state);
    }

    final caption = state.currentCaption ?? (state.captions.isNotEmpty ? state.captions.last : null);
    final isInterim = state.currentCaption != null;

    // Determine spatial alignment based on speaker direction
    final alignment = _getSpatialAlignment(caption);
    final borderColor = isInterim
        ? Colors.orange.withAlpha((255 * 0.6).round())
        : Colors.blue.withAlpha((255 * 0.6).round());

    return AnimatedAlign(
      alignment: alignment,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: widget.maxWidth * 0.85),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((255 * 0.85).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speaker label row
            if (caption?.hasSpeakerDiarization == true) ...[
              _buildSpeakerLabel(caption!),
              const SizedBox(height: 6),
            ],
            // Caption text
            Text(
              currentText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.4,
                  ),
            ),
            // Metadata row
            if (state.currentCaption != null) ...[
              const SizedBox(height: 8),
              _buildMetadataRow(context, state.currentCaption!),
            ],
          ],
        ),
      ),
    );
  }

  /// Compute alignment from speaker direction for spatial positioning
  Alignment _getSpatialAlignment(SpeechResult? caption) {
    final direction = caption?.speakerDirection;
    switch (direction) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      case 'center':
      default:
        return Alignment.center;
    }
  }

  /// Speaker label with color from diarization
  Widget _buildSpeakerLabel(SpeechResult caption) {
    final color = caption.speakerColor != null
        ? Color(caption.speakerColor!)
        : Colors.tealAccent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          caption.speakerLabel,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (caption.speakerConfidence != null) ...[
          const SizedBox(width: 4),
          Text(
            '${(caption.speakerConfidence! * 100).toStringAsFixed(0)}%',
            style: TextStyle(color: color.withOpacity(0.6), fontSize: 10),
          ),
        ],
      ],
    );
  }

  Widget _buildMetadataRow(BuildContext context, SpeechResult caption) {
    return Row(
      children: [
        Icon(Icons.mic, size: 14, color: Colors.orange.withAlpha((255 * 0.7).round())),
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
          '${(caption.confidence * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange.withAlpha((255 * 0.7).round()),
              ),
        ),
      ],
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

  Widget _buildPlaceholder(BuildContext context, LiveCaptionsState state) {
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

  Widget _buildHistoryItem(BuildContext context, SpeechResult caption, int index) {
    final dirIcon = switch (caption.speakerDirection) {
      'left' => Icons.arrow_back,
      'right' => Icons.arrow_forward,
      'center' => Icons.arrow_upward,
      _ => null,
    };

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
          // Speaker direction icon or index
          if (dirIcon != null)
            Icon(dirIcon, color: Colors.white54, size: 14)
          else
            Text(
              '${index + 1}.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          const SizedBox(width: 8),
          // Speaker label
          if (caption.hasSpeakerDiarization) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 6, right: 4),
              decoration: BoxDecoration(
                color: caption.speakerColor != null
                    ? Color(caption.speakerColor!)
                    : Colors.tealAccent,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Expanded(
            child: Text(
              caption.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
          Text(
            '${(caption.confidence * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
