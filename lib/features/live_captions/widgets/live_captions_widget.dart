import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/live_captions_cubit.dart';
import '../cubit/live_captions_state.dart';
import '../../../core/models/speech_result.dart';
import '../../translation/cubit/translation_cubit.dart';
import '../../translation/cubit/translation_state.dart';

/// Widget for displaying live captions styled after The Last of Us Part II.
///
/// Design: dark semi-transparent backdrop, inline speaker names with unique
/// colors, directional arrows for offscreen speakers, clean sans-serif
/// typography, and minimal chrome. No decorative borders, status badges,
/// or metadata rows in the caption area itself.
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
    this.padding = const EdgeInsets.all(0),
    this.maxWidth = 500.0,
    this.showHistory = false,
  }) : super(key: key);

  @override
  State<LiveCaptionsWidget> createState() => _LiveCaptionsWidgetState();
}

class _LiveCaptionsWidgetState extends State<LiveCaptionsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  /// Fixed speaker-color palette (TLOU2 uses distinct per-speaker colors).
  static const List<Color> _speakerPalette = [
    Color(0xFF4FC3F7), // light blue
    Color(0xFFFFD54F), // amber/yellow
    Color(0xFF81C784), // green
    Color(0xFFE57373), // red/coral
    Color(0xFFBA68C8), // purple
    Color(0xFFFF8A65), // orange
    Color(0xFF4DD0E1), // cyan
    Color(0xFFA1887F), // brown
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCurrentCaption(context, state),
          if (widget.showHistory && state is LiveCaptionsActive && state.captions.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildCaptionHistory(context, state),
          ],
        ],
      ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((255 * 0.75).round()),
        borderRadius: BorderRadius.circular(4),
      ),
      child: _buildCaptionLine(context, caption, currentText, isInterim),
    );
  }

  /// Build a single caption line in TLOU2 style:
  /// [direction arrow] [Speaker Name:] caption text
  Widget _buildCaptionLine(
    BuildContext context,
    SpeechResult? caption,
    String text,
    bool isInterim,
  ) {
    final children = <InlineSpan>[];

    // Directional arrow for offscreen speakers
    final dirArrow = _getDirectionArrow(caption);
    if (dirArrow != null) {
      children.add(TextSpan(
        text: '$dirArrow ',
        style: TextStyle(
          color: Colors.white.withAlpha((255 * 0.7).round()),
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
      ));
    }

    // Speaker name with unique color (inline, TLOU2 style)
    if (caption?.hasSpeakerDiarization == true) {
      final speakerColor = _getSpeakerColor(caption!);
      children.add(TextSpan(
        text: '${caption.speakerLabel}: ',
        style: TextStyle(
          color: speakerColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ));
    }

    // Caption text — white, clean
    children.add(TextSpan(
      text: text,
      style: TextStyle(
        color: isInterim
            ? Colors.white.withAlpha((255 * 0.85).round())
            : Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
    ));

    // Translation indicator (subtle, inline after text)
    final translationSuffix = _getTranslationSuffix();
    if (translationSuffix != null) {
      children.add(TextSpan(
        text: '  $translationSuffix',
        style: TextStyle(
          color: Colors.lightBlueAccent.withAlpha((255 * 0.6).round()),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ));
    }

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: children),
    );
  }

  /// Get direction arrow character for offscreen speakers.
  /// Returns null for center/onscreen (TLOU2 only shows arrows for offscreen).
  String? _getDirectionArrow(SpeechResult? caption) {
    final direction = caption?.speakerDirection;
    switch (direction) {
      case 'left':
        return '\u25C0'; // ◀
      case 'right':
        return '\u25B6'; // ▶
      default:
        return null; // no arrow for center/onscreen
    }
  }

  /// Get a consistent color for a speaker from the palette.
  Color _getSpeakerColor(SpeechResult caption) {
    if (caption.speakerColor != null) {
      return Color(caption.speakerColor!);
    }
    // Hash speaker ID to palette index for consistent color
    final id = caption.speakerId ?? caption.speakerLabel;
    final index = id.hashCode.abs() % _speakerPalette.length;
    return _speakerPalette[index];
  }

  /// Get a short translation suffix like "en→es" if translation is active.
  String? _getTranslationSuffix() {
    try {
      final state = context.read<TranslationCubit>().state;
      if (state is TranslationReady && state.isEnabled) {
        return '${state.sourceLanguage.code}\u2192${state.targetLanguage.code}';
      }
    } catch (_) {
      // TranslationCubit not available
    }
    return null;
  }

  Widget _buildCaptionHistory(BuildContext context, LiveCaptionsState state) {
    if (state is! LiveCaptionsActive || state.captions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show last few captions, fading older ones (TLOU2 style)
    final recentCaptions = state.captions.length > 3
        ? state.captions.sublist(state.captions.length - 3)
        : state.captions;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: recentCaptions.asMap().entries.map((entry) {
        final idx = entry.key;
        final caption = entry.value;
        // Older captions fade out
        final opacity = 0.3 + (0.7 * (idx / recentCaptions.length));
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((255 * 0.5).round()),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _buildHistoryLine(context, caption),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryLine(BuildContext context, SpeechResult caption) {
    final children = <InlineSpan>[];

    // Direction arrow
    final dirArrow = _getDirectionArrow(caption);
    if (dirArrow != null) {
      children.add(TextSpan(
        text: '$dirArrow ',
        style: TextStyle(
          color: Colors.white.withAlpha((255 * 0.5).round()),
          fontSize: 15,
        ),
      ));
    }

    // Speaker name
    if (caption.hasSpeakerDiarization) {
      final color = _getSpeakerColor(caption);
      children.add(TextSpan(
        text: '${caption.speakerLabel}: ',
        style: TextStyle(
          color: color.withAlpha((255 * 0.7).round()),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ));
    }

    // Text
    children.add(TextSpan(
      text: caption.text,
      style: TextStyle(
        color: Colors.white.withAlpha((255 * 0.7).round()),
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.3,
      ),
    ));

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: children),
    );
  }

  Widget _buildPlaceholder(BuildContext context, LiveCaptionsState state) {
    if (state is LiveCaptionsLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha((255 * 0.75).round()),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                state.message ?? 'Initializing...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Inactive / waiting — subtle
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((255 * 0.5).round()),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Captions will appear here',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
