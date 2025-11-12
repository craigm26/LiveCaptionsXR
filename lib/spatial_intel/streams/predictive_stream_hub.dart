import 'package:live_captions_xr/spatial_intel/streams/audio_stream.dart';
import 'package:live_captions_xr/spatial_intel/streams/context_stream.dart';
import 'package:live_captions_xr/spatial_intel/streams/spatial_sensor_stream.dart';
import 'package:live_captions_xr/spatial_intel/streams/video_stream.dart';

/// Central registry for predictive caption data feeds.
///
/// The hub consolidates streaming surfaces (audio, video, sensors, context)
/// so that decode policies, calibration, and benchmarking tools can share
/// identical timing semantics. It is registered with the service locator and
/// bridged from existing capture services without disrupting legacy flows.
class PredictiveStreamHub {
  PredictiveStreamHub({
    AudioStreamBus? audioBus,
    VideoStreamBus? videoBus,
    SpatialSensorBus? sensorBus,
    CaptionContextBus? contextBus,
  })  : audio = audioBus ?? AudioStreamBus(),
        video = videoBus ?? VideoStreamBus(),
        sensors = sensorBus ?? SpatialSensorBus(),
        context = contextBus ?? CaptionContextBus();

  final AudioStreamBus audio;
  final VideoStreamBus video;
  final SpatialSensorBus sensors;
  final CaptionContextBus context;

  Future<void> dispose() async {
    await Future.wait([
      audio.dispose(),
      video.dispose(),
      sensors.dispose(),
      context.dispose(),
    ]);
  }
}

