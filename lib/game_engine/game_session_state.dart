import 'dart:math';

import 'package:flutter/foundation.dart';

import 'session/game_session_snapshot.dart';

enum BalloonPopResult { ignored, popped, stageCleared }

/// Single session state for the Stage 1 Flame vertical slice.
///
/// The active balloon id set is authoritative. The HUD never recounts Flame
/// components, and a pop updates the id set, score, remaining count and phase
/// before listeners are notified once.
class GameSessionState extends ChangeNotifier {
  static const int stageOne = 1;
  static const int stageOneSeconds = 15;
  static const int scorePerBalloon = 100;

  GameSessionPhase _phase = GameSessionPhase.ready;
  GameSessionPhase _phaseBeforePause = GameSessionPhase.playing;
  final Set<int> _activeBalloonIds = <int>{};
  int _score = 0;
  int _secondsLeft = stageOneSeconds;
  double _preciseSecondsLeft = stageOneSeconds.toDouble();
  int _stageClearCount = 0;
  int _updateCount = 0;
  Duration _elapsed = Duration.zero;
  bool _disposed = false;

  GameSessionPhase get phase => _phase;
  int get stage => stageOne;
  int get updateCount => _updateCount;
  int get score => _score;
  int get remainingBalloons => _activeBalloonIds.length;
  int get secondsLeft => _secondsLeft;
  int get stageClearCount => _stageClearCount;
  Duration get elapsed => _elapsed;
  bool get isPlaying => _phase == GameSessionPhase.playing;
  bool get isRunning => isPlaying;
  bool get isPaused => _phase == GameSessionPhase.paused;
  bool get isDisposed => _disposed;
  Set<int> get activeBalloonIds => Set<int>.unmodifiable(_activeBalloonIds);

  GameSessionSnapshot get snapshot => GameSessionSnapshot(
        stage: stage,
        score: score,
        remainingBalloons: remainingBalloons,
        phase: phase,
        secondsLeft: secondsLeft,
        stageClearCount: stageClearCount,
      );

  void startStageOne(Iterable<int> balloonIds) {
    if (_disposed) return;
    _activeBalloonIds
      ..clear()
      ..addAll(balloonIds);
    _score = 0;
    _secondsLeft = stageOneSeconds;
    _preciseSecondsLeft = stageOneSeconds.toDouble();
    _stageClearCount = 0;
    _updateCount = 0;
    _elapsed = Duration.zero;
    _phase = GameSessionPhase.playing;
    _phaseBeforePause = GameSessionPhase.playing;
    notifyListeners();
  }

  BalloonPopResult popBalloon(int id) {
    if (_disposed || !isPlaying || !_activeBalloonIds.remove(id)) {
      return BalloonPopResult.ignored;
    }
    _score += scorePerBalloon;
    if (_activeBalloonIds.isEmpty) {
      _phase = GameSessionPhase.stageClear;
      _stageClearCount++;
      notifyListeners();
      return BalloonPopResult.stageCleared;
    }
    notifyListeners();
    return BalloonPopResult.popped;
  }

  void pause() {
    if (_disposed || _phase != GameSessionPhase.playing) return;
    _phaseBeforePause = _phase;
    _phase = GameSessionPhase.paused;
    notifyListeners();
  }

  void resume() {
    if (_disposed || _phase != GameSessionPhase.paused) return;
    _phase = _phaseBeforePause;
    notifyListeners();
  }

  /// Advances diagnostics and the Stage 1 clock without rebuilding Flutter
  /// for movement frames. Listeners are notified only when the displayed
  /// second changes or the stage reaches its failure state.
  void recordUpdate(double deltaSeconds) {
    if (_disposed || !isPlaying || deltaSeconds <= 0) return;
    _updateCount++;
    _elapsed += Duration(
      microseconds: (deltaSeconds * Duration.microsecondsPerSecond).round(),
    );
    _preciseSecondsLeft = max(0, _preciseSecondsLeft - deltaSeconds);
    final nextDisplayedSecond = _preciseSecondsLeft.ceil();
    if (nextDisplayedSecond == _secondsLeft) return;
    _secondsLeft = nextDisplayedSecond;
    if (_secondsLeft == 0) {
      _phase = GameSessionPhase.failed;
    }
    notifyListeners();
  }

  bool matchesActiveComponentIds(Iterable<int> componentIds) {
    return setEquals(_activeBalloonIds, componentIds.toSet());
  }

  @override
  void dispose() {
    _disposed = true;
    _phase = GameSessionPhase.disposed;
    _activeBalloonIds.clear();
    super.dispose();
  }
}
