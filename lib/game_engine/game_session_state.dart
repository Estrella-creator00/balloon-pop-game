import 'package:flutter/foundation.dart';

enum GameSessionPhase { ready, running, paused, disposed }

/// Minimal shared session state for the incremental Flame migration.
///
/// It deliberately contains no gameplay rules. Later phases can connect the
/// existing score, timer, balloon, and phase models to this single view.
class GameSessionState extends ChangeNotifier {
  GameSessionPhase _phase = GameSessionPhase.ready;
  int _updateCount = 0;
  final int _score = 0;
  final int _remainingBalloons = 0;
  Duration _elapsed = Duration.zero;
  bool _disposed = false;

  GameSessionPhase get phase => _phase;
  int get updateCount => _updateCount;
  int get score => _score;
  int get remainingBalloons => _remainingBalloons;
  Duration get elapsed => _elapsed;
  bool get isRunning => _phase == GameSessionPhase.running;
  bool get isDisposed => _disposed;

  void start() => _setPhase(GameSessionPhase.running);

  void pause() => _setPhase(GameSessionPhase.paused);

  void recordUpdate(double deltaSeconds) {
    // GameWidget performs an update(0) while completing its build. It is a
    // loader synchronization step, not a game-loop frame, and notifying from
    // there would dirty the Flutter HUD during layout.
    if (_disposed || !isRunning || deltaSeconds <= 0) return;
    _updateCount++;
    _elapsed += Duration(
      microseconds: (deltaSeconds * Duration.microsecondsPerSecond).round(),
    );
    notifyListeners();
  }

  void _setPhase(GameSessionPhase nextPhase) {
    if (_disposed || _phase == nextPhase) return;
    _phase = nextPhase;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _phase = GameSessionPhase.disposed;
    super.dispose();
  }
}
