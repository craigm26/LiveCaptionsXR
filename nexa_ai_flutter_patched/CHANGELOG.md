## 0.0.4

### Changes
* Update model download URLs

## 0.0.3

### Bug Fixes
* Fix R8 obfuscation of Nexa SDK bean classes causing crash in release builds

## 0.0.2

### Bug Fixes
* Add ProGuard rules to fix R8 code shrinking issues in release builds
* Update Nexa AI core SDK to 0.0.11

## 0.0.1

### Initial Release

#### Features
* Complete Nexa AI SDK integration for Android
* Support for 6 model types: LLM, VLM, Embeddings, ASR, Reranker, and Computer Vision
* Built-in model downloader with progress tracking and cancellation
* Device capability detection with chipset identification
* Model compatibility checking with performance estimation
* Hardware acceleration support (Qualcomm NPU, GPU, and CPU)
* Streaming generation for LLM and VLM models
* Chat template support for conversational AI
* Storage management with model deletion
* 8 pre-configured models ready to use

#### Platform Support
* Android (Min SDK 27, ARM64-v8a)
* NPU acceleration for Snapdragon 8 Gen 3/4 devices
* GPU acceleration for Snapdragon 8 series
* CPU fallback for all ARM64 devices

#### Example App
* Complete demonstration app with all features
* Model management UI with compatibility indicators
* Interactive chat interface with real-time streaming
* Device information and performance indicators
* Download progress tracking with speed monitoring
