/// Model for streaming ASR transcription results
///
/// Defined in `prd/04_gemma_3n_streaming_asr.md`.
/// Contains the transcribed [text] and whether the segment is [isFinal].
class TranscriptionResult {
  final String text;
  final bool isFinal;

  const TranscriptionResult({required this.text, required this.isFinal});
}

