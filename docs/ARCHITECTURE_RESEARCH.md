Great. I’ll research the best way to build a high-performance Flutter-compatible inference package for Gemma 3n `.task` models using Kotlin and Swift. This package will support multimodal (audio and visual) real-time inference for both Android (including XR) and iOS, with an architecture similar to `flutter_gemma`. The goal is to create a fast, extensible MVP suitable for hackathon competition and future custom model support.

I’ll get back to you with an implementation plan, best practices, and references for designing native inference bridges and managing multimodal pipelines effectively.


# Building a Flutter Plugin for Gemma 3n On-Device Inference

## Overview and Goals

We aim to create a high-performance Flutter plugin (for Android and iOS) to run the **Gemma 3n** multimodal model entirely on-device. This plugin will handle loading the Gemma 3n **`.task` model file** (e.g. **`gemma-3n-E2B-it-int4.task`**) and performing real-time inference. Our goals include:

* **Fast, On-Device Execution:** Use the latest device hardware (CPU/GPU/NPUs) to run Gemma 3n locally for low latency and offline use.
* **Multimodal Support:** Accept **text and image inputs** (vision-language), enabling features like visual captioning and analysis. Future extensibility for **audio inputs** (speech) is considered, including handling microphone data for speech recognition and localization.
* **Easy Integration:** Provide a simple Flutter API (Dart) so developers can load the model and get responses with minimal code (similar to `flutter_gemma`). The plugin will hide complexities like file handling, tokenization, and multi-modal preprocessing.
* **Speed of Development:** Leverage existing Google AI Edge / MediaPipe components to avoid reinventing the wheel. By using Google’s optimized inference libraries, we ensure both fast development and optimized performance.

## Leveraging Google’s AI Edge & MediaPipe Tasks

The **best approach** is to build on Google’s official on-device AI toolkit (MediaPipe/Google AI Edge) which provides a ready LLM inference API. Gemma 3n models are distributed in **`.task` format**, a self-contained package with the model weights, tokenizer, and metadata for on-device execution. Google’s **MediaPipe GenAI (LLM Inference API)** is specifically designed to load these `.task` files and run them efficiently on Android/iOS hardware. Key reasons to use this framework:

* **Built-in Optimizations:** MediaPipe automatically handles **hardware acceleration** (GPU, NN accelerators, or CPU) and quantization details for Gemma models. For example, an int4 quantized model can run on mobile GPUs for maximal speed.
* **Unified API for Modalities:** The MediaPipe LLM API offers a unified interface to process text, images, and (eventually) audio in one pipeline. This aligns perfectly with Gemma 3n’s multimodal nature. We can enable vision input with a simple flag rather than writing a custom image processor.
* **Simplified Model Loading:** We can load the Gemma 3n `.task` file directly via the API. For instance, on Android one can specify `LlmInferenceOptions.setModelPath("gemma-3n-E2B-it-int4.task")` to initialize the model. The `.task` format is **“runtime-friendly”**, meaning it includes all necessary components to initialize the model on-device.
* **High-Level Inference Methods:** The framework provides an easy way to feed prompts and get generated text. It even supports **streaming output** (partial token callbacks) to reduce latency, and methods to attach images as context for multimodal models. This saves us from implementing tokenization or generation loops from scratch.

By using MediaPipe’s LLM Inference SDK, we dramatically reduce development time and get Google-optimized performance out of the box. This approach is proven in existing apps (e.g. Google’s AI Edge Gallery) which use `.task` files and MediaPipe for on-device Gemma inference.

## Plugin Architecture and Design

Our Flutter plugin will have a **platform-specific inference core** (Kotlin for Android, Swift for iOS) and a **Dart API** to expose functionality to Flutter apps. The design will be similar to `flutter_gemma` in structure, focusing on speed and ease of use:

* **Singleton Engine Instance:** The plugin will manage a single instance of the Gemma 3n model loaded in memory (or one per concurrent session if needed). This avoids repeatedly loading large models and allows reuse across multiple queries.

* **Model Initialization:** A Dart call like `GemmaXR.loadModel(path, config)` will trigger platform code to load the `.task` file from app assets or storage. We’ll use MediaPipe’s `LlmInference.createFromOptions(...)` with the given model path. Configuration options like `maxTokens`, `preferredBackend` (CPU/GPU), etc., can be passed at this stage. For example, we enable GPU acceleration for int4 models and set an appropriate max token limit for our use case.

* **Session & Context Management:** The plugin will create an **inference session** for handling prompts and model context. MediaPipe’s API supports creating a session from the loaded model and then feeding it inputs. If we want a persistent conversation (chat), the session can be kept open to accumulate prompts. Otherwise, for single-turn queries, we create a session per query and close it.

* **Dart API (Frontend):** We will expose a high-level Dart interface. For example:

  * `GemmaXR.initialize(modelAsset: "assets/gemma-3n.task", useGPU: true)` – Copies the `.task` from assets to a device path and loads it.
  * `GemmaXR.generateReply(String prompt, {Uint8List? imageBytes})` – Sends a text prompt (and optional image) to the model and returns the generated text.
  * `GemmaXR.startSession()` / `addMessage()` / `getNextReply()` – For multi-turn chat, maintain an internal history.
    This API will handle converting Dart types to the proper native calls (e.g. converting `imageBytes` to a platform image object, or sending stream events for partial results).

* **Method Channels & Streams:** We’ll use Flutter method channels to invoke native methods for loading the model and performing inference. For **streaming responses**, we can use an `EventChannel` or callback mechanism: the native code will call back with partial tokens which we forward as Dart stream events. (The MediaPipe `generateResponseAsync` gives us `partialResult` and a `done` flag in a callback, which we can hook into an event stream of tokens).

By structuring the plugin this way, the Flutter side remains simple while heavy lifting (model inference) happens in optimized native code.

## Android Implementation (Kotlin)

On Android, we will implement a platform channel in Kotlin to handle the Gemma 3n model using Google’s **MediaPipe Tasks SDK**:

1. **Include MediaPipe LLM dependency:** Add the Maven dependency for the GenAI tasks. For example, in the plugin’s Gradle config:

   ```gradle
   implementation "com.google.mediapipe:tasks-genai:0.10.24"
   ```

   This gives us the `LlmInference` classes needed to run Gemma models. We also include any required dependencies for image handling (MediaPipe provides `BitmapImageBuilder` for converting images).

2. **Loading the model:** When Flutter calls `loadModel`, the Kotlin code will:

   * Copy the `.task` file to a accessible path (e.g. app’s files directory) if it's packaged in assets. (MediaPipe can load from a filesystem path; direct asset access is not possible, so we copy once and reuse).
   * Build the `LlmInferenceOptions` with the model path and desired settings. For a multimodal model, we call `options.setModelPath(modelPath).setMaxNumImages(1)` and likely `setPreferredBackend(GPU)` given we target high-end devices.
   * Create the `LlmInference` instance:

     ```kotlin
     llmInference = LlmInference.createFromOptions(context, options)
     ```

     This initializes the Gemma 3n model in memory, ready for inference. If the model is large, this may take a moment, but is done only once.

3. **Handling multimodal inputs:** For vision support, we must enable the vision modality in the session. We will:

   * Create an `LlmInferenceSessionOptions` with `GraphOptions.setEnableVisionModality(true)`. This informs the engine to expect image input.
   * When the Flutter app requests a generation with an image (e.g. user calls `generateReply(prompt, imageBytes: ...)`), the Kotlin code will:

     * Convert the `Uint8List` image bytes to a `Bitmap` and then to an `MPImage` (MediaPipe’s image container) via `BitmapImageBuilder(bitmap).build()`.
     * Call the session’s `addImage(mpImage)` to feed the image to the model. (Important: as per MediaPipe’s spec, we add the text prompt *first*, then the image, so the model knows the image is referenced by the prompt.)
   * If only text is provided, we simply skip the image step. The API is flexible: the session will ignore image inputs if the model or session isn’t configured for vision.

4. **Generating a response:** We will support both synchronous and streaming calls:

   * **Synchronous**: The native code can call `session.generateResponse()` which returns the full generated text answer. We send this string back over the method channel to Dart.
   * **Streaming**: For lower latency or long answers, we use `session.generateResponseAsync { partialText, done -> ... }`. In the callback, we receive incremental tokens or chunks of text. We will forward these partial results to Flutter via an EventChannel stream. For example, each `partialText` can be sent as an event, and when `done == true` we close the stream. This way, the Flutter app can update captions in real-time as text is generated (useful for XR captioning).

5. **Speech input (future):** Although Gemma 3n’s audio encoder isn’t publicly available yet, we design the Android side to be extensible. In the future, if Google enables audio prompts in `.task` models, the plugin could accept a microphone audio stream. We might then integrate Google’s USM (Unified Speech Model) or use the MediaPipe audio tasks to transcribe speech on-device, and feed that text into Gemma. Additionally, for **sound localization**, the plugin can optionally expose hooks to pass in directional metadata (e.g. if the XR device’s microphones calculate an azimuth, we can tag the output text with that direction). However, for the MVP, we assume audio will be handled externally (or via a separate ASR model) and focus on **text+image** inference.

6. **Resource management:** Provide methods to unload the model or close sessions to free memory. For example, if the app goes to background, we might allow `GemmaXR.close()` to release the native model (`llmInference.close()` in MediaPipe). This prevents memory leaks on these large models.

The Android implementation heavily relies on the MediaPipe LLM APIs as illustrated above. This ensures we use a **proven, optimized code path** for running Gemma 3n. For instance, the official guidance uses exactly this approach to enable Gemma 3n vision models on Android, which gives us confidence in performance and correctness.

## iOS Implementation (Swift)

On iOS, we follow a similar pattern using Google’s AI Edge **iOS SDK**. We will create a Swift (or Objective-C) counterpart that mirrors the Android functionality:

* **MediaPipe iOS Setup:** Add the Google MediaPipe Tasks library for iOS (likely via CocoaPods or Swift Package Manager). Google provides an iOS LLM inference API analogous to Android’s. For example, an `MPPLLInference` class exists for iOS with similar methods. We will link the proper frameworks (the MediaPipe `.xcframework` or Cocoapod) that includes LLM support.
* **Model Loading:** When Flutter calls `loadModel`, the Swift code will copy the `.task` file into the app’s documents directory (if not already present). Then we configure the model. In Swift, this might look like:

  ```swift
  let options = MPPLlmInferenceOptions()
  options.modelPath = modelFilePath  
  options.maxTokens = 1024  
  options.maxNumImages = 1  
  options.preferredBackend = .GPU
  let llm = MPPLlmInference(options: options)
  ```

  (The actual class names might differ, but conceptually we set the model path and enable image inputs similarly to Android.) We then create a session (`MPPLlmInferenceSession`) and enable vision mode if needed. This corresponds to the `setEnableVisionModality(true)` we did on Android.
* **Inference Calls:** The Swift session will have methods to add text and image. For example, if using Objective-C interface, we might have `[session addQueryChunk:prompt]` and `[session addImage: mpImage]`. (We will convert `FlutterStandardTypedData` from Dart into a UIImage/CIImage and then into the MediaPipe image format for input.) After adding inputs, we call the equivalent of `generateResponseAsyncWithCallback` to get results. We’ll use GCD or background queues to ensure this doesn’t block the main thread.
* **Communicating with Flutter:** The plugin uses the Flutter iOS method channel to send the final or partial texts back. On iOS, we can send partial tokens via `FlutterEventSink`. The structure is analogous to Android: one unified Dart Stream interface receiving tokens from either platform side.
* **Memory and Performance:** We’ll pay attention to iOS memory limits. Gemma 3n models can be a few GB in memory, so we ensure the model is loaded once. Because we target modern iPhones/iPads or Apple Vision Pro (for XR), which have strong hardware, running a 1–2GB model should be feasible. We might utilize Apple’s ANE (neural engine) if MediaPipe supports it – the backend selection in options may automatically use ANE as “GPU” or “best” backend on iOS.

The core idea is that both Android and iOS implementations use the **same logic and sequence** provided by Google’s LLM API. This guarantees consistent behavior across platforms. Any platform-specific details (file paths, image conversion, threading) will be handled in the respective native code.

## Dart API Design for the Plugin

To make our plugin easy to use in Flutter apps (including our live\_captions\_xr project), we will design a friendly Dart API. Drawing inspiration from `flutter_gemma`, we plan the following Dart components:

* **Model Manager:** A class or singleton (`GemmaXR.instance`) that handles loading and caching the model file. It will expose methods like `loadAssetModel(String assetPath)` to streamline moving the `.task` from Flutter assets to device storage and initializing the native model. (This approach is mentioned in the flutter\_gemma docs: *“loadAssetModel... you do not need to load the model every time; it is stored in system files”*). We will similarly persist the model path and not reload if already loaded.

* **Inference/Chat Session:** We can provide a `GemmaSession` object to manage a conversation or sequence of queries. For example, `GemmaSession(sessionId)` could hold context. Methods on it:

  * `sendText(String userPrompt)`
  * `sendImage(Uint8List imageBytes, [String prompt])` – attach an image with an optional prompt (or a follow-up question about the image).
  * `generateReply({stream: true})` – triggers the native inference. If `stream=true`, it returns a Dart `Stream<String>` of partial response tokens; if false, it returns a `Future<String>` with the full response.
    Internally, these will call the method channel or event channel as appropriate.

* **Message Abstraction:** As seen in `flutter_gemma`, we might include a simple `Message` model class for convenience. For example, `Message.withImage(text, imageBytes)` to package a user query that includes an image. The session could accept such Message objects. This is sugar on top of the core API but can make integration in UI (like chat widgets) easier.

Using the above, a typical usage in Flutter might look like:

```dart
await GemmaXR.instance.loadAssetModel('assets/gemma-3n-E2B-it-int4.task');  
var session = GemmaXR.instance.startSession(visionEnabled: true);  
session.sendText("Describe what you see");  
session.sendImage(pickedImageBytes);  
Stream<String> responseStream = session.generateReply(stream:true);  
responseStream.listen((token) { appendSubtitle(token); });  
```

This pseudocode shows a user sending a text query and an image to the model, then receiving a streaming caption response that the app could display word-by-word. Our plugin will handle all the low-level details under the hood (passing the image to native, combining text+image in the correct order, etc.).

## Handling Multimodal Inputs (Vision & Audio)

**Vision (Images):** Support for image inputs is a first-class feature in our plugin, given Gemma 3n’s capabilities. We ensure that when a model supporting vision (like the `E2B-it` variant) is loaded with `supportImage: true`, the native side enables vision mode. The plugin’s API will make it simple to include images, as illustrated with `Message.withImage()` and related methods. Under the hood, we rely on the model’s **built-in vision encoder** via the MediaPipe API (no custom CV code needed). As verified by Google’s examples, adding an image to the LLM session is straightforward and part of the normal flow. We will also document to developers that they should add the text prompt before the image (our plugin can enforce or handle this automatically). Common image formats (JPEG, PNG) will be accepted and converted internally.

**Audio (Speech):** Although not immediately supported by the Gemma 3n task, we anticipate adding this later. The plugin is designed with an extensible architecture: for example, we could integrate a **speech recognition** stage that converts microphone audio to text (using a TFLite model or MediaPipe audio task) and then feeds that text into the Gemma model. This could either be inside the plugin or a separate module that works in tandem. For **spatial audio localization**, the app (live\_captions\_xr) will likely compute sound direction via device sensors, and then can call something like `GemmaXR.instance.tagNextCaption(direction)` or include metadata with the query. The Gemma model itself might not handle spatial data, but our plugin can append a tag or utilize multiple models (e.g., a sound source separator) to inform the UI.

In summary, our initial implementation focuses on text and image modalities, but the infrastructure lays the groundwork to incorporate audio. MediaPipe’s unified design for text/image/audio means when Gemma’s audio encoder becomes available, we can add `setEnableAudioModality(true)` similarly and feed audio input frames to the model, just as we do with images.

## Performance Considerations

Building for speed and performance is a top priority. Here are the key measures and trade-offs in our approach:

* **On-Device Inference & Acceleration:** By using the `.task` format and MediaPipe runtime, we ensure the model runs fully on device with optimized kernels. The `.task` file we target is int4 quantized, which greatly reduces model size and speeds up inference at some accuracy cost. This int4 model is intended to leverage GPU acceleration on mobile. We will default to GPU backend for supported devices, with a fallback to CPU if GPU is unavailable. MediaPipe can handle this automatically, or we can explicitly set `preferredBackend` in options. High-end Android phones and iPhones have ample RAM (8GB+ recommended for multimodal) and powerful GPUs, so we expect smooth performance in our target XR hardware.

* **Memory Management:** Gemma 3n models (especially multimodal ones) can be large (1-2+ GB). We will load one model instance and reuse it to avoid overhead. We also heed platform constraints: on Android, using a physical device or an emulator with increased RAM is necessary (the hackathon project already notes needing increased RAM for testing). Our plugin will document these requirements and possibly expose a check/warning if the device has insufficient memory. If needed, we can allow loading a smaller variant (e.g., a 1B parameter model) as a configuration for lower-end devices.

* **Streaming and Latency:** To achieve real-time captions, streaming generation is crucial. We will utilize the asynchronous generation with partial callbacks. This way, the first words of a caption appear almost immediately (hundreds of ms) rather than waiting for the entire sentence. In testing on-device LLMs, partial results dramatically improve perceived speed. We’ll make sure our Dart stream processing is efficient (using isolates or minimal UI thread work to update captions).

* **Threading and Async:** The native inference calls will run off the main thread. On Android, MediaPipe handles this internally (we just provide a callback). On iOS, we will dispatch the heavy work to a background queue. The plugin’s method channel calls will thus be asynchronous, ensuring we don’t block the Flutter UI.

* **Minimal Overhead:** We are effectively wrapping a C++ inference engine, so we want to avoid adding overhead in Dart/Flutter. The data transferred (prompts and results) are relatively small (text and maybe an image). We will send the image bytes over the channel just once per query, which is acceptable. The main overhead could be token-by-token streaming, but each token is just a short string, so even a few hundred events is fine. (The benefits of streaming outweigh the minor overhead of Flutter event handling.) If needed, we can batch tokens or send larger chunks to reduce event frequency.

In essence, by using Google’s purpose-built inference engine, our plugin will achieve near-native performance. The **MediaPipe LLM API was built for exactly this scenario** – running models like Gemma on phones at decent speeds, e.g. 50-200ms token latency with int4 on a Pixel device. Our job is mainly to integrate it cleanly into Flutter.

## Extensibility for Custom Models

Down the line, we want to allow users to drop in their own models (fine-tuned Gemma variants or other Transformer models). We will design the package to be **model-agnostic** where possible:

* **Support arbitrary `.task` or `.tflite` models:** Initially, we focus on Gemma 3n `.task`, but the plugin can be extended to load any compatible model. MediaPipe’s LLM API supports other open models (Falcon, StableLM, etc.) as long as they are converted to the task format. We can expose a parameter for `ModelType` or simply let the user provide a path to their model file. (The plugin might detect certain model names to apply known settings, e.g., if it’s a Gemma vs another model, but fundamentally loading and inference are similar.) If later we add direct `.tflite` support, we could bypass the `.task` wrapper, but since `.task` includes tokenizers and metadata, it’s usually easier to work with.

* **LoRA and Fine-Tuning:** The plugin could allow loading of LoRA adaptation weights to modify the base model’s behavior. We would plan an API like `applyLora(String loraPath)` which on native side would call something akin to `options.loraPath = ...` if supported. This is not a priority for the MVP, but the architecture (initializing model options) accounts for it.

* **Continuous Improvement:** As MediaPipe releases updates (e.g., supporting audio or new model formats), we will update our plugin to accommodate those. The hackathon context suggests rapid developments in Gemma/MediaPipe, so our implementation should be kept flexible rather than hard-coding specific model details. For example, rather than a class named specifically for Gemma, we might name it generically (like `OnDeviceLLMPlugin`) internally and configure for Gemma by default.

In conclusion, our approach to building this inference plugin centers on **using the right tools for the job**: Google’s optimized on-device AI runtime. By doing so, we meet the performance needs of real-time XR captioning and multimodal interaction, while also achieving fast development turnaround. The plugin will make Gemma 3n’s capabilities readily accessible to our Flutter app and others, with a clean API and the ability to grow (adding new models or modalities) as needed.

**Sources:** The design draws on Google’s documentation and examples of running Gemma on-device. Notably, Google’s AI guides show how `.task` models and MediaPipe enable text and image inference on mobile, and community packages like `flutter_gemma` demonstrate the viability of such a Flutter plugin approach. All these informed our implementation strategy.


Perfect. I’ll create a comprehensive PRD document for the custom Flutter plugin that supports streaming, real-time audio ASR and multimodal (audio + image) inference using `.task`-based Gemma 3n models. This will include architecture details, API design, and deployment considerations for Android (including XR) and iOS.

I’ll also include a small Dart code example showing how to stream microphone audio and an image input through the plugin to generate contextual captions.

I’ll get started and let you know when it’s ready for review.


# Product Requirements Document: Gemma 3n Streaming Flutter Plugin

## Overview and Objectives

The **Gemma 3n Streaming Plugin** is a custom Flutter plugin enabling real-time on-device speech recognition with multimodal context. It leverages Google’s **Gemma 3n** model architecture – a state-of-the-art multimodal AI model optimized for mobile – to transcribe live microphone audio into text (closed captions) in real time, optionally using a camera image as additional context. The goal is to deliver **real-time closed captioning** on mobile and XR devices (Android, Android XR, and iOS), entirely on-device for privacy and low latency. This plugin is built as a hackathon MVP but designed with a clear path to production, emphasizing extensibility and performance.

**Key objectives include:**

* **Streaming ASR (Automatic Speech Recognition):** Capture live microphone audio and stream it into Gemma 3n’s audio encoder for on-device speech-to-text transcription. The plugin should output partial captions in real-time (word-by-word or token-by-token) and finalize the transcript when speech input ends.
* **Multimodal Input (Audio + Image):** Support combined audio + vision inference by feeding an optional image (e.g. camera frame or context image) alongside audio. Gemma 3n natively supports image and audio inputs simultaneously, allowing the model to use visual context to improve or augment captioning results.
* **Cross-Platform Flutter API:** Provide a Dart interface that works on Android (including specialized Android XR devices) and iOS, abstracting the native implementations. Developers should be able to initialize the model and start streaming with a few lines of Dart code.
* **Native Performance via MediaPipe:** Under the hood, use Google’s MediaPipe/AI Edge Task APIs for **on-device inference**. This ensures optimized execution on mobile GPUs/CPUs and integration with Gemma 3n’s `.task` model files. The plugin must harness **Gemma 3n’s optimized encoders** (MobileNet-v5 for vision, USM-based for audio) and streaming capabilities (Gemma 3n’s audio encoder produces \~6 tokens per second, one per 160 ms of audio) to achieve low-latency transcription.
* **Real-Time Closed Captioning:** The plugin focuses on low-latency output for live captions. Partial transcription results (incomplete words or interim captions) should stream out continuously as the user speaks, giving an instant feedback loop, and then a final corrected caption when the utterance is complete. This aligns with Gemma 3n’s design for streaming token generation.
* **Extensibility and Model Flexibility:** While the MVP will target a specific Gemma 3n model (e.g. the 2B effective parameter model `gemma-3n-E2B-it-int4.task` for its smaller size), the plugin architecture should allow swapping in other `.task` models in the future (for example, an upgraded 4B model for better accuracy, or user-fine-tuned models). No support for raw `.tflite` or ONNX is required yet, but the design should not preclude adding such support later.

## User Story and Use Cases

* *Real-Time Captioning (Accessibility):* A deaf or hard-of-hearing user wears an Android XR headset or uses a smartphone to get live subtitles of someone speaking nearby. The app using this plugin streams the conversation through the mic, and captions appear with only a fraction-of-a-second delay. The environment’s image (from the device camera) can be provided to the model to help interpret context (for example, distinguishing homophones based on visual context).
* *Augmented Reality Assistant:* In an AR scenario, the device’s camera sees an object or scene while a person is speaking about it. The plugin feeds both the audio and the current view image into Gemma 3n, which can transcribe the speech with awareness of the visual context. This could enable captions like “*(pointing at a tool)* **User**: *Hand me the **saw***” – the model, seeing a saw in view, correctly transcribes “saw” (tool) instead of “saw” (past tense of see).
* *Multilingual On-Device Translator:* Although primarily for captions, the same setup can enable speech translation on-device. Gemma 3n supports 140 text languages and 100+ spoken languages. A developer could prompt the model to transcribe and translate audio (e.g. Spanish speech to English text) using this plugin. While translation UI is beyond MVP scope, ensuring the plugin handles Unicode text and different language outputs is relevant.

## Key Features and Requirements

### 1. Streaming Audio Inference Pipeline

**Live Microphone Streaming:** The plugin must continuously capture audio from the device microphone and feed it into the Gemma 3n model’s audio encoder **in real time**. We will use a 16 kHz mono audio stream, as required by Gemma’s audio tokenizer (16 kHz with 32ms frames). The audio pipeline should chunk the audio into small frames (e.g. 160 ms windows) and process them promptly. Gemma 3n’s **Universal Speech Model (USM)**-based encoder produces one token per \~160 ms of speech, so the system should aim to supply audio frames at that rate. This will enable the model to output new transcript tokens about \~6 times per second, achieving a smooth, word-by-word transcription.

**Partial and Final Results:** The plugin must emit **partial captions** as the user speaks, updating the text in the UI word-by-word or token-by-token. For example, if the user says “Hello world”, intermediate outputs might be “H…”, “He…”, “Hello …”, and finally “Hello world.” Gemma 3n’s LLM inference supports streaming generation, providing sequential output tokens for better UX. The plugin should capture these tokens and send them immediately to Flutter through a Stream or callback. When the model signals an end-of-transcription (for instance, via a special token or a pause in audio), the plugin should mark the last result as **final**, indicating no further updates for that segment. The API should make it clear to developers what constitutes partial vs final results (e.g. via a boolean flag or separate event types). This real-time feedback loop is crucial for closed captioning usability.

**Microphone Control & Audio Preprocessing:** On both Android and iOS, the plugin should handle microphone initialization (using Android’s `AudioRecord` or `MediaRecorder`, and iOS’s `AVAudioEngine` or `AVAudioRecorder`). Audio will be captured in short intervals (e.g. 20–30 ms frames) and buffered until \~160 ms of audio is ready to send to the model. The plugin must downmix to mono if needed and ensure the audio is in 16-bit PCM or float32 format normalized to \[-1,1] as expected. For efficiency, the plugin might perform minimal preprocessing (the heavy lifting of feature extraction is handled by Gemma’s encoder in the `.task` model). If needed, a small **circular buffer** can accumulate audio to ensure we meet the frame size required by the model’s audio encoder. The pipeline should also handle voice activity detection (if the model doesn’t inherently know when to stop) – for MVP, a simple silence timeout can determine end-of-utterance.

**Threading and Latency:** Audio capture and inference should run on background threads so as not to block the UI. On Android, the AudioRecord reading and MediaPipe inference calls will execute in a background `HandlerThread` or via Kotlin coroutines. On iOS, use a background `DispatchQueue` for capturing audio buffers and running inference. This design ensures that emitting tokens \~6 times a second does not stutter the Flutter UI. Our target is **sub-300ms latency** from spoken word to displayed text, which is feasible given Gemma 3n’s optimized streaming (it introduces special caching to accelerate streaming responses). The plugin should minimize internal buffering to achieve this.

### 2. Multimodal Inference (Audio + Vision)

**Image Context Support:** The plugin will allow an image to be fed into the model along with the audio stream. Gemma 3n is **multimodal by design**, supporting image+text (and image+audio) inputs natively. The plugin’s API should provide a method to set or update the **vision context** – for example, passing in a camera frame as an `InputImage` or bytes. If an image is provided, the plugin will use the Gemma 3n model’s built-in **MobileNet v5** vision encoder to process the image and provide visual embeddings to the language model. This image should be optionally updated, e.g., if the camera view changes or for each new session of captioning. In many cases, the image might remain constant during a live captioning session (e.g., an AR glasses user looking at one scene).

**Inference with Image and Audio:** When an image is available, the plugin must ensure it is added to the model’s context **before or along with audio tokens**. Using MediaPipe’s APIs, we will enable the vision modality in the model session (e.g., `GraphOptions.setEnableVisionModality(true)` and allow one image input). The Android MediaPipe example shows adding an image to the session via `session.addImage(BitmapImageBuilder(image).build())`. Similarly on iOS, the API will have an equivalent call to feed an image (likely using a CVPixelBuffer or `MPImage` in Swift). The plugin will manage a **multimodal session** such that the image’s influence persists across the streaming transcription. For instance, if a user is talking about what they see, the image can subtly bias the language model’s predictions.

**Session Management:** A **session** refers to an inference instance of the Gemma model that holds context (like conversation history, or in this case, the image and audio context). The plugin should manage the LLM session lifecycle: initialize a session when starting captioning, feed it the image (if any) and continuously feed audio. If the session ends (e.g., after a final output or after a timeout of silence), we may either reuse the session for subsequent speech (clearing the audio state but retaining image context if desired) or start a fresh session. The PRD requirement is to handle multimodal input simultaneously, so the design will treat audio+image as part of one combined prompt. The image can be thought of as a persistent prompt context until changed or session reset. The plugin should provide methods to **update or clear the image context**. For example, if the user points their camera elsewhere, the app can send a new image to the plugin, which will update the model’s context for future transcriptions. We must ensure thread-safe updating of the image (e.g., not replacing the image while an ongoing generation is mid-stream to avoid race conditions – possibly lock or queue updates between utterances).

### 3. Flutter API Design

**Dart API and Usage:** The plugin will expose a high-level Dart API that’s easy for Flutter developers to use. Key class could be `GemmaStreamingCaptioner` (singleton or instantiable) that provides methods like:

* `Future<void> initialize(String modelPath, {bool useGPU})` – Loads the Gemma 3n `.task` model from assets or file system and initializes native resources. Configuration such as preferred backend (GPU/CPU) can be optional (default to GPU if available). This uses the MediaPipe LLM Inference API under the hood to create the model and session.
* `void startListening()` – Starts capturing microphone audio and streaming inference. Optionally, `startListening({Image? visionContext})` could accept an image to use from the start. This will begin the flow of partial caption events.
* `void stopListening()` – Stops the microphone and ends the current transcription session. This would yield a final result if not already produced. It may also free some caches.
* `void setVisionContext(Image image)` – (Optional) Provide or update the vision context image *during* an ongoing session or before starting one. This lets the user set a new image (from camera or gallery) that the model should consider. If called mid-stream, it might only affect subsequent tokens; typically it could be set right before `startListening` or between utterances.
* **Stream/Callback for Results:** The plugin will provide a `Stream<CaptionResult>` or similar that developers can listen to. Each `CaptionResult` would carry a `String text` (the current partial or final caption) and a flag `isFinal`. The plugin will push updates to this stream as the model generates new tokens. This is implemented via Flutter’s `EventChannel` or `StreamController` that gets events from the native side.

**Synchronous vs Streaming API:** While streaming is the focus, the plugin can also offer a synchronous one-shot transcription method for completeness (e.g., `Future<String> transcribeAudioClip(File wavFile)` that processes a whole file or a buffered chunk and returns a transcript). This would use the same model but feed a fixed audio sequence rather than live mic. However, for MVP the emphasis is streaming; synchronous calls can be added easily by feeding audio in non-real-time and waiting for the final result. The architecture should separate the **streaming pipeline** from a potential synchronous utility, but both can reuse the same model/session management code.

**Error Handling and Permissions:** The API should surface errors gracefully – e.g., if the model fails to load or if the microphone permission is missing/denied. Initialization should throw a useful exception or return an error `Future` if something goes wrong (e.g., model file not found or incompatible). The plugin must also handle microphone permission requests: it can provide a helper to request permission, or expect the app to handle it prior to starting the plugin. In the PRD scope, we ensure the plugin won’t crash if permission is absent; it should notify the Flutter side of the issue (perhaps via a `status` stream or by the `startListening()` Future completing with an error).

### 4. Native Integration (Android and iOS)

To achieve the above features, the plugin uses **platform-specific implementations** with MediaPipe’s AI libraries:

* **Android (Kotlin + MediaPipe Tasks):** On Android, we will include the MediaPipe **Task Library for LLM Inference** (and possibly the Audio library for capturing mic). The integration can be done by adding the Maven dependency for `com.google.mediapipe:tasks-android:latest` and enabling the `mediapipe_beta` flag if needed for the Generative AI tasks (Gemma 3n support is relatively new, likely marked beta). The plugin’s Android code (`android/src/main/kotlin/.../GemmaStreamingPlugin.kt`) will obtain a `LlmInference` instance by loading the `.task` file from app storage. We will use `LlmInferenceOptions` to configure the model path, max output tokens, and preferred compute backend. Notably, we set `.setMaxNumImages(1)` and `.setGraphOptions(GraphOptions.builder().setEnableVisionModality(true).build())` if an image is to be used. The Android implementation will manage an `LlmInferenceSession` for the active captioning; it will call `session.addQueryChunk()` to feed text or audio tokens, `session.addImage()` for images, and use the **streaming callback API** `session.generateResponseAsync(resultListener)` to get token-by-token callbacks. We will implement `ResultListener` to receive generated text chunks from the model as they stream out, and forward these to Dart via an `EventChannel`. Audio integration: Android will use `AudioRecord` in a separate thread to read PCM frames (16kHz). As audio frames are captured, we will convert them to the format expected by the MediaPipe audio encoder. **Two possible approaches:** (a) **Use MediaPipe’s audio API** – if an `AudioTask` or direct method exists to feed audio to the LLM (to be researched; Gemma’s audio encoder might be invoked internally by simply providing audio tokens). If MediaPipe doesn’t expose a direct audio feed method in LLM API yet, (b) we may manually convert audio frames to tokens using the same **USM model** approach – however, since the `.task` bundle likely contains the audio encoder graph, the proper way is to feed raw audio as a special input to the LLM. We will explore using the C++ Task API: possibly calling `session.addAudio(ByteBuffer audioChunk)` if available. If not, a workaround is to run an `AudioEmbedder` from MediaPipe to get embeddings – but given Gemma 3n’s integration, the more straightforward approach is expected. The Android code will ensure that for each 160 ms of audio, a corresponding token is generated by the model, effectively treating the audio as part of the “prompt.”

* **iOS (Swift + MediaPipe Tasks):** On iOS, we will integrate the analogous MediaPipe LLM libraries. Google’s AI Edge provides an **iOS `.xcframework` or CocoaPod** for the tasks (e.g., `GoogleAIEnterprise` or `MediaPipeTasks` pod). The plugin’s iOS code (`ios/Classes/GemmaStreamingPlugin.swift`) will set up the model similarly by pointing to the `.task` file in the app bundle or documents directory. Using Swift, we’ll create an `MPGLlmInference` instance (MediaPipe’s iOS API, which should mirror Android’s LlmInference). We will configure model options like `maxTokens`, `enableVisionModality`, etc. In Swift, the callback for streaming might be a closure that gets called with generated text chunks. We’ll use these callbacks to send events back to Flutter. Microphone capture on iOS will use `AVAudioEngine` or `AVCaptureAudio` to get a PCM buffer. We will convert that to the proper format (Mono 16k float32) and feed it into the Gemma model’s audio encoder. Like Android, we’ll either call an appropriate method in the API if available (e.g., perhaps adding audio might be done by converting audio to an `MPPacket` or using a general `MPPInferenceRunner`). If the iOS API lacks direct audio feeding calls, we might need to preprocess audio through a separate USM model; however, given Gemma 3n’s integrated design, we anticipate a unified API call. The iOS code must manage Objective-C interop for the event channel to notify Dart. We’ll ensure the audio capture and inference run on a background thread (using GCD).

**MediaPipe and Google AI Edge Integration Notes:** Both platforms will require bundling the Gemma 3n model file. At \~3 GB for int4 quantized (`E2B-it-int4`), this model might be too large for inclusion in the app bundle by default. Instead, the plugin may expect the app to supply the path (downloaded at runtime or added as an asset and unpacked). The PRD assumes the model file is available on device storage and its path is given to `initialize()`. The plugin documentation will advise how to obtain the `.task` (e.g., from Hugging Face or Google). MediaPipe’s LLM APIs were introduced recently, and **Gemma 3n support is cutting-edge** (MediaPipe was the first library to run Gemma 3n from day one). We will closely follow official guides and sample code to ensure compatibility. For instance, the **Edge Gallery** GitHub project by Google can serve as reference for loading .task models. We also note that Gemma 3n’s `.task` uses a special format (zip of multiple components including the audio/vision encoders) which had some initial loading bugs on certain platforms; we’ll track the latest MediaPipe version that resolves these issues (the plugin should specify a minimum version requirement for the underlying native libraries).

### 5. Performance and Memory Considerations

**Model Size and Quantization:** The default model targeted (`gemma-3n-E2B-it-int4.task`) is \~3.1 GB on disk and represents a **2B-equivalent model quantized to int4**. This int4 quantization dramatically reduces size and memory usage, with only a slight hit to accuracy. Running this on modern mobile SoCs is feasible: E2B requires roughly 2GB of RAM on the accelerator (GPU), which high-end phones and XR devices (like Snapdragon XR2-based headsets) can provide. The plugin must be mindful of memory usage: on Android we will load the model into memory once and reuse it (the LLM engine should be a singleton). We should avoid any unnecessary copies of the model or buffers. For better performance on capable devices, the plugin can allow switching to the larger `E4B-int4` model (\~4.4 GB, \~4B parameters), but this will demand \~3GB GPU memory and is optional. The API can expose a knob (model path) for developers to choose models based on device capability.

**GPU vs CPU:** Gemma 3n can run on CPU, but for real-time streaming performance, using the **GPU** is recommended. The plugin by default will initialize the model with `Backend.GPU` (falling back to CPU if GPU is unavailable). This should yield faster token generation and lower latency. XR devices (like AR glasses or VR headsets) often have a dedicated GPU and **thermals to consider** – running the model continuously might heat up the device. We will include options such as adjusting `maxTokens` or using the smaller model to manage performance. The PRD’s focus is on *closed captioning*, which typically generates transcripts roughly equal in length to the input speech. For example, 30 seconds of speech (max recommended per segment) might generate \~90 tokens of text; Gemma 3n can handle this with streaming and caching optimizations like KV cache sharing. We must ensure the plugin handles these long streams efficiently, perhaps by leveraging Gemma’s ability to reuse cache and avoid re-processing the entire audio context each time (the MediaPipe session likely does this internally). If memory becomes an issue in long sessions, the plugin can chunk the session or drop oldest context (though for pure transcription, we generally don’t need to keep past conversation context except within one sentence).

**Latency Targets:** The end-to-end pipeline from audio capture to token output should be optimized for minimal delay. The audio encoder being streaming means we don’t have to wait for a full sentence; the plugin should send audio to the model continuously rather than batching large chunks. The use of partial results means the UI gets incremental updates. We will measure and aim that the **first token latency** is low. Gemma 3n’s improvements like faster prefill ensure a first token speed possibly around 0.5–1.0 tokens/sec in worst case (prefill refers to initial prompt encoding), but since our prompt is small (just an image and the start of audio), first token should appear quickly. In any case, the plugin design must not introduce additional delays – e.g., avoid long audio buffers. A potential performance consideration is audio I/O – using a smaller audio buffer (e.g. 256 samples \~16ms) for read can reduce latency but increases CPU wake-ups; 160ms (2560 samples) is one token’s worth of audio, so an approach is to accumulate \~160ms then push to model. We will tune this for a good balance.

**XR Specifics:** On AR/VR devices, the plugin might be running alongside rendering and other sensor processing. We must ensure **thread priority** for audio capture is high (to avoid audio dropouts if the CPU is busy). The GPU inference might need to run in parallel with graphics; since VR apps aim for e.g. 72-90 FPS, we should consider running the model at a slightly lower priority than rendering. However, Gemma 3n int4 is efficient; it can achieve on the order of a few tokens per second on mobile GPU. If a device struggles, one strategy is to switch to CPU offloading of some parts (Gemma 3n’s PLE offloads some embeddings to CPU by design) – but that is internal. We can, however, expose an option to use **CPU backend** if GPU contention is an issue (bearing in mind CPU will be slower). We should document that on XR devices with limited thermal headroom, continuous use will affect battery and possibly frame rates – so developers might use this plugin in short bursts or with smaller models if needed.

**Memory Management:** We will pay attention to cleaning up the model session after use. The plugin’s `dispose()` or equivalent should free the `LlmInference` and `LlmInferenceSession` objects on native side, release the audio recorder, and release any large buffers. This prevents memory leaks especially critical on iOS where long-running apps could otherwise hold onto multiple GB of memory. We will test for memory spikes when starting/stopping sessions repeatedly. Also, if the model is loaded once and kept in memory across sessions (likely for performance), we must ensure it does not continue to accumulate context indefinitely. MediaPipe’s LLM Session might automatically truncate or forget old interactions beyond a certain limit, but since our use case is one prompt (image + audio) -> one output, we can simply close and recreate sessions for clean slate if needed.

### 6. Extensibility and Future Plans

While this plugin targets a hackathon MVP, the design choices enable future growth:

* **Model Swappability:** As mentioned, developers can drop in newer `.task` files. For instance, if Google releases Gemma 4 or a larger Gemma 3n variant, the plugin can load it as long as it’s MediaPipe-compatible. We’ll ensure the initialization doesn’t hard-code model specifics except for default suggestions. We also plan to allow user-provided **LoRA adapters** or fine-tuned `.task` models to be used (Gemma supports LoRA via config). This could mean adding an `applyLora(String loraPath)` method in future.

* **Additional Modalities:** Gemma 3n also supports **video** input (sequence of images) theoretically. In the future, the plugin could accept a video stream or consecutive camera frames to provide dynamic visual context. Another extension is output modalities: currently output is text, but a future Gemma might output audio or perform actions (with function calling). The plugin architecture (especially the event streaming) can be extended to handle non-text outputs if needed (for example, returning an audio clip or an action code). For now, we keep it text-only.

* **Raw Models and Conversion:** Though out of scope now, the plugin could later support loading raw TFLite models or ONNX models by converting them on-the-fly to `.task` or using a different runtime. The architecture (with a clear separation between Dart API and native inference logic) makes it possible to swap out the inference engine (MediaPipe) with another backend if needed. For example, a future version might integrate directly with TensorFlow Lite if Google releases a TFLite for Gemma, or use `ggml/llama.cpp` for experimental support. Our MVP sticks to `.task` files and MediaPipe, which is the official and optimized path.

* **Production Hardening:** To move from MVP to production, additional features would be added: more robust VAD (voice activity detection) to auto-start/stop the transcription when speech is detected; adaptive microphone gain or noise suppression for better accuracy; and possibly a caching mechanism for the vision context (if the image is static, no need to re-encode it for every new session – we could reuse the embeddings across sessions to save time). The plugin’s structure will account for these potential improvements (e.g., holding onto the vision encoder output while the camera image hasn’t changed, rather than reprocessing it each time).

In summary, this Flutter plugin will encapsulate the complexity of streaming multimodal inference into a developer-friendly package. By utilizing Gemma 3n’s cutting-edge on-device capabilities – its audio encoder for **streaming ASR** and its vision encoder for image context – we meet the requirements for a real-time captioning tool that runs privately on user devices. The architecture prioritizes performance (GPU acceleration, quantized models), and the design is forward-compatible with larger models or additional features.

---

# Technical Specification and Implementation Plan

## Plugin Architecture & File Structure

The plugin follows Flutter’s federated plugin structure with platform-specific code in **Android** (Kotlin) and **iOS** (Swift) and a Dart API:

* **Dart Package (lib folder):** Contains `gemma_streaming.dart` which exports the main API class `GemmaStreamingCaptioner`. This class uses Flutter’s `MethodChannel`/`EventChannel` to communicate with native code. It implements the public methods: `initialize()`, `startListening()`, `stopListening()`, `setVisionContext()`, etc., and a `Stream<String>` or `Stream<CaptionResult>` for results. It may also define data classes like `CaptionResult`. The Dart code handles converting high-level Flutter calls into method channel invocations and listening to event channel streams for the transcription updates.

* **Android (android/src/main/kotlin/...):** Will include:

  * `GemmaStreamingPlugin.kt` – the main plugin class that implements `MethodCallHandler` and sets up the `EventChannel`. This will manage a singleton instance of an `InferenceManager` or similar.
  * `InferenceManager.kt` – a helper singleton (or part of the plugin class) that holds references to the MediaPipe `LlmInference` and current `LlmInferenceSession`. It has methods to initialize the model (loading the `.task` file from assets/path), to start a session (set up listeners, etc.), and to stop/cleanup. It will also contain the `ResultListener` for streaming outputs which pushes events to Flutter via a cached `EventSink`.
  * `AudioCapture.kt` (optional) – a class for managing `AudioRecord`. It sets up the audio recorder with 16kHz mono, reads bytes or floats in a loop, and calls a callback to feed the data to the model. It may run on a separate thread using a `HandlerThread`. If the MediaPipe LLM API provides an `AudioTask` or direct function to handle audio frames, the code might be integrated in `InferenceManager` instead. But abstracting it in `AudioCapture` keeps things organized.
  * The Android manifest might need to include the `RECORD_AUDIO` permission. We will also ensure to handle the permission request from Dart side (via `PermissionHandler` or manual `ActivityCompat.requestPermissions`).

  The Android native code will use **MediaPipe’s Task API**. Integration may involve adding `.aar` libraries. If using Gradle dependencies, we add in build.gradle (app level):

  ```gradle
  implementation "com.google.mediapipe:tasks-vision:latest-release"   // for vision support
  implementation "com.google.mediapipe:tasks-text:latest-release"    // possibly needed for LLM?
  implementation "com.google.mediapipe:tasks-llm:latest-release"     // hypothetical naming
  ```

  (The exact artifact names might be `tasks-core` and `tasks-genai` as per Google AI Edge docs.) These include the native code to run `.task` files and the JNI interfaces we’ll call. We also need to place the `.task` model in accessible storage. For dev ease, the model could be placed in `android/app/src/main/assets` and then copied to device on first run, or downloaded. In code, the path will be given by Flutter (e.g., copying from asset to filesDir and then path).

* **iOS (ios/Classes/...):** Will include:

  * `GemmaStreamingPlugin.swift` – main plugin class, conforms to `FlutterPlugin`. It sets up method call handlers and event channels similarly. It will create an instance of an `InferenceManager` (could be just a class in the same file or separate).
  * `InferenceManager.swift` – manages the model and session on iOS. It uses MediaPipe’s iOS tasks API. This likely involves importing frameworks like `MediaPipeTasks` or `TensorFlowLite` (depending on how Google packages it for iOS). We might use a wrapper class provided by Google, e.g., `MPPLLMInference` (fictional example) or we might have to write some bridging to C++. Google’s sample code or AI Edge iOS guide will clarify this. We will ensure thread-safe operations using GCD.
  * `AudioCapture.swift` – (optional) an audio engine handler. We can use Apple’s `AVAudioEngine` to tap the microphone input. For example, create an `AVAudioEngine` with an input node, install a tap on it with buffer size (e.g., 512 or 1024 frames) and 16k sample rate, then start the engine. The tap callback provides audio PCM buffers which we convert to the appropriate format and forward to the inference routine. We must configure the app’s Audio Session (AVAudioSession) for recording.

  For iOS, we will add the necessary pods. Possibly, Google provides a Cocoapod like `GoogleAIEnterprise` or specific `MediaPipeTaskText`/`MediaPipeTaskVision`. If not, we may include TensorFlowLite C++ and the task libraries manually. The plugin’s podspec will list the libraries and linker flags. We also include microphone usage description in the iOS app’s Info.plist (since the plugin uses mic).

* **Shared and Support Files:**

  * The project’s README (not part of code, but delivered to users) will document how to obtain the Gemma .task model due to its large size and licensing.
  * We might include a default small model for quick testing (if available, e.g., a smaller dummy `.task` or instruct developers to download before using).

**EventChannel Communication:** Both Android and iOS will use an `EventChannel` to stream transcription results back to Flutter. The native side will call `events.success(partialText)` for each token or partial result. To mark final results, we could send a special structure (e.g., a JSON or map `{ "text": "...", "isFinal": true }`) or use a separate method call. A simpler approach: send partial transcripts via event stream, and when final, send one last event with `isFinal=true`. The Dart side `Stream<CaptionResult>` can interpret this. Alternatively, maintain two streams (one for partial, one for final) but that complicates things; one stream with a flag is fine.

**File Structure Summary:**

```
flutter_gemma_streaming/
├── lib/
│   └── gemma_streaming.dart        # Dart API implementation
├── android/
│   └── src/main/kotlin/
│        └── com/example/gemma/     # (actual package path to be decided)
│             ├── GemmaStreamingPlugin.kt
│             ├── InferenceManager.kt
│             └── AudioCapture.kt
├── ios/
│   └── Classes/
│        ├── GemmaStreamingPlugin.swift
│        ├── InferenceManager.swift
│        └── AudioCapture.swift
├── assets/ or downloaded/          # (model .task might be placed here during development)
└── pubspec.yaml                    # includes flutter plugin setup
```

## Android Implementation Details

**Model Initialization:** In `InferenceManager.kt`, `initialize(modelPath: String, useGpu: Boolean)` will be implemented. It will construct `LlmInferenceOptions.builder()` with the model path, set `maxTokens` to a default (say 512 or 1024, though for streaming caption we might not need extremely high output length) and choose backend GPU or CPU. If vision is anticipated, we call `.setMaxNumImages(1)`. Then we call `LlmInference.createFromOptions(context, options)`. This gives us an `LlmInference` object (the loaded model). Next, we create a session: `LlmInferenceSessionOptions.builder()` – here we set decoding parameters: e.g., `topK`, `topP`, `temperature` as desired (we might default to moderate values, or even expose them later). Crucially, if an image will be used, we enable vision modality in the graph options. We then get `session = LlmInferenceSession.createFromOptions(llmInference, sessionOpts)`. This session will be used for generation.

**Audio Feeding:** For streaming, we can’t just call `generateResponseAsync` once and wait because we need to continually provide audio. Instead, the design is: as the user speaks, audio tokens are added to the session and the model incrementally generates output. We might use a loop: continuously read audio frames and call something like `session.addAudioChunk(audioBytes)` if it existed. Since the MediaPipe API doesn’t explicitly show `addAudioChunk` in the snippet, an alternative is to convert the audio chunk to text tokens via the audio encoder. However, a more straightforward idea: Represent audio to the model as special tokens. The Gemma prompt in Google’s example shows `<start_of_audio> ... <end_of_audio>` wrapping audio content. The model expects the audio in the input sequence; how to deliver it programmatically is the question. Possibly, **MediaPipe automates this:** if the .task has an audio encoder, there might be an API to feed raw audio and under the hood it converts to tokens and feeds the model. Given the lack of obvious API in LlmInferenceSession, another strategy emerges: use a **secondary pipeline** – e.g., use MediaPipe’s Audio encoder (if accessible) to transform audio to text tokens, then feed those tokens as if they were part of the text prompt. This could be complex in real-time. Instead, we look at MediaPipe’s C++ or consult latest docs for an audio method. If none, a workaround is: accumulate audio and when the user stops, feed `<start_of_audio> + [audio wave] + <end_of_audio>` to a single generate call. But that loses streaming ability. It’s possible that streaming audio might require feeding dummy text tokens (like some representation). Since the Gemma 3n audio encoder outputs tokens every 160ms, perhaps those are essentially text tokens (like sequence of characters from a special vocabulary). For MVP, if direct streaming integration proves difficult, we plan a simpler interim approach: record audio in short segments (e.g. 0.5s), and sequentially do inference calls after each segment, appending to previous context. However, this is suboptimal and could be slow. We will prioritize leveraging Gemma’s native streaming if at all possible. (One promising sign: MediaPipe’s graph-based approach might allow us to set up a custom graph connecting an `AudioStream` to the LLM. That could be an advanced integration beyond simple Task API usage, possibly using lower-level calculators.)

**ResultListener and Streaming Output:** MediaPipe LLM inference provides an asynchronous generation with callbacks. We will call `session.generateResponseAsync(resultListener)` once we have fed initial input (which might include some initial audio or just an empty prompt to start streaming). The `ResultListener` interface has methods like `onPartialResults` or repeated `onResult` calls – typically for vision or text, but for LLM, likely the listener receives updates for each new output token. The code will look for functions like `LlmInferenceSessionResult` that contain generated text. Possibly, each callback gives the cumulative output so far. We will parse that and send to Flutter. If the API only gives final output at once, we may instead use `session.setResultListener()` that streams tokens (similar to how text classification can stream partial results). The medium article suggests sequential output is indeed supported. We’ll implement accordingly.

**Audio Stop and Finalization:** When `stopListening()` is called from Dart or when silence is detected, the Android code should finalize the session. If we have been adding audio incrementally, we might then allow the model to finish generating remaining tokens and then call `session.close()`. If instead we had to call generate in segments, we would combine outputs. Ideally, with true streaming, `ResultListener` will eventually flag completion (maybe via an `isComplete` or simply no more callbacks). We will then push a final event with `isFinal=true` and reset or dispose the session.

**Concurrency:** Protect `session` and model from concurrent calls. For example, ensure that we don’t call `generateResponseAsync` again while one is in progress. If the user starts a second session, either queue it or reject until the first is closed. The Dart side can prevent overlapping calls (by disabling the start button, etc., but we also enforce in native).

## iOS Implementation Details

**Model Setup:** Using Swift, after adding the appropriate MediaPipe frameworks, we’ll create the model inference similarly. Likely something like:

```swift
let options = MPPLlmInferenceOptions()
options.modelPath = ... // path to gemma3n.task in app bundle
options.maxTokens = 1024
options.maxNumImages = 1
options.preferredBackend = .GPU
let llm = try MPPLlmInference(options: options)
let sessionOpts = MPPLlmInferenceSessionOptions()
sessionOpts.topK = 40
sessionOpts.topP = 0.9
sessionOpts.temperature = 1.0
sessionOpts.enableVisionModality = true
let session = try llm.createSession(options: sessionOpts)
```

(This pseudo-code is based on analogous Android calls; actual API might differ in naming.)

**Audio Streaming:** On iOS, capturing audio via `AVAudioEngine` is straightforward. We configure an input node with a desired format (16k mono). The engine’s hardware sample rate might be 48k, so we use AVAudioConverter or set the input node’s output format to 16k if possible. The audio tap gives us PCM `AVAudioPCMBuffer`. We convert to float32 array and then feed to the model. If MediaPipe iOS has a method like `session.addAudio(_ buffer: [Float])`, we will use it inside the tap callback. Otherwise, as with Android, we need a plan B. Perhaps one approach: *use the Hugging Face `transformers` logic via C++ or a smaller model to get tokens.* But given the tight timeline of hackathon, likely the Gemma’s audio encoder is accessible. We recall that the `.task` file includes `TF_LITE_EMBEDDER` (which might be the audio embedder). Possibly the API might treat audio as a kind of “query chunk” too – for example, `session.addQueryChunk(audioData: Data)` or something along those lines. We will consult any available docs; if none, we might integrate the **Google AI Whisper-like encoder**. USM is essentially a large model; maybe the .task already quantized it. If needed, a very hacky fallback: use a lightweight local model (like Whisper tiny) to get interim transcripts – but that defeats the purpose of Gemma’s integrated approach. We are banking on the fact that Gemma 3n is advertised with audio input, so the MediaPipe API should support it at or soon after launch. If it’s not directly in the tasks API, possibly in the **C API** or via constructing a custom calculator graph. As a last resort for MVP, iOS could mirror what Android does (if Android path is found). The plugin spec allows that some lower-level bridging might be needed, which could increase complexity but is manageable in C++ if both iOS and Android share some C++ helper to run the audio encoder model.

**Event Streaming:** On iOS, once generation starts, we need to capture partial outputs. Possibly the MediaPipe iOS callback uses delegation or notifications. We’ll implement the delegate to receive new tokens and forward them over the event channel. We have to ensure thread-safe calls to Flutter’s event sink (likely dispatch to main thread when sending events).

**Lifecycle:** Manage the lifecycle similar to Android. Memory is a bigger concern on iOS due to ARC – ensure no strong reference cycles (the plugin probably doesn’t hold strong ref to session if not needed). Also handle interruptions: if the app goes to background, we might need to pause audio, etc. (MVP can ignore background operation if not needed, or simply stop).

## Token Streaming and Partial Outputs Implementation

**Token Handling:** Gemma 3n outputs text as a sequence of tokens that form words/sentences. The MediaPipe LLM API likely assembles tokens into readable text for us (as seen in examples where `response.candidates(0).content` yields a string). So we might not have to deal with raw token IDs. For partial results, the API could either give a full string so far or incremental token text. We will take the string and send it out. One consideration: we might get partial results that overwrite the previous (for example, if the model changes its guess of a word as more audio comes in). The plugin should handle that gracefully – possibly by replacing the last partial output with an updated one. If using a stream, we’ll just send new ones; the Flutter UI can decide to simply show the latest. For final output, once signaled, that text is confirmed and can be, for instance, shown in a separate style or new line.

**End-of-utterance Detection:** The model might output a special token or just stop generating new tokens if it senses end of audio. We could also use a silence detector on the audio stream (e.g., if volume drops below threshold for >1s, conclude speech ended, then send an explicit `<end_of_audio>` to the model to prompt finalization). If the model requires an explicit end, we will insert it. Possibly, the .task could allow sending a special `addQueryChunk("<end_of_audio>")` token or a method like `session.markAudioEnd()`. We will search API docs for clues. If not, we implement a timer-based approach in the plugin: when silence is detected, stop audio capture and call `session.close()` which should finalize generation.

**Testing and Tuning:** We will test the plugin with various scenarios: continuous speech vs pausing mid-sentence, to see how partial results behave. We aim to avoid duplicating text. If partial results are always whole sentences, we might need to accumulate them. Ideally, partial results are incremental.

**Example Flow:** When user taps “Start”, we call `startListening()`. Under the hood:

* Native: Start audio recorder, create session, if image context is present add it, then call `generateResponseAsync(listener)`. Possibly also immediately send a special token indicating audio will follow (Gemma uses `<start_of_audio>` internally). Now as audio flows, the model starts producing text. The listener gets “Hello” (partial) then “Hello w” then “Hello wo…” etc. We throttle or directly send each update to Flutter. When user stops (or auto-stop triggers), we call `stopListening()`, which stops mic and maybe sends `<end_of_audio>` token, then waits for the model to finalize “Hello world.” and ends. We send the final result event and tear down the session (or keep it if we plan to reuse for next utterance).

**Memory of Past Captions:** For closed captioning use case, each session stands alone (we transcribe independent utterances). But if a use case wanted to treat it like a conversation (not likely for captioning, but theoretically), the plugin could keep the session open across multiple user utterances so the model has context. That’s more relevant for conversational AI; for captioning, we will **reset context each time** to avoid confusion. So by default after final output, the session is closed or reset (clearing any stored text).

## Validation of Requirements

This technical spec addresses all PRD points: streaming microphone audio via Gemma’s audio encoder, multimodal audio+image input, a unified Flutter API, and use of native MediaPipe for inference. Real-time captioning is achieved with streaming token output, and we’ve accounted for performance on mobile/XR (using int4 quantized models, GPU acceleration, and careful threading). The file structure and architecture allow future extensions like model swaps or added features.

By implementing as above, we expect to deliver a functional plugin that meets the hackathon MVP needs while laying groundwork for a production-quality on-device multimodal captioning system.

---

## Example Dart Usage Snippet

Below is a hypothetical example of how a Flutter developer would use the Gemma 3n streaming plugin in their application:

```dart
import 'package:gemma_streaming/gemma_streaming.dart';

// 1. Initialize the plugin and load the model
final captioner = GemmaStreamingCaptioner();
await captioner.initialize(
  modelPath: '/assets/models/gemma-3n-E2B-it-int4.task', 
  useGPU: true,
);

// 2. Optionally, set a vision context (e.g., a camera image)
Uint8List imageBytes = /* obtain an image frame as bytes */;
captioner.setVisionContext(imageBytes);

// 3. Start streaming live audio from the microphone
captioner.startListening();

// 4. Listen to the streaming caption outputs
captioner.captionStream.listen((CaptionResult result) {
  if (!result.isFinal) {
    // Update UI with partial caption
    print('Partial: ${result.text}');
    // (In a real app, show this partial caption on screen live)
  } else {
    // Display the final caption result
    print('Final caption: ${result.text}');
    // (In UI, perhaps add this as a permanent subtitle and clear partial display)
  }
});

// ... Later, when stopping is needed (e.g., user taps a button or app closes):
captioner.stopListening();
```

In this snippet:

* We create and initialize the `GemmaStreamingCaptioner` with the path to a Gemma 3n `.task` model. The model is loaded and prepared using the native MediaPipe backend (GPU enabled).
* We then provide an image as context via `setVisionContext` (this could be skipped if no image is available). This image will be used by the model to inform the transcription.
* We call `startListening()`, which begins capturing microphone audio and streaming it into the model.
* We subscribe to `captionStream` to receive `CaptionResult` events. This stream yields a sequence of partial transcription texts, and then a final text when the speech segment is done. We differentiate partial vs final by the `isFinal` flag. In an actual UI, partial results might be shown with lighter font, and final result could replace or be added when ready.
* Finally, we call `stopListening()` to stop the capture and end the session (this would typically be done automatically after a final result, or manually if the user cancels).

This example demonstrates a simple usage scenario: the developer does not need to handle any low-level audio or model logic – the plugin abstracts it, providing a straightforward way to get live captions from audio (and image) input.

Thanks for confirming. I’ll develop a hybrid implementation plan for speaker localization and contextual caption placement using:

* Audio-based localization via TDOA from the phone's microphone array
* Visual speaker detection from the phone’s camera feed
* IMU-based spatial anchoring
* Optional fusion with Gemma 3n’s multimodal capabilities to enhance direction estimation and speaker association

The result will include architecture, signal processing pipeline, and annotated Flutter and Swift code examples for both the plugin (inference layer) and LiveCaptionsXR (app layer). I’ll get back to you shortly with a detailed design and working example tailored to iPhone 16 Pro Max and XR devices.


# Implementing On-Device Speech Localization and AR Captioning with Gemma 3n

## Overview of the Approach

**Goal:** Use an iPhone (e.g. iPhone 16 Pro Max) to **detect where speech is coming from (localize the speaker)** and display **live captions** near the speaker. We'll implement this in two contexts: a **Gemma 3n inference** package (for audio processing and transcription) and the **LiveCaptionsXR app** (for the AR visualization in 2D/3D). Modern phones have the necessary components – **multiple microphones, camera, and AR capabilities** – to achieve this:

* **Audio** (microphone array) for detecting speech direction.
* **Camera** for identifying the speaker's location (face/mouth movement).
* **AR** (e.g. ARKit) for placing caption bubbles in **3D space** or overlaying in **2D**.

**Solution Outline:**

1. **Capture Stereo Audio & Estimate Direction:** Use the phone’s multiple mics to record stereo audio. Analyze the **left vs. right channel** differences to estimate the speaker’s direction (e.g. angle relative to the camera).
2. **Transcribe Speech On-Device:** Feed the audio into **Gemma 3n** (Google’s on-device multimodal model) to get the speech-to-text transcription in real time. Gemma 3n’s integrated **audio encoder** (based on Google’s **USM**) can handle streaming ASR on-device.
3. **Visual Localization (Optional Hybrid):** For better accuracy (especially if multiple people), use the camera to **detect faces** and identify which person is speaking (e.g. via mouth movement). This can refine the audio-based direction.
4. **Display Captions in AR:** Depending on mode, either overlay the text in **2D** on the camera feed at the correct screen location, or create a **3D text bubble** anchored at the speaker’s real-world position (using ARKit). Style the bubble like movie closed-captioning (e.g. white text on a semi-transparent black background).

We'll now break down the implementation for **(A) the Gemma 3n audio inference package** and **(B) the LiveCaptionsXR app**, with example code snippets and detailed comments.

## A. Audio Capture and Localization with Gemma 3n (Inference Package)

First, we set up **audio recording** on iPhone to capture **stereo** input. iPhones (with iOS 14+) support stereo recording from the built-in mics. This gives us two-channel audio where differences between channels indicate sound direction. We configure `AVAudioSession` for stereo and start an audio engine or capture session:

```swift
import AVFoundation

class SpeechLocalizer {
    // Gemma 3n model instance for ASR
    private let gemmaModel: Gemma3nASR = Gemma3nASR()  // Pseudo-class for Gemma 3n ASR
    
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let audioFormat: AVAudioFormat
    
    init() throws {
        // 1. Configure AVAudioSession for stereo recording
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, options: [])  // .record or .playAndRecord as needed
        try session.setMode(.measurement)              // use .measurement or .videoRecording mode for best mic behavior
        try session.setActive(true)
        
        // Select built-in microphone and request stereo polar pattern (if supported)
        if let builtInMic = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
            try session.setPreferredInput(builtInMic)
            // Find a data source oriented to the front (toward camera)
            if let dataSource = builtInMic.dataSources?.first(where: { $0.orientation == .front }) {
                // If stereo is supported, set the polar pattern to stereo
                if dataSource.supportedPolarPatterns?.contains(AVAudioSession.PolarPattern.stereo) == true {
                    try dataSource.setPreferredPolarPattern(.stereo)
                }
                try builtInMic.setPreferredDataSource(dataSource)
            }
        }
        // Set input orientation matching the device holding (e.g. .portrait)
        if #available(iOS 14.0, *) {
            try session.setPreferredInputOrientation(.portrait)
        }
        
        // 2. Set up AVAudioEngine for capturing audio frames
        inputNode = audioEngine.inputNode
        audioFormat = inputNode.outputFormat(forBus: 0)
        
        // Install a tap to get audio samples
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { [weak self] buffer, when in
            // Callback for each audio buffer (stereo PCM samples)
            self?.processAudioBuffer(buffer)
        }
    }
    
    func startRecording() throws {
        // Start the audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // 3. Separate the left and right channel audio
        guard let channelData = buffer.floatChannelData, buffer.format.channelCount == 2 else {
            return  // Not stereo data
        }
        let frameCount = Int(buffer.frameLength)
        let leftChannel = channelData[0]
        let rightChannel = channelData[1]
        
        // Calculate average volume (RMS) for left vs right as a simple direction cue
        var leftSum: Float = 0, rightSum: Float = 0
        vDSP_measqv(leftChannel, 1, &leftSum, UInt(frameCount))    // use Accelerate to get mean square
        vDSP_measqv(rightChannel, 1, &rightSum, UInt(frameCount))
        let leftLevel = sqrt(leftSum)
        let rightLevel = sqrt(rightSum)
        
        // Determine rough left-right balance
        let levelDiff = leftLevel - rightLevel
        let sum = leftLevel + rightLevel
        var horizontalAngle: Float = 0  // angle in radians, 0 = center, positive = to right
        if sum > 0 {
            horizontalAngle = (levelDiff / sum) * (.pi/2)  // scale difference to ±90 degrees range (approx)
        }
        
        // (Optional) Use cross-correlation for finer time difference measurement:
        // For brevity, not implemented fully here. In practice, you'd compute the delay between channels to refine the angle.
        
        // 4. Get speech transcription from Gemma 3n (speech-to-text)
        // Convert the PCM buffer to the format Gemma model expects (e.g. 16 kHz mono)
        let monoPCM = downmixToMono(buffer: buffer)
        gemmaModel.transcribeAsync(audioPCM: monoPCM) { [weak self] resultText in
            // Once transcription is ready, deliver the result with the estimated angle
            self?.onTranscriptionAvailable(text: resultText, angle: horizontalAngle)
        }
    }
    
    private func downmixToMono(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
        // Downmix stereo to mono by averaging channels (Gemma ASR likely requires mono audio)
        // ... (Implementation detail: create new AVAudioPCMBuffer with 1 channel and copy averaged samples)
    }
    
    // Callback to send out localized transcription result
    var onTranscriptionAvailable: (_ text: String, _ angle: Float) -> Void = { text, angle in }
}
```

**Explanation:** In the above pseudocode, we:

* Configure the audio session for **stereo recording** using the built-in mic. We attempt to set a **stereo polar pattern** and appropriate **input orientation** (portrait) so that left/right channels correspond to the phone’s left/right directions when held upright. (On iPhone, **stereo** recording uses multiple mics to produce a binaural effect where sound coming from the phone’s front is balanced, and sound from the sides emphasizes one channel.)

* Use `AVAudioEngine` to tap into the audio stream. Each buffer provides **stereo PCM samples**. We compute a basic metric: the **Root Mean Square (RMS)** amplitude of left vs. right channel. If, for example, the **left channel** has higher amplitude than the right, the sound source is likely towards the **left side** of the phone (and vice versa for the right). We convert this difference into a rough **horizontal angle**. (Here we simply scale the level difference to an angle within ±90° range; a more precise method would use **Time Difference of Arrival (TDOA)** via cross-correlation of the two channels to estimate the angle.)

* **Downmix to mono** for speech recognition. Gemma 3n’s ASR model likely expects a single-channel audio input (e.g. 16 kHz mono). We combine the stereo channels into one (to not confuse transcription with stereo effects).

* Pass the audio to Gemma 3n for transcription. *Gemma 3n*, with its **integrated audio encoder**, performs **on-device Automatic Speech Recognition (ASR)**. Gemma 3n can handle streaming audio (processing in \~160 ms chunks) thanks to being based on Google’s **Universal Speech Model (USM)**. In practice, this might involve using Gemma’s API or a Hugging Face `pipeline` for ASR. For example, the Gemma model can be prompted to transcribe audio segments. Here, we assume `gemmaModel.transcribeAsync` handles sending the audio to the model and returns text.

* Finally, when we get the transcription text from Gemma, we call `onTranscriptionAvailable(text, angle)`. This callback will be handled by the **LiveCaptionsXR app** to place the caption in the UI/AR scene at the appropriate location.

**Note:** The **direction angle** we computed is relative to the **device’s orientation**. For example, `angle = 0` means sound from directly ahead (along the back camera’s viewing direction), negative angle = left, positive = right. We currently do not compute vertical angle (we assume sound is roughly on the same plane). The accuracy of a small two-mic array is limited, but it’s sufficient to distinguish left vs right or general direction for our use case. We can refine this using visual cues, as described next.

### (Optional) Using Visual Cues to Identify the Speaker

In many cases, especially in **AR scenarios**, we can use the camera to **assist** in localizing the speaker:

* **Face Detection:** Using frameworks like Apple’s Vision or ARKit, detect faces in the camera feed. If a face is roughly in the direction indicated by audio (e.g. left side of screen for a leftward audio angle), we can assume that person is speaking.

* **Mouth Movement:** For multiple faces, we can analyze which face’s **mouth is moving** in sync with the speech. For instance, Vision can provide facial landmarks (lips, etc.) or one could use frameworks like MediaPipe. The face with a rapidly opening/closing mouth when speech is detected is likely the speaker. This **hybrid audio-visual approach** improves accuracy in noisy settings or when people are close together.

In our implementation, once the audio package detects speech, the **LiveCaptionsXR app** (next section) could perform a quick face scan on the video frame to find a matching person at the estimated angle. If found, it yields a more precise **3D position** for the speaker (using depth/AR data). If not, we’ll rely on the audio angle alone for positioning.

## B. LiveCaptionsXR App – Displaying 2D/3D Caption Bubbles

The app uses the outputs from the Gemma 3n package – the **transcribed text** and **speaker direction** – to display captions in the user’s view. We will support two modes:

**1. 2D Mode (HUD Overlay):** Draw caption text directly onto the screen (2D overlay), positioned near the speaker’s image in the camera view.

**2. 3D Mode (AR Bubble):** Create a 3D caption bubble in the AR world at the speaker’s location, so it stays anchored in place as you move the phone.

The iPhone’s **ARKit** will be used for the 3D mode (and can also provide a camera feed background for 2D mode). We assume we have an AR view (ARSCNView or ARView) in the LiveCaptionsXR app’s interface.

### 1. 2D Caption Overlay Implementation

In 2D mode, we simply overlay a **UILabel** (or a SwiftUI/Text) on the camera preview. We determine the screen coordinate for the speaker:

* If we detected a face for the speaker (via Vision), use the face bounding box (for example, position the caption label slightly above the person’s head in the image).
* If we only have an audio angle, we can map the angle to an approximate screen position. For instance, an angle of -45° (speaker to the left) might correspond to placing the text toward the left side of the screen. We might assume the speaker is at some distance such that -45° lands near the left edge of the camera view.

**Example (simplified):** If using Vision to get face rect `faceFrame` in the UI coordinate space:

```swift
func showCaption2D(text: String, faceFrame: CGRect?) {
    let captionLabel = UILabel()
    captionLabel.text = text
    captionLabel.textColor = .white
    captionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    captionLabel.layer.cornerRadius = 6
    captionLabel.layer.masksToBounds = true
    captionLabel.numberOfLines = 0
    captionLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
    captionLabel.sizeToFit()
    
    if let face = faceFrame {
        // Position label above the detected face
        let x = face.midX - captionLabel.bounds.width/2
        let y = face.minY - captionLabel.bounds.height - 10
        captionLabel.frame.origin = CGPoint(x: max(0, x), y: max(0, y))
    } else {
        // No face info – position based on audio angle as fallback
        let screenWidth = UIScreen.main.bounds.width
        let xPos = screenWidth/2 + CGFloat(tan(currentAngle)) * (screenWidth/2)
        captionLabel.center.x = max(20, min(screenWidth-20, xPos))
        captionLabel.center.y = UIScreen.main.bounds.height * 0.3  // put it towards top third
    }
    
    self.view.addSubview(captionLabel)
    
    // Optionally, animate and remove the caption after a few seconds
    UIView.animate(withDuration: 0.3) {
        captionLabel.alpha = 1.0
    }
    DispatchQueue.main.asyncAfter(deadline: .now()+5) {
        captionLabel.removeFromSuperview()
    }
}
```

Here we create a `UILabel` with styling similar to closed captions (white text on black background with some opacity). If a face bounding box is available, we position the label above that face. Otherwise, we fallback to using the audio angle (`currentAngle`, which we’d get from the `onTranscriptionAvailable` callback) to position the label horizontally. This is a rough placement – the 3D mode will do a more accurate job by actually anchoring in space.

### 2. 3D AR Caption Bubble Implementation

For the 3D mode, we use ARKit to place a **SceneKit text node** (SCNText) or a **billboarded plane with text texture** in the 3D world at the speaker’s location. There are two main steps:

**(a) Determine 3D Position of Speaker:**
If we identified the speaker’s face in the camera image and we have ARKit running with **scene depth** or LiDAR, we can estimate the distance to the speaker. One approach is to perform a **raycast** or hit-test in ARKit: take the 2D point of the face (center of the bounding box) and cast a ray into the AR scene to find an intersecting real-world surface. If the person is standing on the floor or near a wall detected by ARKit, the ray might hit that plane at roughly the right distance. If LiDAR is available, ARKit’s `sceneDepth` data could directly give a depth value for the person’s face point. In absence of these, we might assume a default distance (say 2 meters) for placing the caption in that direction.

We can combine the **device’s orientation** with the audio angle to construct a direction vector. For example, using ARKit’s camera transform matrix `cameraTransform`:

```swift
func anchorForSpeaker(angle: Float, distance: Float = 2.0) -> ARAnchor {
    // angle: horizontal angle in radians (device coords)
    guard let frame = sceneView.session.currentFrame else {
        return ARAnchor(transform: matrix_identity_float4x4)  // fallback: anchor at origin
    }
    // Compute a direction vector in camera space for the given horizontal angle
    // Assuming angle around the Y-axis (yaw), and 0 is forward (negative Z in camera coord).
    var directionInCamera = simd_float4(0, 0, -1, 0)  // forward unit vector
    let rot = simd_float4x4(SCNMatrix4MakeRotation(angle, 0, 1, 0))  // rotation around y-axis
    directionInCamera = rot * directionInCamera
    // directionInCamera is a vector pointing to the sound source direction in camera space.
    
    // Now translate by the desired distance in that direction
    var transform = matrix_identity_float4x4
    transform.columns.3.x = directionInCamera.x * distance
    transform.columns.3.y = directionInCamera.y * distance
    transform.columns.3.z = directionInCamera.z * distance
    // The above transform is relative to camera; convert to world by multiplying with camera transform:
    let worldTransform = frame.camera.transform * transform
    return ARAnchor(transform: worldTransform)
}
```

This function creates an `ARAnchor` at `distance` meters away from the camera, in the direction specified by `angle`. We’ll adjust `angle` based on audio (and possibly adjust vertically if needed). In practice, if we have a face detection with depth info, we would use that exact position instead for better accuracy.

**(b) Display a Text Bubble at the Anchor:**
With an ARAnchor in place, we add a custom **SceneKit node** or **RealityKit entity** to visualize the caption. Using SceneKit for example, we can create an `SCNText` geometry for the caption string, and an `SCNPlane` behind it to serve as a background “bubble”. We make sure the text always faces the camera (**billboarding**), or simply not worry if it’s roughly at face height and the user is generally in front of the speaker.

**Example using SceneKit:**

```swift
// Assuming we have an ARSCNView named sceneView
func createCaptionNode(text: String) -> SCNNode {
    // Create 3D text geometry
    let textGeometry = SCNText(string: text, extrusionDepth: 0.0)
    textGeometry.font = UIFont.boldSystemFont(ofSize: 10)   // base font size (will scale)
    textGeometry.flatness = 0.1  // level of detail
    
    // Material for text
    let textMaterial = SCNMaterial()
    textMaterial.diffuse.contents = UIColor.white
    textGeometry.materials = [textMaterial]
    
    // Create node for text
    let textNode = SCNNode(geometry: textGeometry)
    // Scale down the text (SCNText is often large by default)
    textNode.scale = SCNVector3(0.005, 0.005, 0.005)
    
    // Create a semi-transparent background plane behind the text
    let (minVec, maxVec) = textNode.boundingBox
    let textSize = SCNVector3(maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z)
    let plane = SCNPlane(width: CGFloat(textSize.x * 1.1), height: CGFloat(textSize.y * 1.4))
    plane.cornerRadius = plane.width * 0.1  // rounded corners
    let bgMaterial = SCNMaterial()
    bgMaterial.diffuse.contents = UIColor.black.withAlphaComponent(0.8)
    plane.materials = [bgMaterial]
    let planeNode = SCNNode(geometry: plane)
    // Position plane node so that it is just behind the text
    planeNode.position = SCNVector3(minVec.x + textSize.x/2, minVec.y + textSize.y/2, minVec.z - 0.01)
    
    // Add the plane as a background of text
    textNode.addChildNode(planeNode)
    
    // Make the whole caption node face the camera (billboard constraint)
    let constraint = SCNBillboardConstraint()
    constraint.freeAxes = .Y    // rotate only around Y (so it always faces user)
    textNode.constraints = [constraint]
    
    return textNode
}

// When transcription result comes in:
speechLocalizer.onTranscriptionAvailable = { [weak self] text, angle in
    // Remove old caption node if any, then:
    let anchor = self?.anchorForSpeaker(angle: angle)      // create ARAnchor at estimated position
    if let anchor = anchor {
        self?.sceneView.session.add(anchor: anchor)
    }
    // Store the text for this anchor
    self?.pendingCaptions[anchor.identifier] = text
}

// ARSCNViewDelegate: render node for anchor
func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    // Check if this anchor is one of our caption anchors
    if let captionText = pendingCaptions[anchor.identifier] {
        let captionNode = createCaptionNode(text: captionText)
        // Optionally animate the appearance
        captionNode.opacity = 0
        captionNode.runAction(SCNAction.fadeIn(duration: 0.5))
        // Automatically remove after few seconds:
        captionNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 5.0),
                                                 SCNAction.fadeOut(duration: 0.5),
                                                 SCNAction.removeFromParentNode()]))
        return captionNode
    }
    return nil
}
```

In this code:

* `createCaptionNode(text:)` builds an `SCNText` and an `SCNPlane` background. We set the plane’s color to semi-transparent black and give it a corner radius for a rounded “speech bubble” rectangle. This achieves a caption style similar to movie subtitles (white text on black background). The approach is based on adding a plane behind `SCNText` for a background.

* We use an `SCNBillboardConstraint` so that the text always orients toward the camera (on the Y-axis), ensuring readability as we move around.

* When a new caption (`text` with `angle`) is available, we compute an ARAnchor at the estimated location (`anchorForSpeaker`). We add it to the AR session. In the `renderer(nodeFor:)` delegate, when ARKit creates a node for that anchor, we attach our caption node. We also schedule the node to fade out and remove after a few seconds (to mimic how live captions appear and disappear).

**Speaker Position Refinement:** If we have a face detection with depth info, we could create the ARAnchor using the face’s real 3D coordinates instead of an angle + assumed distance. For example, ARKit’s `ARFaceAnchor` (for front camera) isn’t directly applicable to rear camera. Instead, one might use **ARBodyTracking** or simply do a hit-test against the AR point cloud. But for initial implementation, using the audio angle and an assumed distance yields a reasonable result – the caption will appear in the correct general direction. If the distance is off, the caption might float a bit in front or behind the speaker, but with a large distance (e.g. 3m) and billboard text, the perspective effect is minor.

## Conclusion and Further Enhancements

We have outlined how to build a system that **localizes speech on a smartphone and displays AR captions** for the speaker. Summarizing key points:

* **Gemma 3n** provides on-device **speech-to-text** capabilities, supporting our need for real-time transcription without cloud services. Its multimodal design could even allow future extensions, like processing audio *and* video together if needed.
* **Audio Localization** on an iPhone leverages the stereo microphones. By analyzing inter-channel differences, we infer the direction of speech. This is fundamentally using the principle of binaural hearing – similar to how humans localize sound with two ears. Keep in mind the phone’s small mic spacing limits precision, but it’s sufficient for left/right and approximate positioning.
* **Augmented Reality Visualization:** Using ARKit, we anchor caption bubbles in 3D space. This creates a more immersive and accurate experience – the captions appear next to the speaker like speech bubbles in a comic, but styled as clean subtitles. We presented a SceneKit-based implementation for rendering text with a background panel. On modern iPhones (with powerful GPUs and LiDAR), this 3D approach runs smoothly in real time.
* **Hybrid Audio-Visual Approach:** We recommend combining audio with camera vision for best results (“where to listen” + “who is speaking”). For instance, once the audio points you to the left, the camera can confirm there’s a person there and even track them if they move. This hybrid method addresses scenarios with multiple people or background noise (“Gemma 3n supports this, but if we need a hybrid, we do it”, as you noted).

**Testing on iPhone 16 Pro Max:** This device has multiple microphones and a LiDAR scanner, making it ideal for our use-case. All three components (mic array, camera, AR framework) are available and high-performance on this model, ensuring that the speech localization and AR rendering happen in real time.

By following the above implementation (and adjusting constants through testing), you should get a working prototype of LiveCaptionsXR. When someone speaks, the app will detect the speech, determine the direction, transcribe the words, and pop up a caption near the speaker – first in roughly the correct place, then sticking to that spot in the 3D view as you move the phone. The end result: an AR experience where spoken words appear as localized captions, empowering users to **see** what’s being said, exactly where it’s being said.

**Sources:** The approach combines knowledge from Apple’s AVAudioSession stereo recording (for direction cues), fundamental audio localization techniques, and AR caption rendering techniques. Gemma 3n’s capabilities for on-device ASR are documented in Google’s developer guide and the Hugging Face release notes, which confirm its audio prowess and suitability for our use-case. All these pieces together make the envisioned LiveCaptionsXR feasible with today's technology. Good luck with the implementation!

Here’s how to break down the previous comprehensive solution into smaller, manageable tasks, each of which can be turned into a separate PRD or development ticket clearly:

---

## 🎯 **Task 1: On-Device Audio Capture and Stereo Recording**

* **Goal:** Set up reliable stereo audio capture using iOS’s `AVAudioEngine`.
* **Deliverable:** An API within the Gemma plugin to provide stereo PCM audio buffers for further processing.
* **Outcome:** Stereo audio stream ready for localization and ASR.

---

## 🎯 **Task 2: Basic Audio Direction Estimation (Left/Right Localization)**

* **Goal:** Estimate speaker direction from stereo audio by analyzing amplitude differences (RMS) between left/right channels.
* **Deliverable:** A directional estimation function that outputs a horizontal angle from audio input.
* **Outcome:** Approximate angle indicating left, center, or right direction of the speaker.
* **Implementation Update:** This task is now implemented in the Dart `SpeechLocalizer` service which computes the angle using RMS amplitude comparison for each stereo audio frame.

---

## 🎯 **Task 3: Advanced Audio Localization using TDOA/GCC-PHAT**

* **Goal:** Implement precise speaker direction estimation by computing Time Difference of Arrival (TDOA) using cross-correlation (GCC-PHAT) of stereo audio streams.
* **Deliverable:** Accurate angle and direction estimation method within the inference package.
* **Outcome:** High-precision localization suitable for AR anchoring.

* **Implementation Update:** This task is now implemented using a GCC-PHAT
  algorithm in the Dart `SpeechLocalizer` service to calculate time-delay
  between stereo channels for precise angle estimation.

---

## 🎯 **Task 4: Integration of Gemma 3n for Streaming On-Device ASR**

* **Goal:** Integrate Gemma 3n’s audio encoder (USM-based) to enable real-time, streaming transcription of audio.
* **Deliverable:** Flutter package API for continuous ASR from audio buffers.
* **Outcome:** Live transcription functionality integrated into Flutter apps.

---

## 🎯 **Task 5: Multimodal Fusion (Audio + Visual) using Gemma 3n**

* **Goal:** Use Gemma 3n’s multimodal model to improve speech transcription accuracy and speaker detection by combining audio and visual inputs (camera frame).
* **Deliverable:** An inference pipeline in Gemma 3n plugin that accepts both audio and camera frame inputs.
* **Outcome:** Improved speech recognition context and accuracy, especially in noisy environments.

---

## 🎯 **Task 6: Face Detection & Speaker Identification via Vision Framework**

* **Goal:** Implement face detection and mouth-movement analysis using Apple’s Vision framework to visually identify active speakers in real-time camera feeds.
* **Deliverable:** A Vision framework-based face-tracking module.
* **Outcome:** Accurate visual identification of speakers, complementing audio localization.

---

## 🎯 **Task 7: ARKit Anchor Creation and Placement for Speaker Localization**

* **Goal:** Create ARKit anchors at locations determined by audio/visual localization.
* **Deliverable:** A reusable AR anchoring method based on audio direction angles and optional visual confirmation.
* **Outcome:** Anchors correctly placed in AR scenes for speaker captions.

---

## 🎯 **Task 8: 2D Caption Rendering (HUD Overlay Mode)**

* **Goal:** Render speech captions in a traditional closed-caption style overlay on the camera feed.
* **Deliverable:** Flutter/Swift component for displaying styled captions at 2D positions on the screen.
* **Outcome:** Immediate visual feedback for speaker localization on standard smartphone screens.

---

## 🎯 **Task 9: 3D Caption Rendering (AR Bubble Mode)**

* **Goal:** Render captions as AR-enhanced, spatially anchored 3D text bubbles in the real-world space.
* **Deliverable:** ARKit or RealityKit-based 3D caption rendering component with billboarding support.
* **Outcome:** Realistic AR captions that stick to speaker locations as user moves.

---

## 🎯 **Task 10: IMU-based Device Orientation Integration**

* **Goal:** Incorporate IMU data (gyroscope, accelerometer) to ensure accurate positioning of captions in response to device motion.
* **Deliverable:** Real-time device orientation handling component.
* **Outcome:** Stable and accurate captions that adjust smoothly as the device moves.

---

## 🎯 **Task 11: Hybrid Localization Strategy (Fusion via Kalman Filter)**

* **Goal:** Combine audio localization, visual face-tracking, and IMU orientation data into a unified robust position estimation using a Kalman filter.
* **Deliverable:** A hybrid localization engine combining multiple data streams.
* **Outcome:** Enhanced accuracy and robustness of localization under various conditions.

---

## 🎯 **Task 12: UX/UI Design for AR Captioning Experience**

* **Goal:** Design intuitive and visually appealing user interfaces and interactions for LiveCaptionsXR app.
* **Deliverable:** UX/UI mockups, design assets, and interaction prototypes.
* **Outcome:** High-quality user experience tailored for both accessibility and engagement.

---

## 🎯 **Task 13: Performance Optimization and Resource Management**

* **Goal:** Optimize GPU/CPU usage and memory handling for AR, ASR, and multimodal processing tasks on mobile hardware.
* **Deliverable:** Performance profiling and optimized resource management implementation.
* **Outcome:** Smooth, responsive app performance suitable for sustained use.

---

## 🎯 **Task 14: Continuous Integration (CI) & Deployment Pipeline Setup**

* **Goal:** Set up automated build, test, and deployment pipelines for the Gemma 3n inference package and LiveCaptionsXR app.
* **Deliverable:** CI/CD workflows (GitHub Actions) for automatic testing and deployment.
* **Outcome:** Reliable, repeatable builds and streamlined deployment process.

---

Each task above can independently form the basis for clear PRDs, making the entire development and testing process structured, modular, and agile.
