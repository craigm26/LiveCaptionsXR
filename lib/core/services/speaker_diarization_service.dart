import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';
import '../models/speaker_profile.dart';
import 'stereo_audio_capture.dart';
import 'speech_localizer.dart';
import 'app_logger.dart';

/// Configuration for speaker diarization
class DiarizationConfig {
  /// Minimum similarity threshold to match a speaker (0.0-1.0)
  final double similarityThreshold;
  
  /// Embedding dimension for voice profiles
  final int embeddingDim;
  
  /// Maximum number of speakers to track
  final int maxSpeakers;
  
  /// Window size for MFCC calculation (samples)
  final int mfccWindowSize;
  
  /// Number of MFCC coefficients
  final int numMfcc;
  
  /// Time window for speaker assignment (ms)
  final int assignmentWindowMs;
  
  const DiarizationConfig({
    this.similarityThreshold = 0.75,
    this.embeddingDim = 64,
    this.maxSpeakers = 10,
    this.mfccWindowSize = 512,
    this.numMfcc = 13,
    this.assignmentWindowMs = 500,
  });
}

/// Result of speaker identification
class SpeakerIdentificationResult {
  final String speakerId;
  final SpeakerProfile profile;
  final double confidence;
  final bool isNewSpeaker;
  final Vector3 estimatedPosition;
  
  const SpeakerIdentificationResult({
    required this.speakerId,
    required this.profile,
    required this.confidence,
    required this.isNewSpeaker,
    required this.estimatedPosition,
  });
}

/// Service for speaker diarization with 3D/4D spatial tracking
/// 
/// Implements:
/// - Voice embedding extraction (MFCC-based)
/// - Speaker clustering and identification
/// - Temporal smoothing for position tracking (4D = 3D + time)
/// - Voice profile persistence
class SpeakerDiarizationService {
  final DiarizationConfig config;
  final SpeechLocalizer _speechLocalizer;
  final AppLogger _logger = AppLogger.instance;
  
  // Active speaker profiles
  final Map<String, SpeakerProfile> _speakers = {};
  
  // Speaker change events
  final _speakerChangeController = StreamController<SpeakerIdentificationResult>.broadcast();
  Stream<SpeakerIdentificationResult> get speakerChanges => _speakerChangeController.stream;
  
  // Current active speaker
  String? _currentSpeakerId;
  DateTime? _lastSpeakerChangeTime;
  
  // Precomputed DCT matrix for MFCC
  late final List<List<double>> _dctMatrix;
  
  // Mel filterbank
  late final List<List<double>> _melFilterbank;
  
  SpeakerDiarizationService({
    this.config = const DiarizationConfig(),
    required SpeechLocalizer speechLocalizer,
  }) : _speechLocalizer = speechLocalizer {
    _initializeMfccTables();
  }
  
  void _initializeMfccTables() {
    // Initialize DCT-II matrix for MFCC
    final n = config.mfccWindowSize ~/ 2 + 1;
    _dctMatrix = List.generate(
      config.numMfcc,
      (k) => List.generate(
        n,
        (n_) => cos(pi * k * (n_ + 0.5) / n),
      ),
    );
    
    // Initialize Mel filterbank (26 filters -> numMfcc coefficients)
    _melFilterbank = _createMelFilterbank(
      numFilters: 26,
      fftSize: config.mfccWindowSize,
      sampleRate: 16000,
      lowFreq: 300,
      highFreq: 8000,
    );
    
    _logger.i('🎙️ SpeakerDiarizationService initialized', category: LogCategory.speech);
  }
  
  /// Create Mel filterbank
  List<List<double>> _createMelFilterbank({
    required int numFilters,
    required int fftSize,
    required int sampleRate,
    required int lowFreq,
    required int highFreq,
  }) {
    // Convert to Mel scale
    final lowMel = 2595 * log(1 + lowFreq / 700) / ln10;
    final highMel = 2595 * log(1 + highFreq / 700) / ln10;
    
    // Create equally spaced points in Mel scale
    final melPoints = List.generate(
      numFilters + 2,
      (i) => lowMel + i * (highMel - lowMel) / (numFilters + 1),
    );
    
    // Convert back to Hz
    final hzPoints = melPoints.map((m) => 700 * (pow(10, m / 2595) - 1)).toList();
    
    // Convert to FFT bin indices
    final binPoints = hzPoints
        .map((hz) => ((fftSize + 1) * hz / sampleRate).floor())
        .toList();
    
    // Create filterbank
    final filterbank = <List<double>>[];
    final numBins = fftSize ~/ 2 + 1;
    
    for (int i = 0; i < numFilters; i++) {
      final filter = List<double>.filled(numBins, 0);
      
      for (int j = binPoints[i]; j < binPoints[i + 1]; j++) {
        if (j < numBins) {
          filter[j] = (j - binPoints[i]) / (binPoints[i + 1] - binPoints[i]);
        }
      }
      
      for (int j = binPoints[i + 1]; j < binPoints[i + 2]; j++) {
        if (j < numBins) {
          filter[j] = (binPoints[i + 2] - j) / (binPoints[i + 2] - binPoints[i + 1]);
        }
      }
      
      filterbank.add(filter);
    }
    
    return filterbank;
  }
  
  /// Extract voice embedding from audio frame
  Float32List extractVoiceEmbedding(StereoAudioFrame frame) {
    // Mix to mono
    final mono = Float32List(frame.left.length);
    for (int i = 0; i < mono.length; i++) {
      mono[i] = (frame.left[i] + frame.right[i]) / 2;
    }
    
    // Calculate pitch (fundamental frequency)
    final pitch = _estimatePitch(mono);
    
    // Calculate MFCC features
    final mfccs = _extractMfcc(mono);
    
    // Calculate delta MFCCs (velocity)
    final deltaMfccs = _calculateDeltas(mfccs);
    
    // Calculate spectral features
    final spectral = _extractSpectralFeatures(mono);
    
    // Combine into embedding
    final embedding = Float32List(config.embeddingDim);
    int idx = 0;
    
    // Add MFCC coefficients (normalized)
    for (int i = 0; i < min(config.numMfcc, config.embeddingDim ~/ 4); i++) {
      embedding[idx++] = mfccs[i] / 20.0; // Normalize MFCC range
    }
    
    // Add delta MFCCs
    for (int i = 0; i < min(deltaMfccs.length, config.embeddingDim ~/ 4); i++) {
      embedding[idx++] = deltaMfccs[i] / 10.0;
    }
    
    // Add spectral features
    for (int i = 0; i < min(spectral.length, config.embeddingDim ~/ 4); i++) {
      embedding[idx++] = spectral[i];
    }
    
    // Add pitch information
    if (idx < config.embeddingDim) {
      embedding[idx++] = (pitch / 500.0).clamp(0.0, 1.0); // Normalize pitch (0-500 Hz)
    }
    
    // Fill remaining with energy statistics
    final energy = _calculateEnergy(mono);
    while (idx < config.embeddingDim) {
      embedding[idx++] = energy.clamp(0.0, 1.0);
    }
    
    // L2 normalize the embedding
    return _l2Normalize(embedding);
  }
  
  /// Extract MFCC coefficients
  List<double> _extractMfcc(Float32List audio) {
    // Apply pre-emphasis
    final emphasized = Float32List(audio.length);
    emphasized[0] = audio[0];
    for (int i = 1; i < audio.length; i++) {
      emphasized[i] = audio[i] - 0.97 * audio[i - 1];
    }
    
    // Apply Hamming window
    final windowed = Float32List(config.mfccWindowSize);
    for (int i = 0; i < config.mfccWindowSize && i < emphasized.length; i++) {
      final window = 0.54 - 0.46 * cos(2 * pi * i / (config.mfccWindowSize - 1));
      windowed[i] = emphasized[i] * window;
    }
    
    // Compute power spectrum using FFT
    final powerSpectrum = _computePowerSpectrum(windowed);
    
    // Apply Mel filterbank
    final melEnergies = List<double>.filled(_melFilterbank.length, 0);
    for (int i = 0; i < _melFilterbank.length; i++) {
      double energy = 0;
      for (int j = 0; j < min(powerSpectrum.length, _melFilterbank[i].length); j++) {
        energy += powerSpectrum[j] * _melFilterbank[i][j];
      }
      melEnergies[i] = log(max(energy, 1e-10));
    }
    
    // Apply DCT to get MFCC
    final mfccs = List<double>.filled(config.numMfcc, 0);
    for (int k = 0; k < config.numMfcc; k++) {
      for (int n = 0; n < melEnergies.length; n++) {
        if (n < _dctMatrix[k].length) {
          mfccs[k] += melEnergies[n] * _dctMatrix[k][n];
        }
      }
    }
    
    return mfccs;
  }
  
  /// Compute power spectrum
  Float32List _computePowerSpectrum(Float32List audio) {
    final n = audio.length;
    final spectrum = Float32List(n ~/ 2 + 1);
    
    // Simple DFT (could be optimized with FFT)
    for (int k = 0; k < spectrum.length; k++) {
      double realSum = 0, imagSum = 0;
      for (int t = 0; t < n; t++) {
        final angle = -2 * pi * k * t / n;
        realSum += audio[t] * cos(angle);
        imagSum += audio[t] * sin(angle);
      }
      spectrum[k] = (realSum * realSum + imagSum * imagSum) / n;
    }
    
    return spectrum;
  }
  
  /// Calculate delta coefficients (first derivative)
  List<double> _calculateDeltas(List<double> features) {
    final deltas = List<double>.filled(features.length, 0);
    const N = 2;
    
    for (int i = 0; i < features.length; i++) {
      double numerator = 0;
      double denominator = 0;
      
      for (int n = 1; n <= N; n++) {
        final prev = i - n >= 0 ? features[i - n] : features[0];
        final next = i + n < features.length ? features[i + n] : features[features.length - 1];
        numerator += n * (next - prev);
        denominator += 2 * n * n;
      }
      
      deltas[i] = denominator > 0 ? numerator / denominator : 0;
    }
    
    return deltas;
  }
  
  /// Extract spectral features (centroid, bandwidth, rolloff)
  List<double> _extractSpectralFeatures(Float32List audio) {
    final spectrum = _computePowerSpectrum(audio);
    
    // Spectral centroid
    double weightedSum = 0, totalSum = 0;
    for (int i = 0; i < spectrum.length; i++) {
      weightedSum += i * spectrum[i];
      totalSum += spectrum[i];
    }
    final centroid = totalSum > 0 ? weightedSum / totalSum / spectrum.length : 0.5;
    
    // Spectral bandwidth
    double bandwidthSum = 0;
    for (int i = 0; i < spectrum.length; i++) {
      final diff = i / spectrum.length - centroid;
      bandwidthSum += diff * diff * spectrum[i];
    }
    final bandwidth = totalSum > 0 ? sqrt(bandwidthSum / totalSum) : 0;
    
    // Spectral rolloff (frequency below which 85% of energy is contained)
    double cumulativeEnergy = 0;
    final threshold = totalSum * 0.85;
    int rolloff = spectrum.length - 1;
    for (int i = 0; i < spectrum.length; i++) {
      cumulativeEnergy += spectrum[i];
      if (cumulativeEnergy >= threshold) {
        rolloff = i;
        break;
      }
    }
    final rolloffNorm = rolloff / spectrum.length;
    
    // Spectral flatness (Wiener entropy)
    double geometricMean = 0;
    double arithmeticMean = 0;
    int count = 0;
    for (int i = 0; i < spectrum.length; i++) {
      if (spectrum[i] > 1e-10) {
        geometricMean += log(spectrum[i]);
        arithmeticMean += spectrum[i];
        count++;
      }
    }
    final flatness = count > 0 
        ? exp(geometricMean / count) / (arithmeticMean / count)
        : 0.0;
    
    return [centroid, bandwidth, rolloffNorm, flatness.clamp(0.0, 1.0)];
  }
  
  /// Estimate fundamental frequency (pitch)
  double _estimatePitch(Float32List audio) {
    // Autocorrelation-based pitch detection
    const minLag = 20; // ~800 Hz max
    const maxLag = 200; // ~80 Hz min
    
    double maxCorr = 0;
    int bestLag = minLag;
    
    for (int lag = minLag; lag < min(maxLag, audio.length ~/ 2); lag++) {
      double correlation = 0;
      for (int i = 0; i < audio.length - lag; i++) {
        correlation += audio[i] * audio[i + lag];
      }
      
      if (correlation > maxCorr) {
        maxCorr = correlation;
        bestLag = lag;
      }
    }
    
    // Convert lag to frequency (assuming 16kHz sample rate)
    return 16000.0 / bestLag;
  }
  
  /// Calculate RMS energy
  double _calculateEnergy(Float32List audio) {
    double sum = 0;
    for (int i = 0; i < audio.length; i++) {
      sum += audio[i] * audio[i];
    }
    return sqrt(sum / audio.length);
  }
  
  /// L2 normalize embedding
  Float32List _l2Normalize(Float32List embedding) {
    double norm = 0;
    for (int i = 0; i < embedding.length; i++) {
      norm += embedding[i] * embedding[i];
    }
    norm = sqrt(norm);
    
    if (norm > 1e-10) {
      for (int i = 0; i < embedding.length; i++) {
        embedding[i] /= norm;
      }
    }
    
    return embedding;
  }
  
  /// Identify speaker from audio frame with spatial positioning
  Future<SpeakerIdentificationResult> identifySpeaker(
    StereoAudioFrame frame, {
    double? overrideAngle,
  }) async {
    // Extract voice embedding
    final embedding = extractVoiceEmbedding(frame);
    
    // Estimate spatial direction
    final angle = overrideAngle ?? _speechLocalizer.estimateDirectionAdvanced(frame);
    
    // Calculate 3D position from angle
    const distance = 2.0; // Default 2m distance
    final position = Vector3(
      distance * sin(angle),
      0, // Eye level
      -distance * cos(angle),
    );
    
    // Extract voice characteristics for matching
    final mono = Float32List(frame.left.length);
    for (int i = 0; i < mono.length; i++) {
      mono[i] = (frame.left[i] + frame.right[i]) / 2;
    }
    final pitch = _estimatePitch(mono);
    final energy = _calculateEnergy(mono);
    
    // Find best matching speaker
    String? bestMatchId;
    double bestSimilarity = 0;
    
    for (final entry in _speakers.entries) {
      final similarity = entry.value.similarityTo(embedding);
      
      // Boost similarity if position is close (spatial coherence)
      final posDiff = (entry.value.currentPosition - position).length;
      final spatialBoost = posDiff < 0.5 ? 0.1 : (posDiff < 1.0 ? 0.05 : 0);
      
      final adjustedSimilarity = similarity + spatialBoost;
      
      if (adjustedSimilarity > bestSimilarity) {
        bestSimilarity = adjustedSimilarity;
        bestMatchId = entry.key;
      }
    }
    
    SpeakerProfile profile;
    bool isNewSpeaker = false;
    
    if (bestMatchId != null && bestSimilarity >= config.similarityThreshold) {
      // Existing speaker
      profile = _speakers[bestMatchId]!;
      profile.addSpatialObservation(position, confidence: bestSimilarity);
      profile.updateVoiceCharacteristics(pitch: pitch, energy: energy);
      
      _logger.d('👤 Matched speaker ${profile.id} (similarity: ${bestSimilarity.toStringAsFixed(2)})', 
          category: LogCategory.speech);
    } else {
      // New speaker
      isNewSpeaker = true;
      final speakerId = 'speaker_${_speakers.length + 1}_${DateTime.now().millisecondsSinceEpoch}';
      
      profile = SpeakerProfile(
        id: speakerId,
        voiceEmbedding: embedding,
        firstSeen: DateTime.now(),
        pitchMean: pitch,
        energyMean: energy,
      );
      profile.addSpatialObservation(position);
      
      _speakers[speakerId] = profile;
      
      _logger.i('🆕 New speaker detected: $speakerId at position $position', 
          category: LogCategory.speech);
      
      // Enforce max speakers limit
      _pruneInactiveSpeakers();
    }
    
    // Track speaker changes
    if (_currentSpeakerId != profile.id) {
      _currentSpeakerId = profile.id;
      _lastSpeakerChangeTime = DateTime.now();
    }
    
    final result = SpeakerIdentificationResult(
      speakerId: profile.id,
      profile: profile,
      confidence: isNewSpeaker ? 1.0 : bestSimilarity,
      isNewSpeaker: isNewSpeaker,
      estimatedPosition: profile.currentPosition,
    );
    
    _speakerChangeController.add(result);
    
    return result;
  }
  
  /// Remove inactive speakers when limit exceeded
  void _pruneInactiveSpeakers() {
    if (_speakers.length <= config.maxSpeakers) return;
    
    // Sort by last seen time
    final sorted = _speakers.entries.toList()
      ..sort((a, b) => a.value.lastSeen.compareTo(b.value.lastSeen));
    
    // Remove oldest inactive speakers
    while (_speakers.length > config.maxSpeakers) {
      final oldest = sorted.removeAt(0);
      _speakers.remove(oldest.key);
      _logger.i('🗑️ Pruned inactive speaker: ${oldest.key}', category: LogCategory.speech);
    }
  }
  
  /// Get all tracked speakers
  List<SpeakerProfile> get speakers => _speakers.values.toList();
  
  /// Get speaker by ID
  SpeakerProfile? getSpeaker(String id) => _speakers[id];
  
  /// Get currently active speaker
  SpeakerProfile? get currentSpeaker => 
      _currentSpeakerId != null ? _speakers[_currentSpeakerId] : null;
  
  /// Update speaker position manually (e.g., from visual tracking)
  void updateSpeakerPosition(String speakerId, Vector3 position, {double confidence = 1.0}) {
    final speaker = _speakers[speakerId];
    if (speaker != null) {
      speaker.addSpatialObservation(position, confidence: confidence);
      _logger.d('📍 Updated ${speakerId} position to $position', category: LogCategory.speech);
    }
  }
  
  /// Assign a display name to a speaker
  void nameSpeaker(String speakerId, String name) {
    final speaker = _speakers[speakerId];
    if (speaker != null) {
      // Create new profile with name (SpeakerProfile is mostly immutable)
      _speakers[speakerId] = SpeakerProfile(
        id: speaker.id,
        displayName: name,
        voiceEmbedding: speaker.voiceEmbedding,
        firstSeen: speaker.firstSeen,
        lastSeen: speaker.lastSeen,
        spatialHistory: speaker.spatialHistory,
        pitchMean: speaker.pitchMean,
        pitchStd: speaker.pitchStd,
        energyMean: speaker.energyMean,
        utteranceCount: speaker.utteranceCount,
        colorValue: speaker.colorValue,
      );
      _logger.i('🏷️ Named speaker $speakerId as "$name"', category: LogCategory.speech);
    }
  }
  
  /// Clear all speaker profiles
  void clearSpeakers() {
    _speakers.clear();
    _currentSpeakerId = null;
    _logger.i('🧹 Cleared all speaker profiles', category: LogCategory.speech);
  }
  
  /// Export speaker profiles for persistence
  List<Map<String, dynamic>> exportProfiles() {
    return _speakers.values.map((s) => s.toJson()).toList();
  }
  
  /// Import speaker profiles from persistence
  void importProfiles(List<Map<String, dynamic>> profiles) {
    for (final json in profiles) {
      try {
        final profile = SpeakerProfile.fromJson(json);
        _speakers[profile.id] = profile;
      } catch (e) {
        _logger.w('⚠️ Failed to import speaker profile: $e', category: LogCategory.speech);
      }
    }
    _logger.i('📥 Imported ${profiles.length} speaker profiles', category: LogCategory.speech);
  }
  
  void dispose() {
    _speakerChangeController.close();
  }
}
