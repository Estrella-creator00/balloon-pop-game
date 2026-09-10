import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract interface class GameBgmBackend {
  Future<void> startLoop(String assetPath, double volume);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> dispose();
}

final class AudioplayersGameBgmBackend implements GameBgmBackend {
  final AudioPlayer _player = AudioPlayer();

  static final AudioContext _audioContext = AudioContext(
    android: const AudioContextAndroid(
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  @override
  Future<void> startLoop(String assetPath, double volume) async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(
      AssetSource(_assetSourcePath(assetPath)),
      volume: volume,
      mode: PlayerMode.mediaPlayer,
      ctx: _audioContext,
    );
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();

  static String _assetSourcePath(String assetPath) =>
      assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;
}

final class _NoopGameBgmBackend implements GameBgmBackend {
  @override
  Future<void> startLoop(String assetPath, double volume) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// Owns the single looping gameplay music player across stage transitions.
abstract final class GameBgm {
  static const String assetPath = 'assets/sounds/bouncy_loop.mp3';
  static const double volume = 0.16;

  static GameBgmBackend? _backend;
  static Future<void> _operations = Future<void>.value();
  static bool _soundEnabled = true;
  static bool _gameplayActive = false;
  static bool _gameplayPaused = false;
  static bool _started = false;
  static bool _playing = false;

  static Future<void> startGameplay() {
    _gameplayActive = true;
    _gameplayPaused = false;
    return _scheduleSync();
  }

  static Future<void> pauseGameplay() {
    if (!_gameplayActive) return Future<void>.value();
    _gameplayPaused = true;
    return _scheduleSync();
  }

  static Future<void> resumeGameplay() {
    if (!_gameplayActive) return Future<void>.value();
    _gameplayPaused = false;
    return _scheduleSync();
  }

  static Future<void> stopGameplay() {
    _gameplayActive = false;
    _gameplayPaused = false;
    return _scheduleSync();
  }

  static Future<void> setEnabled(bool enabled) {
    _soundEnabled = enabled;
    return _scheduleSync();
  }

  static Future<void> shutdown() async {
    _gameplayActive = false;
    _gameplayPaused = false;
    await _scheduleSync();
    final backend = _backend;
    _backend = null;
    _started = false;
    _playing = false;
    await backend?.dispose();
  }

  static Future<void> _scheduleSync() {
    _operations = _operations.then((_) async {
      try {
        await _synchronize();
      } catch (_) {
        _started = false;
        _playing = false;
      }
    });
    return _operations;
  }

  static Future<void> _synchronize() async {
    if (!_gameplayActive) {
      if (_started) await _player.stop();
      _started = false;
      _playing = false;
      return;
    }

    final shouldPlay = _soundEnabled && !_gameplayPaused;
    if (!shouldPlay) {
      if (_playing) await _player.pause();
      _playing = false;
      return;
    }

    if (!_started) {
      await _player.startLoop(assetPath, volume);
      _started = true;
      _playing = true;
      return;
    }

    if (!_playing) {
      await _player.resume();
      _playing = true;
    }
  }

  static GameBgmBackend get _player => _backend ??= _createBackend();

  static GameBgmBackend _createBackend() {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return AudioplayersGameBgmBackend();
    }
    return _NoopGameBgmBackend();
  }

  @visibleForTesting
  static Future<void> debugReset({
    required GameBgmBackend backend,
    bool soundEnabled = true,
  }) async {
    await shutdown();
    _backend = backend;
    _soundEnabled = soundEnabled;
    _gameplayActive = false;
    _gameplayPaused = false;
    _started = false;
    _playing = false;
    _operations = Future<void>.value();
  }
}
