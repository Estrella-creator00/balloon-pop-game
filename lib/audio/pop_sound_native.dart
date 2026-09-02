import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'audioplayers_native_backend.dart';
import 'native_audio_backend.dart';

abstract final class PopSound {
  static const int gameplayVoiceCount = 4;
  static const int rapidGameplayVoiceCount = 8;
  static const int mugiGameplayVoiceCount = 12;
  static const uiClickAssetPath = 'assets/sounds/ui_click.mp3.mp3';
  static const bossAppearAssetPath = 'assets/sounds/boss_appear.mp3.mp3';
  static const bossClearAssetPath = 'assets/sounds/boss_clear.mp3.mp3';
  static const shopPurchaseAssetPath = 'assets/sounds/shop_purchase.mp3.mp3';
  static const shopEquipAssetPath = 'assets/sounds/shop_equip.mp3.mp3';
  static const basicPopAssetPath = 'assets/sounds/native/native_basic_pop.wav';
  static const heartPopAssetPath = 'assets/sounds/native/native_heart_pop.wav';
  static const lightTapAssetPath = 'assets/sounds/native/native_light_tap.wav';
  static const fakeHitAssetPath = 'assets/sounds/native/native_fake_hit.wav';
  static const bossExplosionAssetPath =
      'assets/sounds/native/native_boss_explosion.wav';
  static const ghostAssetPath = 'assets/sounds/native/native_ghost.wav';
  static const crackleAssetPath = 'assets/sounds/native/native_crackle.wav';
  static const crystalAssetPath = 'assets/sounds/native/native_crystal.wav';
  static const creamAssetPath = 'assets/sounds/native/native_cream.wav';

  static const _sharedAssetPaths = <String>{
    uiClickAssetPath,
    bossAppearAssetPath,
    bossClearAssetPath,
    shopPurchaseAssetPath,
    shopEquipAssetPath,
  };

  static NativeAudioBackend _backend = const NoopNativeAudioBackend();
  static NativeAudioBackendFactory _backendFactory = _createAudioplayersBackend;
  static Future<void>? _initializationFuture;
  static bool _initialized = false;
  static bool _lifecyclePaused = false;
  static bool _shutdown = false;
  static int _operationEpoch = 0;
  static Object? _lastNativeAudioError;
  static final Set<String> _preparedGameplayAssets = <String>{};
  static final Set<String> _preparedSemanticGameplayAssets = <String>{};
  static final Set<String> _readyGameplayAssets = <String>{};
  static final Map<String, Future<void>> _sharedPrepares =
      <String, Future<void>>{};
  static String? _transientAssetPath;
  static int _transientEpoch = 0;

  static bool enabled = true;
  static int basicPlayCount = 0;
  static int heartPlayCount = 0;
  static int bossExplosionPlayCount = 0;
  static int fakePlayCount = 0;
  static int themedPlayCount = 0;
  static int assetPlayCount = 0;
  static int polyphonicAssetPlayCount = 0;
  static int gameplayAssetPrepareCount = 0;
  static int gameplayAssetPlayCount = 0;
  static int gameplayAssetPauseCount = 0;
  static int gameplayPendingPrepareCount = 0;
  static String? lastAssetPath;
  static String? lastPreparedAssetPath;

  static Future<NativeAudioBackend> _createAudioplayersBackend() async =>
      AudioplayersNativeAudioBackend();

  static Future<void> initializeNativeAudio() =>
      _initializationFuture ??= _initializeOnce();

  static Future<void> _initializeOnce() async {
    try {
      final backend = await _backendFactory();
      if (_shutdown) {
        await backend.dispose();
        return;
      }
      _backend = backend;
      _initialized = true;
      _lastNativeAudioError = null;
    } catch (error, stackTrace) {
      _lastNativeAudioError = error;
      _backend = const NoopNativeAudioBackend();
      developer.log(
        'Native sound backend initialization failed.',
        name: 'poppop.audio',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static int get preparedGameplayAssetCount => _preparedGameplayAssets.length;

  static int get activeGameplayVoiceCount => _preparedGameplayAssets.fold(
        0,
        (sum, path) =>
            sum +
            (_backend is NoopNativeAudioBackend
                ? gameplayVoiceCountForAsset(path)
                : _backend.voiceCapacityFor(path)),
      );

  static int get playingGameplayVoiceCount => _preparedGameplayAssets.fold(
        0,
        (sum, path) => sum + _backend.activeVoiceCountFor(path),
      );

  static int get readyGameplayAssetCount => _readyGameplayAssets.length;

  static int get gameplayListenerCount => 0;

  static int gameplayVoiceCountForAsset(String assetPath) {
    if (assetPath.endsWith('muggy_break.mp3.mp3')) {
      return mugiGameplayVoiceCount;
    }
    if (assetPath.endsWith('wari_watermelon_bite.mp3.mp3')) {
      return rapidGameplayVoiceCount;
    }
    return gameplayVoiceCount;
  }

  static void setEnabled(bool value) {
    if (enabled == value) return;
    enabled = value;
    if (!value) {
      _operationEpoch++;
      unawaited(_guarded(_backend.stopAll()));
    }
  }

  static void preloadSharedAssets() {
    if (!_canDispatch) return;
    for (final path in _sharedAssetPaths) {
      _sharedPrepares.putIfAbsent(path, () => _prepareShared(path));
    }
  }

  static Future<void> _prepareShared(String assetPath) async {
    try {
      await _backend.prepare(assetPath, 1);
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
    }
  }

  static void playUiClick() => playAsset(uiClickAssetPath);
  static void playBossAppear() => playAsset(bossAppearAssetPath);
  static void playBossClear() => playAsset(bossClearAssetPath);
  static void playShopPurchase() => playAsset(shopPurchaseAssetPath);
  static void playShopEquip() => playAsset(shopEquipAssetPath);

  static void play() {
    if (!_canDispatch) return;
    basicPlayCount++;
    _playSemantic(basicPopAssetPath);
  }

  static void playHeart() {
    if (!_canDispatch) return;
    heartPlayCount++;
    _playSemantic(heartPopAssetPath);
  }

  static void playLightTap() {
    if (_canDispatch) _playSemantic(lightTapAssetPath);
  }

  static void playFake() {
    if (!_canDispatch) return;
    fakePlayCount++;
    _playSemantic(fakeHitAssetPath);
  }

  static void playBossExplosion() {
    if (!_canDispatch) return;
    bossExplosionPlayCount++;
    _playSemantic(bossExplosionAssetPath);
  }

  static void playGhost() {
    if (!_canDispatch) return;
    themedPlayCount++;
    _playSemantic(ghostAssetPath);
  }

  static void playCrackle() {
    if (!_canDispatch) return;
    themedPlayCount++;
    _playSemantic(crackleAssetPath);
  }

  static void playCrystal() {
    if (!_canDispatch) return;
    themedPlayCount++;
    _playSemantic(crystalAssetPath);
  }

  static void playCream() {
    if (!_canDispatch) return;
    themedPlayCount++;
    _playSemantic(creamAssetPath);
  }

  static void _playSemantic(String assetPath) {
    if (_backend.voiceCapacityFor(assetPath) > 0) {
      _backend.play(assetPath);
      return;
    }
    _playOnDemand(assetPath, gameplayVoiceCount);
  }

  static Future<void> prepareSemanticGameplaySounds({
    required bool hasHitAsset,
    required bool hasPopAsset,
    required String popSoundKind,
  }) async {
    if (!_canDispatch) return;
    final paths = <String>{fakeHitAssetPath, bossExplosionAssetPath};
    if (!hasHitAsset) {
      paths
        ..add(lightTapAssetPath)
        ..add(basicPopAssetPath);
    }
    if (!hasPopAsset) paths.add(_semanticPathForKind(popSoundKind));
    final epoch = _operationEpoch;
    gameplayPendingPrepareCount += paths.length;
    try {
      await Future.wait(paths.map(
        (path) => _backend.prepare(path, gameplayVoiceCount),
      ));
      if (!_canDispatch || epoch != _operationEpoch) {
        await _backend.releaseAssets(paths);
        return;
      }
      _preparedSemanticGameplayAssets.addAll(paths);
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
    } finally {
      gameplayPendingPrepareCount -= paths.length;
    }
  }

  static String _semanticPathForKind(String kind) => switch (kind) {
        'heart' => heartPopAssetPath,
        'ghost' => ghostAssetPath,
        'crackle' => crackleAssetPath,
        'crystal' => crystalAssetPath,
        'cream' => creamAssetPath,
        _ => basicPopAssetPath,
      };

  static void releaseSemanticGameplaySounds() {
    final paths = _preparedSemanticGameplayAssets.toSet();
    _preparedSemanticGameplayAssets.clear();
    unawaited(_guarded(_backend.releaseAssets(paths)));
  }

  // Production preloads only shared UI assets and the currently selected
  // gameplay profile. The catalog-wide legacy preload loop remains a no-op on
  // native so all eleven skins are not decoded together.
  static void preloadAsset(String assetPath) {}

  static Future<void> prepareGameplayAsset(String assetPath) async {
    if (!_canDispatch || _preparedGameplayAssets.contains(assetPath)) return;
    final epoch = _operationEpoch;
    gameplayPendingPrepareCount++;
    try {
      await _backend.prepare(
        assetPath,
        gameplayVoiceCountForAsset(assetPath),
      );
      if (!_canDispatch || epoch != _operationEpoch) {
        await _backend.releaseAssets(<String>[assetPath]);
        return;
      }
      _preparedGameplayAssets.add(assetPath);
      _readyGameplayAssets.add(assetPath);
      if (_transientAssetPath == assetPath) _transientAssetPath = null;
      gameplayAssetPrepareCount++;
      lastPreparedAssetPath = assetPath;
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
    } finally {
      gameplayPendingPrepareCount--;
    }
  }

  static void playGameplayAsset(String assetPath) {
    if (!_canDispatch || !_readyGameplayAssets.contains(assetPath)) return;
    gameplayAssetPlayCount++;
    lastAssetPath = assetPath;
    _backend.play(assetPath);
  }

  static void releaseGameplayAsset(String assetPath) {
    _preparedGameplayAssets.remove(assetPath);
    _readyGameplayAssets.remove(assetPath);
    if (_transientAssetPath == assetPath) _transientAssetPath = null;
    unawaited(_guarded(_backend.releaseAssets(<String>[assetPath])));
  }

  static void pauseGameplayAssets(Iterable<String> assetPaths) {
    final paths = assetPaths.toSet();
    if (paths.any(_preparedGameplayAssets.contains)) {
      gameplayAssetPauseCount++;
    }
    unawaited(_guarded(_backend.stopAssets(paths)));
  }

  static void releaseGameplayAssets(Iterable<String> assetPaths) {
    for (final assetPath in assetPaths.toSet()) {
      releaseGameplayAsset(assetPath);
    }
  }

  static void preloadPolyphonicAsset(
    String assetPath, {
    int voiceCount = 12,
  }) {}

  static void playAsset(String assetPath) {
    if (!_canDispatch) return;
    assetPlayCount++;
    lastAssetPath = assetPath;
    _playOnDemand(assetPath, 1);
  }

  static void playAssetPolyphonic(String assetPath) {
    if (!_canDispatch) return;
    polyphonicAssetPlayCount++;
    lastAssetPath = assetPath;
    _playOnDemand(assetPath, mugiGameplayVoiceCount);
  }

  static void _playOnDemand(String assetPath, int voiceCount) {
    if (_backend.voiceCapacityFor(assetPath) >= voiceCount) {
      _backend.play(assetPath);
      return;
    }
    final epoch = _operationEpoch;
    final transientEpoch = ++_transientEpoch;
    unawaited(_prepareTransientAndPlay(
      assetPath,
      voiceCount,
      epoch,
      transientEpoch,
    ));
  }

  static Future<void> _prepareTransientAndPlay(
    String assetPath,
    int voiceCount,
    int epoch,
    int transientEpoch,
  ) async {
    try {
      if (!_sharedAssetPaths.contains(assetPath)) {
        final previous = _transientAssetPath;
        if (previous != null &&
            previous != assetPath &&
            !_preparedGameplayAssets.contains(previous)) {
          await _backend.releaseAssets(<String>[previous]);
        }
        _transientAssetPath = assetPath;
      }
      await _backend.prepare(assetPath, voiceCount);
      if (!_canDispatch ||
          epoch != _operationEpoch ||
          (!_sharedAssetPaths.contains(assetPath) &&
              transientEpoch != _transientEpoch)) {
        if (!_preparedGameplayAssets.contains(assetPath) &&
            !_sharedAssetPaths.contains(assetPath)) {
          await _backend.releaseAssets(<String>[assetPath]);
        }
        return;
      }
      _backend.play(assetPath);
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
    }
  }

  static bool get _canDispatch =>
      enabled &&
      (_initialized || _backend is NoopNativeAudioBackend) &&
      !_lifecyclePaused &&
      !_shutdown;

  static void pauseNativeAudio() {
    _lifecyclePaused = true;
    _operationEpoch++;
    unawaited(_guarded(_backend.stopAll()));
  }

  static void resumeNativeAudio() {
    if (_shutdown) return;
    _lifecyclePaused = false;
  }

  static void stopActiveNativeAudio() {
    _operationEpoch++;
    unawaited(_guarded(_backend.stopAll()));
  }

  static Future<void> shutdownNativeAudio() async {
    if (_shutdown) return;
    _shutdown = true;
    _operationEpoch++;
    _transientEpoch++;
    _preparedGameplayAssets.clear();
    _preparedSemanticGameplayAssets.clear();
    _readyGameplayAssets.clear();
    _sharedPrepares.clear();
    _transientAssetPath = null;
    await _guarded(_backend.dispose());
    _backend = const NoopNativeAudioBackend();
    _initialized = false;
  }

  static Future<void> _guarded(Future<void> operation) async {
    try {
      await operation;
    } catch (error, stackTrace) {
      _recordError(error, stackTrace);
    }
  }

  static void _recordError(Object error, StackTrace stackTrace) {
    _lastNativeAudioError = error;
    developer.log(
      'Native sound operation failed.',
      name: 'poppop.audio',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void resetDebug() {
    final preparedPaths = <String>{
      ..._preparedGameplayAssets,
      ..._preparedSemanticGameplayAssets,
    };
    _preparedGameplayAssets.clear();
    _preparedSemanticGameplayAssets.clear();
    _readyGameplayAssets.clear();
    if (preparedPaths.isNotEmpty) {
      unawaited(_guarded(_backend.releaseAssets(preparedPaths)));
    }
    basicPlayCount = 0;
    heartPlayCount = 0;
    bossExplosionPlayCount = 0;
    fakePlayCount = 0;
    themedPlayCount = 0;
    assetPlayCount = 0;
    polyphonicAssetPlayCount = 0;
    gameplayAssetPrepareCount = 0;
    gameplayAssetPlayCount = 0;
    gameplayAssetPauseCount = 0;
    gameplayPendingPrepareCount = 0;
    lastAssetPath = null;
    lastPreparedAssetPath = null;
  }

  @visibleForTesting
  static Future<void> initializeForTesting(
    NativeAudioBackendFactory factory,
  ) async {
    await resetForTesting();
    _backendFactory = factory;
    await initializeNativeAudio();
  }

  @visibleForTesting
  static Future<void> resetForTesting() async {
    if (_initialized) await _guarded(_backend.dispose());
    _backend = const NoopNativeAudioBackend();
    _backendFactory = _createAudioplayersBackend;
    _initializationFuture = null;
    _initialized = false;
    _lifecyclePaused = false;
    _shutdown = false;
    _operationEpoch = 0;
    _lastNativeAudioError = null;
    _preparedGameplayAssets.clear();
    _preparedSemanticGameplayAssets.clear();
    _readyGameplayAssets.clear();
    _sharedPrepares.clear();
    _transientAssetPath = null;
    _transientEpoch = 0;
    enabled = true;
    resetDebug();
  }

  @visibleForTesting
  static int get nativePoolCountForTesting => _backend.poolCount;

  @visibleForTesting
  static int get nativeVoiceCapacityForTesting => _backend.totalVoiceCapacity;

  @visibleForTesting
  static Object? get lastNativeAudioErrorForTesting => _lastNativeAudioError;
}
