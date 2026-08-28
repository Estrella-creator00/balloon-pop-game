import 'dart:async';
import 'dart:js_interop';

@JS('AudioContext')
extension type _AudioContext._(JSObject _) implements JSObject {
  external factory _AudioContext();

  external JSPromise<JSAny?> resume();
  external _OscillatorNode createOscillator();
  external _GainNode createGain();
  external num get currentTime;
  external JSAny? get destination;
}

extension type _AudioNode._(JSObject _) implements JSObject {
  external JSAny? connect(JSAny? destination);
}

extension type _OscillatorNode._(JSObject _) implements _AudioNode, JSObject {
  external _AudioParam get frequency;
  external set type(String value);
  external void start([num when]);
  external void stop([num when]);
}

extension type _GainNode._(JSObject _) implements _AudioNode, JSObject {
  external _AudioParam get gain;
}

extension type _AudioParam._(JSObject _) implements JSObject {
  external void setValueAtTime(num value, num startTime);
  external void exponentialRampToValueAtTime(num value, num endTime);
}

@JS('Audio')
extension type _AudioElement._(JSObject _) implements JSObject {
  external factory _AudioElement([String source]);

  external JSPromise<JSAny?> play();
  external void load();
  external void pause();
  external set currentTime(num value);
  external set preload(String value);
  external int get readyState;
}

abstract final class PopSound {
  static const int gameplayVoiceCount = 8;
  static const uiClickAssetPath = 'assets/sounds/ui_click.mp3.mp3';
  static const bossAppearAssetPath = 'assets/sounds/boss_appear.mp3.mp3';
  static const bossClearAssetPath = 'assets/sounds/boss_clear.mp3.mp3';
  static const shopPurchaseAssetPath = 'assets/sounds/shop_purchase.mp3.mp3';
  static const shopEquipAssetPath = 'assets/sounds/shop_equip.mp3.mp3';

  static _AudioContext? _context;
  static final Map<String, _AudioElement> _assetPlayers = {};
  static final Map<String, List<_AudioElement>> _polyphonicAssetPlayers = {};
  static final Map<String, int> _polyphonicVoiceIndexes = {};
  static final Map<String, List<_AudioElement>> _gameplayAssetPlayers = {};
  static final Map<String, int> _gameplayVoiceIndexes = {};
  static bool enabled = true;

  static int get preparedGameplayAssetCount => _gameplayAssetPlayers.length;
  static int get activeGameplayVoiceCount => _gameplayAssetPlayers.values
      .fold(0, (total, voices) => total + voices.length);

  static void setEnabled(bool value) => enabled = value;

  static void preloadSharedAssets() {
    for (final path in const <String>[
      uiClickAssetPath,
      bossAppearAssetPath,
      bossClearAssetPath,
      shopPurchaseAssetPath,
      shopEquipAssetPath,
    ]) {
      preloadAsset(path);
    }
  }

  static void playUiClick() => playAsset(uiClickAssetPath);
  static void playBossAppear() => playAsset(bossAppearAssetPath);
  static void playBossClear() => playAsset(bossClearAssetPath);
  static void playShopPurchase() => playAsset(shopPurchaseAssetPath);
  static void playShopEquip() => playAsset(shopEquipAssetPath);

  static void play() {
    if (!enabled) return;
    // This method is called directly inside the balloon's user-click handler.
    // Creating/resuming the context here also unlocks audio on the first click.
    try {
      final context = _context ??= _AudioContext();
      context.resume();

      final now = context.currentTime;
      final oscillator = context.createOscillator();
      final gain = context.createGain();

      oscillator
        ..type = 'sine'
        ..frequency.setValueAtTime(520, now)
        ..frequency.exponentialRampToValueAtTime(110, now + 0.09)
        ..connect(gain);
      gain
        ..gain.setValueAtTime(0.32, now)
        ..gain.exponentialRampToValueAtTime(0.001, now + 0.1)
        ..connect(context.destination);

      oscillator
        ..start(now)
        ..stop(now + 0.105);
    } catch (_) {
      // Audio support must never affect scoring or stage progress.
    }
  }

  /// Default heart skin sound: a soft 0.23 second pop with a small chime.
  /// Keeping this entry point separate lets a future sound pack replace it.
  static void playHeart() {
    if (!enabled) return;
    try {
      final context = _context ??= _AudioContext();
      context.resume();
      final now = context.currentTime;

      final pop = context.createOscillator();
      final popGain = context.createGain();
      pop
        ..type = 'sine'
        ..frequency.setValueAtTime(390, now)
        ..frequency.exponentialRampToValueAtTime(145, now + 0.18)
        ..connect(popGain);
      popGain
        ..gain.setValueAtTime(0.22, now)
        ..gain.exponentialRampToValueAtTime(0.001, now + 0.2)
        ..connect(context.destination);
      pop
        ..start(now)
        ..stop(now + 0.205);

      final chime = context.createOscillator();
      final chimeGain = context.createGain();
      final chimeStart = now + 0.095;
      chime
        ..type = 'sine'
        ..frequency.setValueAtTime(900, chimeStart)
        ..frequency.exponentialRampToValueAtTime(1180, now + 0.21)
        ..connect(chimeGain);
      chimeGain
        ..gain.setValueAtTime(0.07, chimeStart)
        ..gain.exponentialRampToValueAtTime(0.001, now + 0.23)
        ..connect(context.destination);
      chime
        ..start(chimeStart)
        ..stop(now + 0.235);
    } catch (_) {
      // Audio support must never affect balloon removal or stage progress.
    }
  }

  static void playLightTap() {
    if (!enabled) return;
    try {
      final context = _context ??= _AudioContext();
      context.resume();
      final now = context.currentTime;
      final oscillator = context.createOscillator();
      final gain = context.createGain();
      oscillator
        ..type = 'sine'
        ..frequency.setValueAtTime(760, now)
        ..frequency.exponentialRampToValueAtTime(520, now + 0.045)
        ..connect(gain);
      gain
        ..gain.setValueAtTime(0.16, now)
        ..gain.exponentialRampToValueAtTime(0.001, now + 0.055)
        ..connect(context.destination);
      oscillator
        ..start(now)
        ..stop(now + 0.06);
    } catch (_) {
      // A missing audio device must not affect balloon health.
    }
  }

  /// Short, soft failure cue for a fake balloon. It is synthesized through
  /// the existing Web Audio context and follows the shared sound preference.
  static void playFake() {
    if (!enabled) return;
    try {
      final context = _context ??= _AudioContext();
      context.resume();
      final now = context.currentTime;
      final oscillator = context.createOscillator();
      final gain = context.createGain();
      oscillator
        ..type = 'triangle'
        ..frequency.setValueAtTime(240, now)
        ..frequency.exponentialRampToValueAtTime(105, now + 0.13)
        ..connect(gain);
      gain
        ..gain.setValueAtTime(0.13, now)
        ..gain.exponentialRampToValueAtTime(0.001, now + 0.15)
        ..connect(context.destination);
      oscillator
        ..start(now)
        ..stop(now + 0.155);
    } catch (_) {
      // Unsupported audio must never affect the time penalty or removal.
    }
  }

  static void playBossExplosion() {
    if (!enabled) return;
    try {
      final context = _context ??= _AudioContext();
      context.resume();
      final now = context.currentTime;

      for (var i = 0; i < 3; i++) {
        final oscillator = context.createOscillator();
        final gain = context.createGain();
        final start = now + i * 0.025;
        oscillator
          ..type = i == 0 ? 'square' : 'sawtooth'
          ..frequency.setValueAtTime(150 - i * 25, start)
          ..frequency.exponentialRampToValueAtTime(38, start + 0.38)
          ..connect(gain);
        gain
          ..gain.setValueAtTime(0.18, start)
          ..gain.exponentialRampToValueAtTime(0.001, start + 0.42)
          ..connect(context.destination);
        oscillator
          ..start(start)
          ..stop(start + 0.43);
      }
    } catch (_) {
      // Sound failure must never block the boss-clear flow.
    }
  }

  static void playGhost() => _playTone('sine', 330, 92, 0.22, 0.16);

  static void playCrackle() {
    _playTone('square', 880, 235, 0.085, 0.11);
    _playTone('triangle', 1240, 390, 0.055, 0.065);
  }

  static void playCrystal() {
    _playTone('triangle', 1380, 510, 0.15, 0.14);
    _playTone('sine', 1760, 920, 0.19, 0.07);
  }

  static void playCream() {
    _playTone('sine', 270, 115, 0.12, 0.16);
    _playTone('triangle', 520, 310, 0.09, 0.07);
  }

  static void preloadAsset(String assetPath) {
    try {
      _assetPlayers.putIfAbsent(assetPath, () {
        final player = _AudioElement('assets/$assetPath');
        player.preload = 'auto';
        return player;
      });
    } catch (_) {
      // Asset preload support must never affect startup.
    }
  }

  /// Requests media loading while the integration game is entered from a
  /// user gesture, so the first accepted hit only resets and plays the player.
  static Future<void> prepareGameplayAsset(String assetPath) async {
    List<_AudioElement>? voices;
    try {
      final context = _context ??= _AudioContext();
      _ignorePlayback(context.resume());
      voices = _gameplayAssetPlayers.putIfAbsent(
        assetPath,
        () => List<_AudioElement>.generate(gameplayVoiceCount, (_) {
          final player = _AudioElement('assets/$assetPath');
          player.preload = 'auto';
          return player;
        }, growable: false),
      );
      for (final voice in voices) {
        if (voice.readyState < 2) voice.load();
      }
    } catch (_) {
      // Media readiness must never block gameplay navigation.
    }
    if (voices == null) return;
    for (var attempt = 0; attempt < 20; attempt++) {
      if (voices.every((voice) => voice.readyState >= 2)) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  static void playGameplayAsset(String assetPath) {
    if (!enabled) return;
    try {
      final voices = _gameplayAssetPlayers[assetPath];
      if (voices == null || voices.isEmpty) return;
      final index = _gameplayVoiceIndexes[assetPath] ?? 0;
      final player = voices[index % voices.length];
      _gameplayVoiceIndexes[assetPath] = (index + 1) % voices.length;
      player.currentTime = 0;
      _ignorePlayback(player.play());
    } catch (_) {
      // A rejected Safari play promise must not affect gameplay.
    }
  }

  static void releaseGameplayAsset(String assetPath) {
    final voices = _gameplayAssetPlayers.remove(assetPath);
    _gameplayVoiceIndexes.remove(assetPath);
    if (voices == null) return;
    for (final voice in voices) {
      try {
        voice
          ..pause()
          ..currentTime = 0;
      } catch (_) {
        // Teardown remains best-effort on browsers without media support.
      }
    }
  }

  static void pauseGameplayAssets(Iterable<String> assetPaths) {
    for (final assetPath in assetPaths.toSet()) {
      final voices = _gameplayAssetPlayers[assetPath];
      if (voices == null) continue;
      for (final voice in voices) {
        try {
          voice.pause();
        } catch (_) {
          // Pausing is best-effort across browser media implementations.
        }
      }
    }
  }

  static void releaseGameplayAssets(Iterable<String> assetPaths) {
    for (final assetPath in assetPaths.toSet()) {
      releaseGameplayAsset(assetPath);
    }
  }

  static void preloadPolyphonicAsset(
    String assetPath, {
    int voiceCount = 12,
  }) {
    try {
      _polyphonicAssetPlayers.putIfAbsent(
        assetPath,
        () => List<_AudioElement>.generate(voiceCount, (_) {
          final player = _AudioElement('assets/$assetPath');
          player.preload = 'auto';
          return player;
        }, growable: false),
      );
    } catch (_) {
      // Asset preload support must never affect startup.
    }
  }

  static void playAsset(String assetPath) {
    if (!enabled) return;
    try {
      preloadAsset(assetPath);
      final player = _assetPlayers[assetPath];
      if (player == null) return;
      player
        ..pause()
        ..currentTime = 0;
      _ignorePlayback(player.play());
    } catch (_) {
      // Missing browser audio support must never affect gameplay.
    }
  }

  static void playAssetPolyphonic(String assetPath) {
    if (!enabled) return;
    try {
      preloadPolyphonicAsset(assetPath);
      final voices = _polyphonicAssetPlayers[assetPath];
      if (voices == null || voices.isEmpty) return;
      final index = _polyphonicVoiceIndexes[assetPath] ?? 0;
      final player = voices[index % voices.length];
      _polyphonicVoiceIndexes[assetPath] = (index + 1) % voices.length;
      player.currentTime = 0;
      _ignorePlayback(player.play());
    } catch (_) {
      // Missing browser audio support must never affect gameplay.
    }
  }

  static void _playTone(
    String type,
    double startFrequency,
    double endFrequency,
    double duration,
    double volume,
  ) {
    if (!enabled) return;
    try {
      final context = _context ??= _AudioContext();
      context.resume();
      final now = context.currentTime;
      final oscillator = context.createOscillator();
      final gain = context.createGain();
      oscillator
        ..type = type
        ..frequency.setValueAtTime(startFrequency, now)
        ..frequency.exponentialRampToValueAtTime(endFrequency, now + duration)
        ..connect(gain);
      gain
        ..gain.setValueAtTime(volume, now)
        ..gain.exponentialRampToValueAtTime(0.001, now + duration)
        ..connect(context.destination);
      oscillator
        ..start(now)
        ..stop(now + duration + 0.01);
    } catch (_) {
      // Unsupported audio must never alter gameplay.
    }
  }

  static void _ignorePlayback(JSPromise<JSAny?> promise) {
    unawaited(promise.toDart.then<void>((_) {}, onError: (_, __) {}));
  }

  static void resetDebug() {}
}
