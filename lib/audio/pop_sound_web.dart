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

abstract final class PopSound {
  static _AudioContext? _context;
  static bool enabled = true;

  static void setEnabled(bool value) => enabled = value;

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

  static void resetDebug() {}
}
