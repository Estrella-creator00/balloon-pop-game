import 'dart:ui';

import 'package:flame/game.dart';

import 'game_session_state.dart';

/// Empty Flame root used to validate hosting and lifecycle before migration.
class PoppopGame extends FlameGame {
  PoppopGame(this.sessionState) {
    // Flame's default lifecycle policy treats `inactive` like `resumed`.
    // The preview page owns lifecycle decisions so inactive/background states
    // are always paused and a manual pause is preserved on foreground return.
    pauseWhenBackgrounded = false;
  }

  final GameSessionState sessionState;
  bool _shutdown = false;
  bool _hostWantsRunning = true;

  bool get isShutdown => _shutdown;

  @override
  Color backgroundColor() => const Color(0xFF14243A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (_shutdown) return;
    if (_hostWantsRunning) {
      sessionState.start();
    } else {
      sessionState.pause();
    }
  }

  @override
  void update(double dt) {
    if (_shutdown || !sessionState.isRunning) return;
    super.update(dt);
    sessionState.recordUpdate(dt);
  }

  void pausePreview() {
    if (_shutdown) return;
    _hostWantsRunning = false;
    pauseEngine();
    sessionState.pause();
  }

  void resumePreview() {
    if (_shutdown) return;
    _hostWantsRunning = true;
    resumeEngine();
    sessionState.start();
  }

  void shutdown() {
    if (_shutdown) return;
    _shutdown = true;
    _hostWantsRunning = false;
    pauseEngine();
    sessionState.pause();
  }

  @override
  void onDispose() {
    shutdown();
    super.onDispose();
  }
}
