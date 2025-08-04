import 'package:equatable/equatable.dart';
import '../models/caption_model.dart';

class SpatialCaptionsState extends Equatable {
  final List<CaptionModel> captions;
  final bool isLandscapeLocked;
  final bool isInitialized;
  final String? error;

  const SpatialCaptionsState({
    this.captions = const [],
    this.isLandscapeLocked = true,  // Default to landscape
    this.isInitialized = false,
    this.error,
  });

  SpatialCaptionsState copyWith({
    List<CaptionModel>? captions,
    bool? isLandscapeLocked,
    bool? isInitialized,
    String? error,
  }) {
    return SpatialCaptionsState(
      captions: captions ?? this.captions,
      isLandscapeLocked: isLandscapeLocked ?? this.isLandscapeLocked,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
    );
  }

  /// Get only active captions
  List<CaptionModel> get activeCaptions => 
      captions.where((c) => c.isActive).toList();

  /// Get captions grouped by speaker
  Map<String?, List<CaptionModel>> get captionsBySpeaker {
    final map = <String?, List<CaptionModel>>{};
    for (final caption in activeCaptions) {
      map.putIfAbsent(caption.speakerId, () => []).add(caption);
    }
    return map;
  }

  /// Get the latest caption for each speaker
  Map<String?, CaptionModel> get latestCaptionBySpeaker {
    final map = <String?, CaptionModel>{};
    for (final caption in activeCaptions) {
      final existing = map[caption.speakerId];
      if (existing == null || caption.timestamp.isAfter(existing.timestamp)) {
        map[caption.speakerId] = caption;
      }
    }
    return map;
  }

  @override
  List<Object?> get props => [captions, isLandscapeLocked, isInitialized, error];
} 