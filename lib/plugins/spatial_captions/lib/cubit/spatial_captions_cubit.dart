import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vector_math/vector_math_64.dart';
import '../spatial_captions.dart';
import '../models/caption_model.dart';
import 'spatial_captions_state.dart';

class SpatialCaptionsCubit extends Cubit<SpatialCaptionsState> {
  SpatialCaptionsCubit() : super(const SpatialCaptionsState());

  // Configuration
  Duration captionDuration = const Duration(seconds: 5);
  Duration fadeOutDuration = const Duration(seconds: 1);
  
  /// Add a new partial caption
  Future<void> addPartialCaption({
    required String text,
    required Vector3 position,
    String? speakerId,
    double confidence = 1.0,
  }) async {
    final id = _generateCaptionId();
    final caption = CaptionModel(
      id: id,
      text: text,
      position: position,
      type: CaptionType.partial,
      speakerId: speakerId,
      confidence: confidence,
    );

    // Check if we should replace an existing partial caption from the same speaker
    final existingPartial = state.captions
        .where((c) => c.isPartial && c.speakerId == speakerId && c.isActive)
        .lastOrNull;

    if (existingPartial != null) {
      // Replace the existing partial caption
      await SpatialCaptions.replaceCaption(
        oldId: existingPartial.id,
        newId: id,
        text: text,
        type: CaptionType.partial,
      );
      
      final updated = state.captions.map((c) => 
        c.id == existingPartial.id ? c.copyWith(isActive: false) : c
      ).toList()..add(caption);
      
      emit(state.copyWith(captions: updated));
    } else {
      // Add new partial caption
      await SpatialCaptions.addCaption(
        id: id,
        text: text,
        position: position,
        type: CaptionType.partial,
        speakerId: speakerId,
      );
      
      emit(state.copyWith(
        captions: [...state.captions, caption],
      ));
    }
  }

  /// Convert partial caption to final
  Future<void> finalizeCaption({
    required String text,
    required Vector3 position,
    String? speakerId,
    double confidence = 1.0,
  }) async {
    final id = _generateCaptionId();
    final caption = CaptionModel(
      id: id,
      text: text,
      position: position,
      type: CaptionType.final_,
      speakerId: speakerId,
      confidence: confidence,
    );

    // Find and replace the last partial caption from the same speaker
    final partialToReplace = state.captions
        .where((c) => c.isPartial && c.speakerId == speakerId && c.isActive)
        .lastOrNull;

    if (partialToReplace != null) {
      await SpatialCaptions.replaceCaption(
        oldId: partialToReplace.id,
        newId: id,
        text: text,
        type: CaptionType.final_,
      );
      
      final updated = state.captions.map((c) => 
        c.id == partialToReplace.id ? c.copyWith(isActive: false) : c
      ).toList()..add(caption.copyWith(replacesId: partialToReplace.id));
      
      emit(state.copyWith(captions: updated));
    } else {
      // No partial to replace, add as new final caption
      await SpatialCaptions.addCaption(
        id: id,
        text: text,
        position: position,
        type: CaptionType.final_,
        speakerId: speakerId,
      );
      
      emit(state.copyWith(
        captions: [...state.captions, caption],
      ));
    }

    // Schedule removal after duration
    _scheduleRemoval(id);
  }

  /// Enhance a final caption with Gemma result
  Future<void> enhanceCaption({
    required String captionId,
    required String enhancedText,
  }) async {
    final captionToEnhance = state.captions
        .firstWhere((c) => c.id == captionId && c.isFinal);

    final enhancedId = _generateCaptionId();
    final enhancedCaption = captionToEnhance.copyWith(
      id: enhancedId,
      text: enhancedText,
      type: CaptionType.enhanced,
      replacesId: captionId,
    );

    await SpatialCaptions.replaceCaption(
      oldId: captionId,
      newId: enhancedId,
      text: enhancedText,
      type: CaptionType.enhanced,
    );

    final updated = state.captions.map((c) => 
      c.id == captionId ? c.copyWith(isActive: false) : c
    ).toList()..add(enhancedCaption);

    emit(state.copyWith(captions: updated));
    
    // Reschedule removal for enhanced caption
    _scheduleRemoval(enhancedId);
  }

  /// Remove a caption
  Future<void> removeCaption(String id) async {
    await SpatialCaptions.removeCaption(id);
    
    final updated = state.captions
        .where((c) => c.id != id)
        .toList();
    
    emit(state.copyWith(captions: updated));
  }

  /// Clear all captions
  Future<void> clearAll() async {
    await SpatialCaptions.clearCaptions();
    emit(const SpatialCaptionsState());
  }

  /// Set caption display duration
  void setCaptionDuration(Duration duration) {
    captionDuration = duration;
    SpatialCaptions.setCaptionDuration(duration);
  }

  /// Set orientation lock
  Future<void> setOrientationLock(bool lockLandscape) async {
    await SpatialCaptions.setOrientationLock(lockLandscape);
    emit(state.copyWith(isLandscapeLocked: lockLandscape));
  }

  /// Get active captions
  List<CaptionModel> get activeCaptions => 
      state.captions.where((c) => c.isActive).toList();

  /// Get captions by type
  List<CaptionModel> getCaptionsByType(CaptionType type) =>
      state.captions.where((c) => c.type == type && c.isActive).toList();

  // Private helpers
  String _generateCaptionId() => 
      DateTime.now().millisecondsSinceEpoch.toString();

  void _scheduleRemoval(String id) {
    Future.delayed(captionDuration, () {
      if (state.captions.any((c) => c.id == id)) {
        removeCaption(id);
      }
    });
  }
} 