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

  static void play() {
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

  static void playLightTap() {
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

  static void playBossExplosion() {
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
}
