# Whisper Streaming Models

- Store Whisper GGML binaries here (e.g., `ggml-small.en.bin`) for deterministic streaming benchmarks.
- Ensure `ModelDownloadManager` points to the intended file; Android GGML is still the default engine.
- Use the benchmarking harness to compare Whisper vs. Gemma decoding under identical policies.

