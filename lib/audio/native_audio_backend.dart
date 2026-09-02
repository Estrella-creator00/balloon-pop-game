abstract interface class NativeAudioBackend {
  Future<void> prepare(String assetPath, int voiceCount);

  void play(String assetPath);

  Future<void> stopAssets(Iterable<String> assetPaths);

  Future<void> releaseAssets(Iterable<String> assetPaths);

  Future<void> stopAll();

  Future<void> dispose();

  int voiceCapacityFor(String assetPath);

  int activeVoiceCountFor(String assetPath);

  int get poolCount;

  int get totalVoiceCapacity;
}

typedef NativeAudioBackendFactory = Future<NativeAudioBackend> Function();

final class NoopNativeAudioBackend implements NativeAudioBackend {
  const NoopNativeAudioBackend();

  @override
  Future<void> prepare(String assetPath, int voiceCount) async {}

  @override
  void play(String assetPath) {}

  @override
  Future<void> stopAssets(Iterable<String> assetPaths) async {}

  @override
  Future<void> releaseAssets(Iterable<String> assetPaths) async {}

  @override
  Future<void> stopAll() async {}

  @override
  Future<void> dispose() async {}

  @override
  int voiceCapacityFor(String assetPath) => 0;

  @override
  int activeVoiceCountFor(String assetPath) => 0;

  @override
  int get poolCount => 0;

  @override
  int get totalVoiceCapacity => 0;
}
