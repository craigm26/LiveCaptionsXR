import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/user_settings.dart';
import '../../settings/cubit/settings_cubit.dart';

import '../cubit/live_captions_cubit.dart';
import '../cubit/live_captions_state.dart';
import '../../../core/models/speech_result.dart';
import '../../translation/cubit/translation_cubit.dart';
import '../../translation/cubit/translation_state.dart';
import '../../localization/cubit/localization_cubit.dart';

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
    super.key,
    this.onToggle,
    this.onClear,
    this.padding = const EdgeInsets.all(0),
    this.maxWidth = 500.0,
    this.showHistory = false,
  });

  @override
  State<LiveCaptionsWidget> createState() => _LiveCaptionsWidgetState();
}

class _LiveCaptionsWidgetState extends State<LiveCaptionsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _didInitializeFadeFromState = false;

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

  static const double _pillRadius = 999;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitializeFadeFromState) return;

    try {
      final state = context.read<LiveCaptionsCubit>().state;
      final isActive = state is LiveCaptionsActive && state.isListening;
      _fadeController.value = isActive ? 1.0 : 0.0;
    } catch (_) {
      _fadeController.value = 1.0;
    }

    _didInitializeFadeFromState = true;
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

  UserSettings _settings(BuildContext context) {
    try {
      return context.watch<SettingsCubit>().state;
    } catch (_) {
      return const UserSettings();
    }
  }

  Widget _buildCaptionsContent(BuildContext context, LiveCaptionsState state) {
    final settings = _settings(context);
    final activeState = state is LiveCaptionsActive ? state : null;
    final isEnhancedActive = activeState != null && activeState.enhancedCaptionsActive;
    return Container(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sticky speaker labels — only when Enhanced Captions is active.
          if (isEnhancedActive) ...[
            _buildStickyLabelBar(context, activeState, settings),
            const SizedBox(height: 4),
          ],
          _buildCurrentCaption(context, state, settings),
          if (widget.showHistory &&
              state is LiveCaptionsActive &&
              state.captions.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildCaptionHistory(context, state, settings),
          ],
        ],
      ),
    );
  }

  /// Builds a horizontal bar with speaker name pills that float at the speaker's
  /// estimated horizontal angle. Labels animate smoothly as angle changes.
  Widget _buildStickyLabelBar(
    BuildContext context,
    LiveCaptionsActive state,
    UserSettings settings,
  ) {
    // Collect unique speakers from current + recent captions.
    final seenIds = <String>{};
    final speakers = <SpeechResult>[];
    final allCaptions = [
      if (state.currentCaption != null) state.currentCaption!,
      ...state.captions.reversed,
    ];
    for (final c in allCaptions) {
      if (c.hasSpeakerDiarization && !seenIds.contains(c.speakerId)) {
        seenIds.add(c.speakerId!);
        speakers.add(c);
      }
    }

    if (speakers.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth.clamp(200.0, widget.maxWidth);
        final activeSpeakerId = state.currentCaption?.speakerId ??
            (state.captions.isNotEmpty ? state.captions.last.speakerId : null);

        return SizedBox(
          height: 28,
          child: Stack(
            clipBehavior: Clip.none,
            children: speakers.map((speaker) {
              final id = speaker.speakerId!;
              final angle = state.speakerAngles[id] ?? _angleFromSpeakerResult(speaker);
              // Map angle (-π/2 .. π/2) to 0..1 normalised position.
              final t = ((angle / (math.pi / 2)) + 1) / 2;
              // Left-edge of label, clamped so it stays within container.
              const labelW = 72.0;
              final left = (containerWidth * t - labelW / 2)
                  .clamp(0.0, containerWidth - labelW);
              final isActive = id == activeSpeakerId;
              final color = _getSpeakerColor(speaker);

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                left: left,
                top: 0,
                child: _buildStickyLabel(speaker, color, isActive, settings),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildStickyLabel(
    SpeechResult speaker,
    Color color,
    bool isActive,
    UserSettings settings,
  ) {
    final fontScale = settings.captionFontSize;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(
        horizontal: 7 * fontScale,
        vertical: 3 * fontScale,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? color.withAlpha((255 * 0.28).round())
            : Colors.black.withAlpha((255 * 0.55).round()),
        borderRadius: BorderRadius.circular(_pillRadius),
        border: Border.all(
          color: color.withAlpha(
              (255 * (isActive ? 0.95 : 0.45)).round()),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Text(
        speaker.speakerLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color.withAlpha((255 * (isActive ? 1.0 : 0.65)).round()),
          fontSize: 11 * fontScale,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  /// Derive an angle from a speaker result when no tracked angle is available.
  static double _angleFromSpeakerResult(SpeechResult result) {
    if (result.speakerPosition != null) {
      final pos = result.speakerPosition!;
      final denom = pos.x.abs() + pos.z.abs().clamp(0.1, double.infinity);
      return pos.x.sign * (pos.x.abs() / denom) * (math.pi / 2);
    }
    switch (result.speakerDirection) {
      case 'left': return -0.785;
      case 'right': return 0.785;
      default: return 0.0;
    }
  }

  Widget _buildCurrentCaption(
    BuildContext context,
    LiveCaptionsState state,
    UserSettings settings,
  ) {
    if (state is! LiveCaptionsActive) {
      return _buildPlaceholder(context, state, settings);
    }

    final currentText = state.currentCaption?.text ??
        (state.captions.isNotEmpty ? state.captions.last.text : null);

    if (currentText == null || currentText.isEmpty) {
      return _buildPlaceholder(context, state, settings);
    }

    // "Listening..." is an activity fallback — not real speech.
    // Per TLOU2 style: show nothing, not a spinner or status text.
    if (currentText.trim() == 'Listening...') {
      return const SizedBox.shrink();
    }

    final caption = state.currentCaption ??
        (state.captions.isNotEmpty ? state.captions.last : null);
    final isInterim = state.currentCaption != null;
    final highContrast = settings.highContrastEnabled ||
        settings.accessibilityCaptionModeEnabled;
    final speakerFocus = settings.speakerFocusModeEnabled;
    final showSpeakerBadge =
        speakerFocus && caption?.hasSpeakerDiarization == true;
    final badgeGap = 4 * settings.captionFontSize;

    return Container(
      // TLOU2 style: tight, subtle — almost invisible backing, not a card.
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black
            .withAlpha((255 * (highContrast ? 0.82 : 0.62)).round()),
        // Very slight rounding — TLOU2 uses essentially no rounding
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showSpeakerBadge) ...[
            _buildSpeakerFocusBadge(caption!, settings),
            SizedBox(height: badgeGap),
          ],
          _buildCaptionLine(
            context,
            caption,
            currentText,
            isInterim,
            settings,
          ),
          if (settings.rawSttDebugLineEnabled &&
              state.rawSttDebugText != null &&
              state.rawSttDebugText!.trim().isNotEmpty) ...[
            SizedBox(height: 6 * settings.captionFontSize),
            _buildRawSttDebugLine(settings, state.rawSttDebugText!),
          ],
        ],
      ),
    );
  }

  Widget _buildRawSttDebugLine(UserSettings settings, String rawText) {
    final fontScale = settings.captionFontSize;
    return Text(
      'raw: ${rawText.trim()}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withAlpha((255 * 0.55).round()),
        fontSize: 12 * fontScale,
        fontWeight: FontWeight.w400,
        height: 1.2,
      ),
    );
  }

  Widget _buildSpeakerFocusBadge(SpeechResult caption, UserSettings settings) {
    final color = _getDirectionalSpeakerColor(caption);
    final fontScale = settings.captionFontSize;
    final directionIcon = _getDirectionIcon(caption);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 7.5 * fontScale,
        vertical: 4.5 * fontScale,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.2).round()),
        borderRadius: BorderRadius.circular(_pillRadius),
        border: Border.all(
          color: color.withAlpha((255 * 0.9).round()),
          width: 1,
        ),
      ),
      child: Icon(
        directionIcon ?? Icons.record_voice_over,
        size: 14 * fontScale,
        color: color.withAlpha((255 * 0.95).round()),
      ),
    );
  }

  Widget _buildSpeakerFocusHistoryBadge(
      SpeechResult caption, UserSettings settings) {
    final color = _getDirectionalSpeakerColor(caption);
    final fontScale = settings.captionFontSize;
    final directionIcon = _getDirectionIcon(caption);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6.5 * fontScale,
        vertical: 3.5 * fontScale,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.16).round()),
        borderRadius: BorderRadius.circular(_pillRadius),
        border: Border.all(
          color: color.withAlpha((255 * 0.75).round()),
          width: 1,
        ),
      ),
      child: Icon(
        directionIcon ?? Icons.person,
        size: 11 * fontScale,
        color: color.withAlpha((255 * 0.9).round()),
      ),
    );
  }

  /// Build a single caption line in TLOU2 style:
  /// [direction arrow] [Speaker Name:] caption text
  Widget _buildCaptionLine(
    BuildContext context,
    SpeechResult? caption,
    String text,
    bool isInterim,
    UserSettings settings,
  ) {
    final children = <InlineSpan>[];
    final fontScale = settings.captionFontSize;
    final highContrast = settings.highContrastEnabled ||
        settings.accessibilityCaptionModeEnabled;
    final speakerFocus = settings.speakerFocusModeEnabled;

    // Directional arrow — only show for off-center speakers (TLOU2 style).
    // When Enhanced Captions is active, uses precise angle from localization
    // for a continuously-tracking pointer rather than snapping left/right.
    children.add(WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: BlocBuilder<LocalizationCubit, LocalizationState>(
        builder: (context, locState) {
          String direction = 'center';
          double? preciseAngle;
          if (locState is LocalizationLoaded) {
            direction = locState.direction;
            preciseAngle = locState.angle;
          } else if (caption?.speakerDirection != null) {
            direction = caption!.speakerDirection!;
          }

          // No arrow for center/unknown — TLOU2 only marks off-screen speakers
          if (direction != 'left' && direction != 'right') {
            return const SizedBox.shrink();
          }

          // Enhanced Captions: rotate arrow by precise angle for responsive tracking.
          // Standard: snap to ±90°.
          final double rotation = preciseAngle != null
              ? preciseAngle.clamp(-math.pi / 2, math.pi / 2)
              : (direction == 'left' ? -math.pi / 2 : math.pi / 2);

          return Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: rotation, end: rotation),
              duration: const Duration(milliseconds: 150),
              builder: (context, angle, _) => Transform.rotate(
                angle: angle,
                child: Icon(
                  Icons.play_arrow_rounded,
                  // TLOU2: arrow is same height as the caption text, not oversized
                  size: 14 * fontScale,
                  color: Colors.white
                      .withAlpha((255 * (highContrast ? 1.0 : 0.85)).round()),
                ),
              ),
            ),
          );
        },
      ),
    ));

    // Speaker name with unique color (inline, TLOU2 style)
    if (caption?.hasSpeakerDiarization == true) {
      final speakerColor = _getDirectionalSpeakerColor(caption!);
      final speakerLabel = speakerFocus
          ? '[${caption.speakerLabel.toUpperCase()}]'
          : caption.speakerLabel;

      children.add(TextSpan(
        text: '$speakerLabel: ',
        style: TextStyle(
          color: speakerFocus
              ? speakerColor.withAlpha((255 * 0.95).round())
              : speakerColor,
          // TLOU2: speaker label same size as caption text
          fontSize: 16 * fontScale,
          fontWeight: speakerFocus ? FontWeight.w700 : FontWeight.w600,
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ));
    }

    // Caption text — white, clean, with subtle shadow to pop off any background
    children.add(TextSpan(
      text: text,
      style: TextStyle(
        color: isInterim
            ? Colors.white
                .withAlpha((255 * (highContrast ? 1.0 : 0.88)).round())
            : Colors.white,
        fontSize: 16 * fontScale,
        fontWeight: FontWeight.w500,
        height: 1.3,
        shadows: const [
          Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
    ));

    // Translation indicator (subtle, inline after text)
    final translationSuffix = _getTranslationSuffix();
    if (translationSuffix != null) {
      children.add(TextSpan(
        text: '  $translationSuffix',
        style: TextStyle(
          color: Colors.lightBlueAccent.withAlpha((255 * 0.6).round()),
          fontSize: 12 * fontScale,
          fontWeight: FontWeight.w400,
        ),
      ));
    }

    return RichText(
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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

  IconData? _getDirectionIcon(SpeechResult? caption) {
    final direction = caption?.speakerDirection;
    switch (direction) {
      case 'left':
        return Icons.keyboard_double_arrow_left;
      case 'right':
        return Icons.keyboard_double_arrow_right;
      default:
        return null;
    }
  }

  Color _getDirectionalSpeakerColor(SpeechResult caption) {
    final base = _getSpeakerColor(caption);
    switch (caption.speakerDirection) {
      case 'left':
        return Color.alphaBlend(
          Colors.cyan.withAlpha((255 * 0.18).round()),
          base,
        );
      case 'right':
        return Color.alphaBlend(
          Colors.orange.withAlpha((255 * 0.16).round()),
          base,
        );
      default:
        return base;
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

  Widget _buildCaptionHistory(
    BuildContext context,
    LiveCaptionsState state,
    UserSettings settings,
  ) {
    if (state is! LiveCaptionsActive || state.captions.isEmpty) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final maxHistoryItems = (settings.maxVisibleCaptions - 1).clamp(1, 5);
    final visibleWindow =
        Duration(seconds: settings.captionDurationSeconds.round());
    final recentInWindow = state.captions.where((caption) {
      return now.difference(caption.timestamp) <= visibleWindow;
    }).toList();

    if (recentInWindow.isEmpty) {
      return const SizedBox.shrink();
    }

    // Deduplicate: remove consecutive identical texts (avoids "World. World. World.")
    // Also strip the activity-fallback placeholder from history.
    final deduped = <SpeechResult>[];
    for (final c in recentInWindow) {
      final t = c.text.trim();
      if (t.isEmpty || t == 'Listening...') continue;
      if (deduped.isEmpty || deduped.last.text.trim() != t) {
        deduped.add(c);
      }
    }

    final recentCaptions = deduped.length > maxHistoryItems
        ? deduped.sublist(deduped.length - maxHistoryItems)
        : deduped;

    final highContrast = settings.highContrastEnabled ||
        settings.accessibilityCaptionModeEnabled;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: recentCaptions.asMap().entries.map((entry) {
        final idx = entry.key;
        final caption = entry.value;
        final showSpeakerBadge =
            settings.speakerFocusModeEnabled && caption.hasSpeakerDiarization;
        final badgeGap = 3 * settings.captionFontSize;
        // Older captions fade out
        final opacity = 0.3 + (0.7 * (idx / recentCaptions.length));
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: Colors.black
                  .withAlpha((255 * (highContrast ? 0.75 : 0.5)).round()),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showSpeakerBadge) ...[
                  _buildSpeakerFocusHistoryBadge(caption, settings),
                  SizedBox(height: badgeGap),
                ],
                _buildHistoryLine(context, caption, settings),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryLine(
    BuildContext context,
    SpeechResult caption,
    UserSettings settings,
  ) {
    final children = <InlineSpan>[];
    final fontScale = settings.captionFontSize;
    final highContrast = settings.highContrastEnabled ||
        settings.accessibilityCaptionModeEnabled;
    final speakerFocus = settings.speakerFocusModeEnabled;
    final hasDirectionalIcon = _getDirectionIcon(caption) != null;

    // Direction arrow
    final dirArrow = _getDirectionArrow(caption);
    if (dirArrow != null && !(speakerFocus && hasDirectionalIcon)) {
      children.add(TextSpan(
        text: '$dirArrow ',
        style: TextStyle(
          color: Colors.white
              .withAlpha((255 * (highContrast ? 0.75 : 0.5)).round()),
          fontSize: 15 * fontScale,
        ),
      ));
    }

    // Speaker name
    if (caption.hasSpeakerDiarization) {
      final color = _getDirectionalSpeakerColor(caption);
      final speakerLabel = speakerFocus
          ? '[${caption.speakerLabel.toUpperCase()}]'
          : caption.speakerLabel;
      children.add(TextSpan(
        text: '$speakerLabel: ',
        style: TextStyle(
          color: speakerFocus
              ? color.withAlpha((255 * 0.9).round())
              : color.withAlpha((255 * 0.7).round()),
          fontSize: 15 * fontScale,
          fontWeight: speakerFocus ? FontWeight.w700 : FontWeight.w600,
        ),
      ));
    }

    // Text
    children.add(TextSpan(
      text: caption.text,
      style: TextStyle(
        color:
            Colors.white.withAlpha((255 * (highContrast ? 0.9 : 0.7)).round()),
        fontSize: 15 * fontScale,
        fontWeight: FontWeight.w400,
        height: 1.3,
      ),
    ));

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: children),
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    LiveCaptionsState state,
    UserSettings settings,
  ) {
    final fontScale = settings.captionFontSize;
    final highContrast = settings.highContrastEnabled ||
        settings.accessibilityCaptionModeEnabled;

    if (state is LiveCaptionsLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black
              .withAlpha((255 * (highContrast ? 0.9 : 0.75)).round()),
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
        color:
            Colors.black.withAlpha((255 * (highContrast ? 0.75 : 0.5)).round()),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Captions will appear here',
        style: TextStyle(
          color: highContrast ? Colors.white70 : Colors.white38,
          fontSize: 16 * fontScale,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
