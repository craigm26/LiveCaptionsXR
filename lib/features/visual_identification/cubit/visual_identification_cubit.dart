import 'dart:async';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../core/models/detected_speaker.dart';
import '../../../core/models/visual_object.dart';
import '../../../core/services/app_logger.dart';
import '../../../core/services/hybrid_localization_engine.dart';
import '../../../core/services/speaker_tagging_coordinator.dart';
import '../../../core/services/speaker_attribution_store.dart';
import '../../../core/services/visual_speaker_service.dart';

abstract class VisualIdentificationState {}

class VisualIdentificationInitial extends VisualIdentificationState {}

class VisualIdentificationLoaded extends VisualIdentificationState {
  final List<VisualObject> objects;
  final List<DetectedSpeaker> speakers;
  final DetectedSpeaker? activeSpeaker;

  VisualIdentificationLoaded({
    this.objects = const [],
    this.speakers = const [],
    this.activeSpeaker,
  });
}

class VisualIdentificationCubit extends Cubit<VisualIdentificationState> {
  static final AppLogger _logger = AppLogger.instance;
  static const MethodChannel _channel =
      MethodChannel('live_captions_xr/visual_object_methods');

  final HybridLocalizationEngine hybridLocalizationEngine;
  final VisualSpeakerService? _visualSpeakerService;
  final SpeakerTaggingCoordinator? _speakerTaggingCoordinator;
  final SpeakerAttributionStore? _attributionStore;

  bool _isActive = false;
  StreamSubscription<List<DetectedSpeaker>>? _speakerSubscription;

  List<VisualObject> _latestObjects = const [];
  List<DetectedSpeaker> _latestSpeakers = const [];
  DetectedSpeaker? _activeSpeaker;

  VisualIdentificationCubit({
    required this.hybridLocalizationEngine,
    VisualSpeakerService? visualSpeakerService,
    SpeakerTaggingCoordinator? speakerTaggingCoordinator,
    SpeakerAttributionStore? attributionStore,
  })  : _visualSpeakerService = visualSpeakerService,
        _speakerTaggingCoordinator = speakerTaggingCoordinator,
        _attributionStore = attributionStore,
        super(VisualIdentificationInitial());

  bool get isActive => _isActive;

  Future<void> start() async {
    if (_isActive) return;
    _logger.i('??? Starting Visual Identification...');
    _channel.setMethodCallHandler(_handleMethodCall);

    if (_visualSpeakerService != null) {
      await _visualSpeakerService!.start();
      _speakerSubscription = _visualSpeakerService!.detectedSpeakers
          .listen(_handleSpeakerDetections);
    }

    _isActive = true;
    _logger.i('? Visual Identification started.');
  }

  Future<void> stop() async {
    if (!_isActive) return;
    _logger.i('??? Stopping Visual Identification...');
    _channel.setMethodCallHandler(null);
    _isActive = false;

    await _speakerSubscription?.cancel();
    _speakerSubscription = null;
    _speakerTaggingCoordinator?.reset();
    _attributionStore?.clear();
    await _visualSpeakerService?.stop();

    _latestObjects = const [];
    _latestSpeakers = const [];
    _activeSpeaker = null;
    emit(VisualIdentificationInitial());

    _logger.i('? Visual Identification stopped.');
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onVisualObjectDetected') {
      final args = Map<String, dynamic>.from(call.arguments);
      final bbox = args['boundingBox'] as List<dynamic>;
      final worldTransform = (args['worldTransform'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList();
      final obj = VisualObject(
        label: args['label'] as String,
        confidence: (args['confidence'] as num).toDouble(),
        boundingBox: Rect.fromLTRB(
          (bbox[0] as num).toDouble(),
          (bbox[1] as num).toDouble(),
          (bbox[2] as num).toDouble(),
          (bbox[3] as num).toDouble(),
        ),
        worldTransform: worldTransform,
      );
      detectObjects([obj]);
    }
  }

  void detectObjects(List<VisualObject> objects) {
    if (!_isActive) return;
    _latestObjects = objects;
    _emitLoadedState();

    for (final obj in objects) {
      if (obj.worldTransform != null && obj.worldTransform!.length == 16) {
        hybridLocalizationEngine.updateWithVisualMeasurement(
          transform: obj.worldTransform!,
          confidence: obj.confidence,
        );
      }
    }
  }

  void _handleSpeakerDetections(List<DetectedSpeaker> speakers) {
    if (!_isActive) {
      return;
    }

    _latestSpeakers = speakers;
    DetectedSpeaker? active =
        _speakerTaggingCoordinator?.updateDetections(speakers);

    active ??= _selectTopSpeaker(speakers);
    _activeSpeaker = active;
    if (_speakerTaggingCoordinator == null && _attributionStore != null) {
      _attributionStore!.update(active);
    }

    if (_speakerTaggingCoordinator == null &&
        active?.worldTransform != null &&
        active!.worldTransform!.length == 16) {
      unawaited(
        hybridLocalizationEngine.updateWithVisualMeasurement(
          transform: active.worldTransform!,
          confidence: active.confidence,
        ),
      );
    }

    _emitLoadedState();
  }

  DetectedSpeaker? _selectTopSpeaker(List<DetectedSpeaker> speakers) {
    if (speakers.isEmpty) {
      return null;
    }
    final sorted = List<DetectedSpeaker>.from(speakers)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final speaking = sorted
        .where((d) => d.state == SpeakerState.speaking)
        .toList(growable: false);
    return speaking.isNotEmpty ? speaking.first : sorted.first;
  }

  void _emitLoadedState() {
    emit(
      VisualIdentificationLoaded(
        objects: _latestObjects,
        speakers: _latestSpeakers,
        activeSpeaker: _activeSpeaker,
      ),
    );
  }
}
