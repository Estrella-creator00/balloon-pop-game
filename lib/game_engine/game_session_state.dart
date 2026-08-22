import 'dart:math';

import 'package:flutter/foundation.dart';

import 'session/game_session_snapshot.dart';
import 'stages/flame_stage_definition.dart';

enum BalloonPopResult { ignored, popped, stageCleared }

enum BossHitResult { ignored, hit, bossCleared }

/// Single session state for the Stage 1-10 Flame preview loop.
///
/// The active balloon id set is authoritative. The HUD never recounts Flame
/// components, and a pop updates the id set, score, remaining count and phase
/// before listeners are notified once.
class GameSessionState extends ChangeNotifier {
  GameSessionPhase _phase = GameSessionPhase.ready;
  GameSessionPhase _phaseBeforePause = GameSessionPhase.playing;
  final Set<int> _activeBalloonIds = <int>{};
  final Map<int, int> _activeBossHp = <int, int>{};
  FlameStageDefinition? _stageDefinition;
  int _score = 0;
  int _secondsLeft = 0;
  double _preciseSecondsLeft = 0;
  int _stageClearCount = 0;
  int _lastClearBonus = 0;
  int _updateCount = 0;
  Duration _elapsed = Duration.zero;
  bool _disposed = false;

  GameSessionPhase get phase => _phase;
  int get stage => _stageDefinition?.stage ?? 0;
  FlameStageDefinition? get stageDefinition => _stageDefinition;
  int get updateCount => _updateCount;
  int get score => _score;
  int get remainingBalloons => _activeBalloonIds.length;
  int get activeBossCount => _activeBossHp.length;
  int get bossHp => _activeBossHp.values.fold(0, (sum, hp) => sum + hp);
  int get bossMaxHp {
    final rule = _stageDefinition?.bossRule;
    return rule == null ? 0 : rule.maxHp * rule.bossCount;
  }

  int get secondsLeft => _secondsLeft;
  int get stageClearCount => _stageClearCount;
  int get lastClearBonus => _lastClearBonus;
  Duration get elapsed => _elapsed;
  bool get isPlaying => _phase == GameSessionPhase.playing;
  bool get isRunning => isPlaying;
  bool get isPaused => _phase == GameSessionPhase.paused;
  bool get isStageClear => _phase == GameSessionPhase.stageClear;
  bool get isBossClear => _phase == GameSessionPhase.bossClear;
  bool get isSectionClear => _phase == GameSessionPhase.sectionClear;
  bool get isTimeOver => _phase == GameSessionPhase.failed;
  bool get isDisposed => _disposed;
  Set<int> get activeBalloonIds => Set<int>.unmodifiable(_activeBalloonIds);
  Set<int> get activeBossIds => Set<int>.unmodifiable(_activeBossHp.keys);

  GameSessionSnapshot get snapshot => GameSessionSnapshot(
        stage: stage,
        score: score,
        remainingBalloons: remainingBalloons,
        phase: phase,
        secondsLeft: secondsLeft,
        stageClearCount: stageClearCount,
        activeBossCount: activeBossCount,
        bossHp: bossHp,
        bossMaxHp: bossMaxHp,
      );

  void startNewGame(
    FlameStageDefinition definition,
    Iterable<int> balloonIds, {
    Map<int, int> bossHpById = const <int, int>{},
  }) {
    if (_disposed) return;
    _score = 0;
    _stageClearCount = 0;
    _lastClearBonus = 0;
    _updateCount = 0;
    _elapsed = Duration.zero;
    _beginStage(definition, balloonIds, bossHpById);
  }

  void beginNextStage(
    FlameStageDefinition definition,
    Iterable<int> balloonIds, {
    Map<int, int> bossHpById = const <int, int>{},
  }) {
    if (_disposed || _phase != GameSessionPhase.stageClear) return;
    _beginStage(definition, balloonIds, bossHpById);
  }

  void _beginStage(
    FlameStageDefinition definition,
    Iterable<int> balloonIds,
    Map<int, int> bossHpById,
  ) {
    _stageDefinition = definition;
    _activeBalloonIds
      ..clear()
      ..addAll(balloonIds);
    _activeBossHp
      ..clear()
      ..addAll(bossHpById);
    _secondsLeft = definition.timeLimitSeconds;
    _preciseSecondsLeft = definition.timeLimitSeconds.toDouble();
    _lastClearBonus = 0;
    _phase = GameSessionPhase.playing;
    _phaseBeforePause = GameSessionPhase.playing;
    notifyListeners();
  }

  BalloonPopResult popBalloon(int id) {
    final definition = _stageDefinition;
    if (_disposed ||
        !isPlaying ||
        definition == null ||
        definition.successCondition !=
            StageSuccessCondition.allBalloonsPopped ||
        !_activeBalloonIds.remove(id)) {
      return BalloonPopResult.ignored;
    }
    _score += definition.scoreRule.pointsPerBalloon;
    if (_activeBalloonIds.isEmpty) {
      _stageClearCount++;
      _lastClearBonus = definition.scoreRule.clearBonus(_secondsLeft);
      _score += _lastClearBonus;
      _phase = GameSessionPhase.stageClear;
      notifyListeners();
      return BalloonPopResult.stageCleared;
    }
    notifyListeners();
    return BalloonPopResult.popped;
  }

  BossHitResult hitBoss(int id) {
    final definition = _stageDefinition;
    final rule = definition?.bossRule;
    final currentHp = _activeBossHp[id];
    if (_disposed ||
        !isPlaying ||
        definition == null ||
        rule == null ||
        definition.successCondition !=
            StageSuccessCondition.allBossesDefeated ||
        currentHp == null ||
        currentHp <= 0) {
      return BossHitResult.ignored;
    }

    final nextHp = currentHp - 1;
    if (nextHp > 0) {
      _activeBossHp[id] = nextHp;
      notifyListeners();
      return BossHitResult.hit;
    }

    _activeBossHp.remove(id);
    _score += rule.defeatPoints;
    if (_activeBossHp.isNotEmpty) {
      notifyListeners();
      return BossHitResult.hit;
    }

    _stageClearCount++;
    _lastClearBonus = _secondsLeft * rule.remainingSecondMultiplier;
    _score += _lastClearBonus;
    _phase = GameSessionPhase.bossClear;
    notifyListeners();
    return BossHitResult.bossCleared;
  }

  int bossHpFor(int id) => _activeBossHp[id] ?? 0;

  void completeSectionClear() {
    if (_disposed ||
        _phase != GameSessionPhase.bossClear ||
        _stageDefinition?.completion != StageCompletion.sectionClear) {
      return;
    }
    _phase = GameSessionPhase.sectionClear;
    notifyListeners();
  }

  void pause() {
    if (_disposed ||
        (_phase != GameSessionPhase.playing &&
            _phase != GameSessionPhase.stageClear &&
            _phase != GameSessionPhase.bossClear)) {
      return;
    }
    _phaseBeforePause = _phase;
    _phase = GameSessionPhase.paused;
    notifyListeners();
  }

  void resume() {
    if (_disposed || _phase != GameSessionPhase.paused) return;
    _phase = _phaseBeforePause;
    notifyListeners();
  }

  /// Advances diagnostics and the current stage clock without rebuilding Flutter
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
    if (_secondsLeft == 0 &&
        _stageDefinition?.failureCondition ==
            StageFailureCondition.timeExpired) {
      _phase = GameSessionPhase.failed;
      if (_stageDefinition?.isBoss ?? false) _activeBossHp.clear();
    }
    notifyListeners();
  }

  bool matchesActiveComponentIds(Iterable<int> componentIds) {
    return setEquals(_activeBalloonIds, componentIds.toSet());
  }

  bool matchesActiveBossComponentIds(Iterable<int> componentIds) {
    return setEquals(_activeBossHp.keys.toSet(), componentIds.toSet());
  }

  void endSession() {
    if (_disposed) return;
    _activeBalloonIds.clear();
    _activeBossHp.clear();
    _phase = GameSessionPhase.ready;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _phase = GameSessionPhase.disposed;
    _activeBalloonIds.clear();
    _activeBossHp.clear();
    super.dispose();
  }
}
