
# Whisper GGML



OpenAI Whisper ASR (Automatic Speech Recognition) for Flutter using [Whisper.cpp](https://github.com/ggerganov/whisper.cpp).




## Supported platforms


| Platform  | Supported |
|-----------|-----------|
| Android   | ✅        |
| iOS       | ✅        |
| MacOS     | ✅        |





## Features



- Automatic Speech Recognition integration for Flutter apps.

- Supports automatic model downloading and initialization. Can be configured to work fully offline by using `assets` models (see example folder).

- Seamless iOS and Android support with optimized performance.

- Utilizes CORE ML for enhanced processing on iOS devices.



## Installation



To use this library in your Flutter project, follow these steps:



1. Add the library to your Flutter project's `pubspec.yaml`:

```yaml
dependencies:
  whisper_ggml: ^1.3.0
```

2. Run `flutter pub get` to install the package.



## Usage



To integrate Whisper ASR in your Flutter app:



1. Import the package:

```dart
import 'package:whisper_ggml/whisper_ggml.dart';
```



2. Pick your model. Smaller models are more performant, but the accuracy may be lower. Recommended models are `tiny` and `small`.

```dart
final model = WhisperModel.tiny;
```

3. Declare `WhisperController` and use it for transcription:

```dart
final controller = WhisperController();

final result = await whisperController.transcribe(
    model: model, /// Selected WhisperModel
    audioPath: audioPath, /// Path to .wav file
    lang: 'en', /// Language to transcribe
);
```

4. Use the `result` variable to access the transcription result:

```dart
if (result?.transcription.text != null) {
    /// Do something with the transcription
    print(result!.transcription.text);
}
```



## Notes



Transcription processing time is about `5x` times faster when running in release mode.
