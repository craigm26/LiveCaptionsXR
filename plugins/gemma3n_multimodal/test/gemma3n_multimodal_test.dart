import 'package:flutter_test/flutter_test.dart';
import 'package:gemma3n_multimodal/gemma3n_multimodal.dart';
import 'package:gemma3n_multimodal/gemma3n_multimodal_platform_interface.dart';
import 'package:gemma3n_multimodal/gemma3n_multimodal_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/core/message.dart';
import 'package:flutter_gemma/core/chat.dart';

class MockGemma3nMultimodalPlatform
    with MockPlatformInterfaceMixin
    implements Gemma3nMultimodalPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

class FakeModelManager implements ModelFileManager {
  int setPathCalls = 0;
  String? lastPath;

  @override
  Future<bool> get isModelInstalled async => true;

  @override
  Future<bool> get isLoraInstalled async => false;

  @override
  Future<void> setModelPath(String path, {String? loraPath}) async {
    setPathCalls++;
    lastPath = path;
  }

  // The remaining methods are no-ops for testing.
  @override
  Future<void> setLoraWeightsPath(String path) async {}

  @override
  Future<void> downloadModelFromNetwork(String url, {String? loraUrl}) async {}

  @override
  Stream<int> downloadModelFromNetworkWithProgress(String url,
          {String? loraUrl}) async* {}

  @override
  Future<void> downloadLoraWeightsFromNetwork(String loraUrl) async {}

  @override
  Future<void> installModelFromAsset(String path, {String? loraPath}) async {}

  @override
  Future<void> installLoraWeightsFromAsset(String path) async {}

  @override
  Stream<int> installModelFromAssetWithProgress(String path,
          {String? loraPath}) async* {}

  @override
  Future<void> deleteModel() async {}

  @override
  Future<void> deleteLoraWeights() async {}
}

class FakeFlutterGemma extends FlutterGemmaPlugin
    with MockPlatformInterfaceMixin {
  FakeFlutterGemma();

  final FakeModelManager manager = FakeModelManager();
  int createModelCalls = 0;

  @override
  ModelFileManager get modelManager => manager;

  @override
  InferenceModel? get initializedModel => null;

  @override
  Future<InferenceModel> createModel({
    required ModelType modelType,
    int maxTokens = 1024,
    PreferredBackend? preferredBackend,
    List<int>? loraRanks,
    int? maxNumImages,
    bool supportImage = false,
  }) async {
    createModelCalls++;
    return DummyInferenceModel();
  }

  @override
  Future<void> close() async {}
}

class DummyInferenceModel implements InferenceModel {
  @override
  InferenceModelSession? get session => null;

  @override
  InferenceChat? chat;

  @override
  int get maxTokens => 0;

  @override
  Future<InferenceModelSession> createSession({
    double temperature = .8,
    int randomSeed = 1,
    int topK = 1,
    double? topP,
    String? loraPath,
    bool? enableVisionModality,
  }) async {
    return DummyInferenceSession();
  }

  @override
  Future<InferenceChat> createChat({
    double temperature = .8,
    int randomSeed = 1,
    int topK = 1,
    double? topP,
    int tokenBuffer = 256,
    String? loraPath,
    bool? supportImage,
  }) async {
    return InferenceChat(
      sessionCreator: () async => DummyInferenceSession(),
      maxTokens: 0,
    );
  }

  @override
  Future<void> close() async {}
}

class DummyInferenceSession implements InferenceModelSession {
  @override
  Future<void> addQueryChunk(Message message) async {}

  @override
  Future<void> close() async {}

  @override
  Future<String> getResponse() async => '';

  @override
  Stream<String> getResponseAsync() async* {}

  @override
  Future<int> sizeInTokens(String text) async => 0;
}

void main() {
  final Gemma3nMultimodalPlatform initialPlatform = Gemma3nMultimodalPlatform.instance;

  test('$MethodChannelGemma3nMultimodal is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGemma3nMultimodal>());
  });

  test('getPlatformVersion', () async {
    Gemma3nMultimodal gemma3nMultimodalPlugin = Gemma3nMultimodal();
    MockGemma3nMultimodalPlatform fakePlatform = MockGemma3nMultimodalPlatform();
    Gemma3nMultimodalPlatform.instance = fakePlatform;

    expect(await gemma3nMultimodalPlugin.getPlatformVersion(), '42');
  });

  test('loadModel uses flutter_gemma', () async {
    final fakeGemma = FakeFlutterGemma();
    final plugin = Gemma3nMultimodal(gemma: fakeGemma);

    await plugin.loadModel('path/to/model.task', useANE: false, useGPU: true);

    expect(fakeGemma.manager.setPathCalls, 1);
    expect(fakeGemma.manager.lastPath, 'path/to/model.task');
    expect(fakeGemma.createModelCalls, 1);
  });
}
