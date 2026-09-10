import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

abstract interface class GameBgmBackend {
  Future<void> startLoop(String assetPath, double volume);

  Future<void> setVolume(double volume);

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
  Future<void> setVolume(double volume) => _player.setVolume(volume);

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
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

enum _GameBgmTrack { home, gameplay }

/// Owns one looping music player and switches it only at gameplay boundaries.
abstract final class GameBgm {
  static const String homeAssetPath = 'assets/sounds/bouncing_notes.mp3';
  static const String gameplayAssetPath = 'assets/sounds/arcade_bounce.mp3';
  static const double homeVolume = 0.12;
  static const double gameplayVolume = 0.16;
  static const Duration fadeDuration = Duration(milliseconds: 400);
  static const int _fadeSteps = 5;

  static GameBgmBackend? _backend;
  static Future<void> _operations = Future<void>.value();
  static bool _soundEnabled = true;
  static _GameBgmTrack? _desiredTrack;
  static _GameBgmTrack? _loadedTrack;
  static bool _gameplayPaused = false;
  static bool _lifecyclePaused = false;
  static bool _playing = false;
  static double _currentVolume = 0;
  static Duration _fadeStepDuration =
      Duration(milliseconds: fadeDuration.inMilliseconds ~/ _fadeSteps);

  static Future<void> startHome() {
    _desiredTrack = _GameBgmTrack.home;
    _gameplayPaused = false;
    return _scheduleSync();
  }

  static Future<void> startGameplay() {
    _desiredTrack = _GameBgmTrack.gameplay;
    _gameplayPaused = false;
    return _scheduleSync();
  }

  static Future<void> pauseGameplay() {
    if (_desiredTrack != _GameBgmTrack.gameplay) return Future<void>.value();
    _gameplayPaused = true;
    return _scheduleSync();
  }

  static Future<void> resumeGameplay() {
    if (_desiredTrack != _GameBgmTrack.gameplay) return Future<void>.value();
    _gameplayPaused = false;
    return _scheduleSync();
  }

  static Future<void> stopGameplay() {
    if (_desiredTrack != _GameBgmTrack.gameplay) return Future<void>.value();
    _desiredTrack = null;
    _gameplayPaused = false;
    return _scheduleSync();
  }

  static Future<void> pauseForLifecycle() {
    _lifecyclePaused = true;
    return _scheduleSync();
  }

  static Future<void> resumeFromLifecycle() {
    _lifecyclePaused = false;
    return _scheduleSync();
  }

  /// Retries a blocked web autoplay once the player provides a user gesture.
  static Future<void> handleUserInteraction() {
    if (!_soundEnabled ||
        _lifecyclePaused ||
        _desiredTrack == null ||
        _playing) {
      return Future<void>.value();
    }
    return _scheduleSync();
  }

  static Future<void> setEnabled(bool enabled) {
    _soundEnabled = enabled;
    return _scheduleSync();
  }

  static Future<void> shutdown() async {
    _desiredTrack = null;
    _gameplayPaused = false;
    _lifecyclePaused = false;
    await _scheduleSync();
    final backend = _backend;
    _backend = null;
    _loadedTrack = null;
    _playing = false;
    _currentVolume = 0;
    await backend?.dispose();
  }

  static Future<void> _scheduleSync() {
    _operations = _operations.then((_) async {
      try {
        await _synchronize();
      } catch (_) {
        _loadedTrack = null;
        _playing = false;
      }
    });
    return _operations;
  }

  static Future<void> _synchronize() async {
    final desiredTrack = _desiredTrack;
    if (desiredTrack == null) {
      if (_loadedTrack != null) await _fadeOutAndStop();
      _loadedTrack = null;
      _playing = false;
      return;
    }

    final shouldPlay = _soundEnabled &&
        !_lifecyclePaused &&
        (desiredTrack != _GameBgmTrack.gameplay || !_gameplayPaused);

    if (_loadedTrack != null && _loadedTrack != desiredTrack) {
      await _fadeOutAndStop();
      _loadedTrack = null;
      _playing = false;
    }

    if (!shouldPlay) {
      if (_playing) {
        await _fadeTo(0);
        await _player.pause();
      }
      _playing = false;
      return;
    }

    if (_loadedTrack == null) {
      _currentVolume = 0;
      await _player.startLoop(_assetPathFor(desiredTrack), 0);
      _loadedTrack = desiredTrack;
      _playing = true;
      await _fadeTo(_volumeFor(desiredTrack));
      return;
    }

    if (!_playing) {
      _currentVolume = 0;
      await _player.setVolume(0);
      await _player.resume();
      _playing = true;
      await _fadeTo(_volumeFor(desiredTrack));
    }
  }

  static Future<void> _fadeOutAndStop() async {
    if (_playing) await _fadeTo(0);
    await _player.stop();
    _currentVolume = 0;
  }

  static Future<void> _fadeTo(double target) async {
    final start = _currentVolume;
    if (start == target) return;
    for (var step = 1; step <= _fadeSteps; step++) {
      if (_fadeStepDuration > Duration.zero) {
        await Future<void>.delayed(_fadeStepDuration);
      }
      final next = start + (target - start) * step / _fadeSteps;
      await _player.setVolume(next);
      _currentVolume = next;
    }
  }

  static GameBgmBackend get _player => _backend ??= _createBackend();

  static String _assetPathFor(_GameBgmTrack track) => switch (track) {
        _GameBgmTrack.home => homeAssetPath,
        _GameBgmTrack.gameplay => gameplayAssetPath,
      };

  static double _volumeFor(_GameBgmTrack track) => switch (track) {
        _GameBgmTrack.home => homeVolume,
        _GameBgmTrack.gameplay => gameplayVolume,
      };

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
    Duration fadeStepDuration = Duration.zero,
  }) async {
    await shutdown();
    _backend = backend;
    _soundEnabled = soundEnabled;
    _desiredTrack = null;
    _loadedTrack = null;
    _gameplayPaused = false;
    _lifecyclePaused = false;
    _playing = false;
    _currentVolume = 0;
    _fadeStepDuration = fadeStepDuration;
    _operations = Future<void>.value();
  }
}
