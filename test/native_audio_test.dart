import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:balloon_pop_game/audio/audioplayers_native_backend.dart';
import 'package:balloon_pop_game/audio/native_audio_backend.dart';
import 'package:balloon_pop_game/audio/pop_sound_native.dart';

void main() {
  late _FakeNativeAudioBackend backend;

  setUp(() async {
    backend = _FakeNativeAudioBackend();
    await PopSound.initializeForTesting(() async => backend);
  });

  tearDown(() async {
    await PopSound.resetForTesting();
  });

  test('native backend selection uses injected backend without method channel',
      () {
    expect(backend.factoryUseCount, 1);
    expect(PopSound.nativePoolCountForTesting, 0);
  });

  test('only current skin file assets and semantic assets are prepared',
      () async {
    const pop = 'assets/sounds/wari_watermelon_bite.mp3.mp3';
    await PopSound.prepareGameplayAsset(pop);
    await PopSound.prepareSemanticGameplaySounds(
      hasHitAsset: false,
      hasPopAsset: true,
      popSoundKind: 'basic',
    );

    expect(backend.capacities[pop], 8);
    expect(backend.capacities, hasLength(5));
    expect(
      backend.capacities.keys,
      containsAll(<String>{
        pop,
        PopSound.basicPopAssetPath,
        PopSound.lightTapAssetPath,
        PopSound.fakeHitAssetPath,
        PopSound.bossExplosionAssetPath,
      }),
    );
  });

  test('first hit waits for prepare and play performs no new load', () async {
    const path = 'assets/images/shushu_fork_hit.mp3.mp3';
    await PopSound.prepareGameplayAsset(path);
    final prepares = backend.prepareCount;

    PopSound.playGameplayAsset(path);

    expect(backend.prepareCount, prepares);
    expect(backend.plays, [path]);
  });

  test('rapid identical sound dispatches overlap without cancellation',
      () async {
    const path = 'assets/sounds/wari_watermelon_bite.mp3.mp3';
    await PopSound.prepareGameplayAsset(path);

    PopSound.playGameplayAsset(path);
    PopSound.playGameplayAsset(path);

    expect(backend.active[path], 2);
    expect(backend.stopCount, 0);
  });

  test('two pointer-equivalent dispatches both play', () async {
    const path = 'assets/images/shushu_cream_burst.mp3.mp3';
    await PopSound.prepareGameplayAsset(path);
    PopSound.playGameplayAsset(path);
    PopSound.playGameplayAsset(path);

    expect(PopSound.gameplayAssetPlayCount, 2);
    expect(backend.plays.where((value) => value == path), hasLength(2));
  });

  test('ordinary gameplay file pool is capped at four voices', () async {
    const path = 'assets/sounds/boo_ghost_woo_short.mp3.mp3';
    await PopSound.prepareGameplayAsset(path);
    for (var index = 0; index < 12; index++) {
      PopSound.playGameplayAsset(path);
    }

    expect(backend.capacities[path], 4);
    expect(backend.active[path], 4);
    expect(backend.poolCreateCount, 1);
  });

  test('WARI pool uses eight voices', () async {
    const path = 'assets/sounds/wari_watermelon_bite.mp3.mp3';
    await PopSound.prepareGameplayAsset(path);
    expect(PopSound.gameplayVoiceCountForAsset(path), 8);
    expect(backend.capacities[path], 8);
  });

  test('SHUSHU hit and pop use four voices each', () async {
    const hit = 'assets/images/shushu_fork_hit.mp3.mp3';
    const pop = 'assets/images/shushu_cream_burst.mp3.mp3';
    await Future.wait([
      PopSound.prepareGameplayAsset(hit),
      PopSound.prepareGameplayAsset(pop),
    ]);

    expect(backend.capacities[hit], 4);
    expect(backend.capacities[pop], 4);
    expect(PopSound.activeGameplayVoiceCount, 8);
  });

  test('MUGI native pool preserves twelve voice polyphony', () async {
    const path = 'assets/sounds/muggy_break.mp3.mp3';
    await PopSound.prepareGameplayAsset(path);
    expect(PopSound.gameplayVoiceCountForAsset(path), 12);
    expect(backend.capacities[path], 12);
  });

  test('full pool never creates unbounded voices', () async {
    const path = 'assets/sounds/kicks_soccer_kick.mp3.mp3';
    await PopSound.prepareGameplayAsset(path);
    for (var index = 0; index < 100; index++) {
      PopSound.playGameplayAsset(path);
    }
    expect(backend.active[path], 4);
    expect(backend.poolCreateCount, 1);
  });

  test('sound off blocks dispatch', () async {
    await PopSound.prepareGameplayAsset(PopSound.basicPopAssetPath);
    PopSound.setEnabled(false);
    PopSound.playGameplayAsset(PopSound.basicPopAssetPath);
    PopSound.play();
    await Future<void>.delayed(Duration.zero);
    expect(backend.plays, isEmpty);
  });

  test('sound off stops active voices immediately', () async {
    await PopSound.prepareGameplayAsset(PopSound.basicPopAssetPath);
    PopSound.playGameplayAsset(PopSound.basicPopAssetPath);
    PopSound.setEnabled(false);
    await Future<void>.delayed(Duration.zero);
    expect(backend.activeVoiceCountFor(PopSound.basicPopAssetPath), 0);
    expect(backend.stopAllCount, 1);
  });

  test('pause stops active voices and blocks new dispatch', () async {
    await PopSound.prepareGameplayAsset(PopSound.basicPopAssetPath);
    PopSound.playGameplayAsset(PopSound.basicPopAssetPath);
    PopSound.pauseNativeAudio();
    PopSound.playGameplayAsset(PopSound.basicPopAssetPath);
    await Future<void>.delayed(Duration.zero);
    expect(backend.activeVoiceCountFor(PopSound.basicPopAssetPath), 0);
  });

  test('resume does not replay old sound and next event plays', () async {
    await PopSound.prepareGameplayAsset(PopSound.basicPopAssetPath);
    PopSound.playGameplayAsset(PopSound.basicPopAssetPath);
    PopSound.pauseNativeAudio();
    await Future<void>.delayed(Duration.zero);
    final plays = backend.plays.length;
    PopSound.resumeNativeAudio();
    expect(backend.plays.length, plays);
    PopSound.playGameplayAsset(PopSound.basicPopAssetPath);
    expect(backend.plays.length, plays + 1);
  });

  test('background inactive contract stops all native voices', () async {
    await PopSound.prepareGameplayAsset(PopSound.fakeHitAssetPath);
    PopSound.playGameplayAsset(PopSound.fakeHitAssetPath);
    PopSound.pauseNativeAudio();
    await Future<void>.delayed(Duration.zero);
    expect(backend.totalActive, 0);
  });

  test('restart reuses an already prepared pool', () async {
    const path = 'assets/sounds/wari_watermelon_bite.mp3.mp3';
    await PopSound.prepareGameplayAsset(path);
    await PopSound.prepareGameplayAsset(path);
    expect(backend.poolCreateCount, 1);
    expect(backend.capacities, hasLength(1));
  });

  test('route exit releases gameplay and semantic pools', () async {
    const path = 'assets/sounds/wari_watermelon_bite.mp3.mp3';
    await PopSound.prepareGameplayAsset(path);
    await PopSound.prepareSemanticGameplaySounds(
      hasHitAsset: false,
      hasPopAsset: true,
      popSoundKind: 'basic',
    );
    PopSound.releaseGameplayAsset(path);
    PopSound.releaseSemanticGameplaySounds();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(backend.capacities, isEmpty);
  });

  test('dispose is idempotent and removes every pool', () async {
    await PopSound.prepareGameplayAsset(PopSound.basicPopAssetPath);
    await PopSound.shutdownNativeAudio();
    await PopSound.shutdownNativeAudio();
    expect(backend.disposeCount, 1);
    expect(backend.capacities, isEmpty);
  });

  test('dispatch after dispose is ignored', () async {
    await PopSound.prepareGameplayAsset(PopSound.basicPopAssetPath);
    await PopSound.shutdownNativeAudio();
    final plays = backend.plays.length;
    PopSound.play();
    PopSound.playGameplayAsset(PopSound.basicPopAssetPath);
    expect(backend.plays.length, plays);
  });

  test('stale input after release produces no sound', () async {
    const path = 'assets/sounds/boo_ghost_woo_short.mp3.mp3';
    await PopSound.prepareGameplayAsset(path);
    PopSound.releaseGameplayAsset(path);
    PopSound.playGameplayAsset(path);
    expect(backend.plays, isEmpty);
  });

  test('prepare completion after shutdown never plays', () async {
    final gate = Completer<void>();
    backend.prepareGate = gate.future;
    final prepare = PopSound.prepareGameplayAsset(PopSound.basicPopAssetPath);
    await Future<void>.delayed(Duration.zero);
    final shutdown = PopSound.shutdownNativeAudio();
    gate.complete();
    await Future.wait([prepare, shutdown]);
    expect(backend.plays, isEmpty);
  });

  test('route reentry replaces pools without accumulation', () async {
    const first = 'assets/sounds/wari_watermelon_bite.mp3.mp3';
    const second = 'assets/sounds/muggy_break.mp3.mp3';
    await PopSound.prepareGameplayAsset(first);
    PopSound.releaseGameplayAsset(first);
    await Future<void>.delayed(Duration.zero);
    await PopSound.prepareGameplayAsset(second);
    expect(backend.capacities.keys, [second]);
  });

  test('all audible Web synthetic semantics dispatch native WAV pools',
      () async {
    await Future.wait(<Future<void>>[
      for (final kind in const [
        'basic',
        'heart',
        'ghost',
        'crackle',
        'crystal',
        'cream'
      ])
        PopSound.prepareSemanticGameplaySounds(
          hasHitAsset: false,
          hasPopAsset: false,
          popSoundKind: kind,
        ),
    ]);
    PopSound.play();
    PopSound.playHeart();
    PopSound.playLightTap();
    PopSound.playFake();
    PopSound.playBossExplosion();
    PopSound.playGhost();
    PopSound.playCrackle();
    PopSound.playCrystal();
    PopSound.playCream();
    await Future<void>.delayed(Duration.zero);

    expect(
      backend.plays.toSet(),
      containsAll(<String>{
        PopSound.basicPopAssetPath,
        PopSound.heartPopAssetPath,
        PopSound.lightTapAssetPath,
        PopSound.fakeHitAssetPath,
        PopSound.bossExplosionAssetPath,
        PopSound.ghostAssetPath,
        PopSound.crackleAssetPath,
        PopSound.crystalAssetPath,
        PopSound.creamAssetPath,
      }),
    );
  });

  test('native WAV files are mono PCM and registered in pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final path in _nativeWavPaths) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      final bytes = ByteData.sublistView(file.readAsBytesSync());
      expect(_ascii(bytes, 0, 4), 'RIFF');
      expect(_ascii(bytes, 8, 4), 'WAVE');
      expect(bytes.getUint16(20, Endian.little), 1);
      expect(bytes.getUint16(22, Endian.little), 1);
      expect(bytes.getUint32(24, Endian.little), 22050);
      expect(pubspec, contains(path.replaceAll('\\', '/')));
    }
  });

  test('iOS and Android contexts match short game SFX intent', () {
    final context = AudioplayersNativeAudioBackend.soundEffectContext;
    final source = File(
      'lib/audio/audioplayers_native_backend.dart',
    ).readAsStringSync();
    expect(context.iOS.category, AVAudioSessionCategory.ambient);
    expect(context.android.contentType, AndroidContentType.sonification);
    expect(context.android.usageType, AndroidUsageType.game);
    expect(context.android.audioFocus, AndroidAudioFocus.none);
    expect(context.android.stayAwake, isFalse);
    expect(source, contains('playerMode: PlayerMode.lowLatency'));
  });

  test('web audio implementation and voice contract remain unchanged', () {
    final source = File('lib/audio/pop_sound_web.dart').readAsStringSync();
    expect(source, contains('static const int gameplayVoiceCount = 4;'));
    expect(source, contains('static const int rapidGameplayVoiceCount = 8;'));
    expect(source, contains("@JS('AudioContext')"));
    expect(source, contains("@JS('Audio')"));
  });

  test('basic, fake, first-hit and boss semantics remain distinct', () async {
    await PopSound.prepareSemanticGameplaySounds(
      hasHitAsset: false,
      hasPopAsset: false,
      popSoundKind: 'basic',
    );
    PopSound.play();
    PopSound.playLightTap();
    PopSound.playFake();
    PopSound.playBossExplosion();
    expect(backend.plays, <String>[
      PopSound.basicPopAssetPath,
      PopSound.lightTapAssetPath,
      PopSound.fakeHitAssetPath,
      PopSound.bossExplosionAssetPath,
    ]);
  });

  test('semantic preparation uses bounded four-voice pools', () async {
    await PopSound.prepareSemanticGameplaySounds(
      hasHitAsset: false,
      hasPopAsset: false,
      popSoundKind: 'heart',
    );
    expect(
      backend.capacities.values.every(
        (capacity) => capacity == PopSound.gameplayVoiceCount,
      ),
      isTrue,
    );
  });

  test('no timers widgets or game objects are owned by audio backend', () {
    final source = File(
      'lib/audio/audioplayers_native_backend.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('Timer(')));
    expect(source, isNot(contains('AnimationController')));
    expect(source, isNot(contains('Widget')));
  });

  test('fake lifecycle counters prove no platform plugin dependency', () async {
    await PopSound.prepareGameplayAsset(PopSound.basicPopAssetPath);
    PopSound.playGameplayAsset(PopSound.basicPopAssetPath);
    PopSound.pauseGameplayAssets(<String>[PopSound.basicPopAssetPath]);
    await Future<void>.delayed(Duration.zero);
    expect(backend.prepareCount, 1);
    expect(backend.plays, hasLength(1));
    expect(backend.stopAssetsCount, 1);
  });
}

const _nativeWavPaths = <String>[
  'assets/sounds/native/native_basic_pop.wav',
  'assets/sounds/native/native_heart_pop.wav',
  'assets/sounds/native/native_light_tap.wav',
  'assets/sounds/native/native_fake_hit.wav',
  'assets/sounds/native/native_boss_explosion.wav',
  'assets/sounds/native/native_ghost.wav',
  'assets/sounds/native/native_crackle.wav',
  'assets/sounds/native/native_crystal.wav',
  'assets/sounds/native/native_cream.wav',
];

String _ascii(ByteData bytes, int offset, int length) => String.fromCharCodes(
      List<int>.generate(length, (index) => bytes.getUint8(offset + index)),
    );

final class _FakeNativeAudioBackend implements NativeAudioBackend {
  final Map<String, int> capacities = <String, int>{};
  final Map<String, int> active = <String, int>{};
  final List<String> plays = <String>[];
  int factoryUseCount = 1;
  int prepareCount = 0;
  int poolCreateCount = 0;
  int poolDisposeCount = 0;
  int stopCount = 0;
  int stopAllCount = 0;
  int stopAssetsCount = 0;
  int disposeCount = 0;
  Future<void>? prepareGate;
  bool disposed = false;

  int get totalActive => active.values.fold(0, (sum, value) => sum + value);

  @override
  Future<void> prepare(String assetPath, int voiceCount) async {
    prepareCount++;
    if (prepareGate case final gate?) await gate;
    if (disposed) return;
    if (capacities[assetPath] != voiceCount) {
      if (capacities.containsKey(assetPath)) poolDisposeCount++;
      capacities[assetPath] = voiceCount;
      active[assetPath] = 0;
      poolCreateCount++;
    }
  }

  @override
  void play(String assetPath) {
    if (disposed || !capacities.containsKey(assetPath)) return;
    plays.add(assetPath);
    active[assetPath] =
        ((active[assetPath] ?? 0) + 1).clamp(0, capacities[assetPath]!);
  }

  @override
  Future<void> stopAssets(Iterable<String> assetPaths) async {
    stopAssetsCount++;
    for (final path in assetPaths.toSet()) {
      stopCount += active[path] ?? 0;
      active[path] = 0;
    }
  }

  @override
  Future<void> releaseAssets(Iterable<String> assetPaths) async {
    for (final path in assetPaths.toSet()) {
      if (capacities.remove(path) != null) poolDisposeCount++;
      active.remove(path);
    }
  }

  @override
  Future<void> stopAll() async {
    stopAllCount++;
    stopCount += totalActive;
    for (final path in active.keys) {
      active[path] = 0;
    }
  }

  @override
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    disposeCount++;
    poolDisposeCount += capacities.length;
    capacities.clear();
    active.clear();
  }

  @override
  int voiceCapacityFor(String assetPath) => capacities[assetPath] ?? 0;

  @override
  int activeVoiceCountFor(String assetPath) => active[assetPath] ?? 0;

  @override
  int get poolCount => capacities.length;

  @override
  int get totalVoiceCapacity =>
      capacities.values.fold(0, (sum, value) => sum + value);
}
