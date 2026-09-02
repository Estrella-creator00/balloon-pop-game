// AudioPool does not expose a public active-count/stop-all API. Reading its
// bounded player map is required to enforce a hard cap without adding a timer
// per sound; creation, playback, and disposal still use AudioPool APIs.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'native_audio_backend.dart';

final class AudioplayersNativeAudioBackend implements NativeAudioBackend {
  static final AudioContext soundEffectContext = AudioContext(
    android: const AudioContextAndroid(
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  final Map<String, _BoundedAudioPool> _pools = <String, _BoundedAudioPool>{};
  bool _disposed = false;

  @override
  Future<void> prepare(String assetPath, int voiceCount) async {
    if (_disposed || voiceCount <= 0) return;
    final existing = _pools[assetPath];
    if (existing != null && existing.voiceCount == voiceCount) return;
    if (existing != null) await existing.dispose();
    if (_disposed) return;
    final pool = await AudioPool.create(
      source: AssetSource(_assetSourcePath(assetPath)),
      minPlayers: voiceCount,
      maxPlayers: voiceCount,
      playerMode: PlayerMode.lowLatency,
      audioContext: soundEffectContext,
    );
    if (_disposed) {
      await pool.dispose();
      return;
    }
    _pools[assetPath] = _BoundedAudioPool(pool, voiceCount);
  }

  @override
  void play(String assetPath) {
    if (_disposed) return;
    _pools[assetPath]?.play();
  }

  @override
  Future<void> stopAssets(Iterable<String> assetPaths) async {
    await Future.wait(
      assetPaths.toSet().map((path) async => _pools[path]?.stopAll()),
    );
  }

  @override
  Future<void> releaseAssets(Iterable<String> assetPaths) async {
    final pools = <_BoundedAudioPool>[];
    for (final path in assetPaths.toSet()) {
      final pool = _pools.remove(path);
      if (pool != null) pools.add(pool);
    }
    await Future.wait(pools.map((pool) => pool.dispose()));
  }

  @override
  Future<void> stopAll() =>
      Future.wait(_pools.values.map((pool) => pool.stopAll()));

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final pools = _pools.values.toList(growable: false);
    _pools.clear();
    await Future.wait(pools.map((pool) => pool.dispose()));
  }

  @override
  int voiceCapacityFor(String assetPath) => _pools[assetPath]?.voiceCount ?? 0;

  @override
  int activeVoiceCountFor(String assetPath) =>
      _pools[assetPath]?.activeVoiceCount ?? 0;

  @override
  int get poolCount => _pools.length;

  @override
  int get totalVoiceCapacity =>
      _pools.values.fold(0, (sum, pool) => sum + pool.voiceCount);

  static String _assetSourcePath(String assetPath) =>
      assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;
}

final class _BoundedAudioPool {
  _BoundedAudioPool(this.pool, this.voiceCount);

  final AudioPool pool;
  final int voiceCount;
  final Map<String, StopFunction> _stopCallbacks = <String, StopFunction>{};
  Future<void> _startQueue = Future<void>.value();
  int _reservedStarts = 0;
  int _operationEpoch = 0;
  bool _disposed = false;

  int get activeVoiceCount => pool.currentPlayers.length;

  void play() {
    if (_disposed || activeVoiceCount + _reservedStarts >= voiceCount) return;
    _reservedStarts++;
    final epoch = _operationEpoch;
    _startQueue = _startQueue.then((_) async {
      try {
        if (_disposed || epoch != _operationEpoch) return;
        _removeCompletedCallbacks();
        final previousIds = pool.currentPlayers.keys.toSet();
        final stop = await pool.start();
        if (_disposed || epoch != _operationEpoch) {
          await stop();
          return;
        }
        final playerId = pool.currentPlayers.keys.firstWhere(
          (id) => !previousIds.contains(id),
          orElse: () => '',
        );
        if (playerId.isNotEmpty) _stopCallbacks[playerId] = stop;
      } catch (_) {
        // A native playback error must never affect input or game progress.
      } finally {
        _reservedStarts--;
      }
    });
  }

  void _removeCompletedCallbacks() {
    final activeIds = pool.currentPlayers.keys.toSet();
    _stopCallbacks.removeWhere((id, _) => !activeIds.contains(id));
  }

  Future<void> stopAll() async {
    if (_disposed) return;
    _operationEpoch++;
    await _startQueue;
    final stops = _stopCallbacks.values.toList(growable: false);
    _stopCallbacks.clear();
    await Future.wait(stops.map((stop) => stop()));
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _operationEpoch++;
    await _startQueue;
    _stopCallbacks.clear();
    await pool.dispose();
  }
}
