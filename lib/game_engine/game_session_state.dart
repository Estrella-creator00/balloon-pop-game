import 'dart:math';

import 'package:flutter/foundation.dart';

import 'session/game_session_snapshot.dart';
import 'endless/endless_mode.dart';
import 'stages/flame_stage_definition.dart';

enum BalloonHitResult { ignored, hit, popped, fakeHit, stageCleared }

enum BossHitResult { ignored, hit, fakeHit, bossDefeated, bossCleared }

class GameSessionState extends ChangeNotifier {
  GameSessionPhase _phase = GameSessionPhase.ready;
  GameSessionPhase _phaseBeforePause = GameSessionPhase.playing;
  final Map<int, int> _targetHp = <int, int>{};
  final Set<int> _fakeIds = <int>{};
  final Map<int, int> _bossHp = <int, int>{};
  FlameStageDefinition? _definition;
  int _score = 0;
  int _secondsLeft = 0;
  double _preciseSecondsLeft = 0;
  int _stageClearCount = 0;
  int _lastClearBonus = 0;
  int _updateCount = 0;
  int _generation = 0;
  int? _stage30RealBossId;
  int _stage30SharedHp = 0;
  bool _isEndless = false;
  int _endlessMistakes = 0;
  bool _disposed = false;

  GameSessionPhase get phase => _phase;
  FlameStageDefinition? get stageDefinition => _definition;
  int get stage => _definition?.stage ?? 0;
  int get score => _score;
  int get secondsLeft => _secondsLeft;
  int get remainingBalloons => _targetHp.length;
  int get damagedBalloonCount => _targetHp.values.where((hp) => hp == 1).length;
  int get fakeCount => _fakeIds.length;
  int get activeBossCount => _bossHp.length;
  int get bossHp => _definition?.bossRule?.sharedHp == true
      ? _stage30SharedHp
      : _bossHp.values.fold(0, (sum, hp) => sum + hp);
  int get bossMaxHp {
    final rule = _definition?.bossRule;
    if (rule == null) return 0;
    return rule.sharedHp ? rule.maxHp : rule.maxHp * rule.bossCount;
  }

  int get stageClearCount => _stageClearCount;
  int get lastClearBonus => _lastClearBonus;
  int get updateCount => _updateCount;
  int get generation => _generation;
  int? get stage30RealBossId => _stage30RealBossId;
  bool get isPlaying => _phase == GameSessionPhase.playing;
  bool get isDisposed => _disposed;
  bool get isEndless => _isEndless;
  int get endlessMistakes => _endlessMistakes;
  Set<int> get activeBalloonIds =>
      Set<int>.unmodifiable(<int>{..._targetHp.keys, ..._fakeIds});
  Set<int> get targetBalloonIds => Set<int>.unmodifiable(_targetHp.keys);
  Set<int> get fakeIds => Set<int>.unmodifiable(_fakeIds);
  Set<int> get activeBossIds => Set<int>.unmodifiable(_bossHp.keys);

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
        damagedBalloonCount: damagedBalloonCount,
        fakeCount: fakeCount,
        stage30RealBossId: stage30RealBossId,
        generation: generation,
        isEndless: isEndless,
        endlessMistakes: endlessMistakes,
      );

  void startEndless(
    Map<int, int> targetHp, {
    Set<int> fakeIds = const <int>{},
    int generation = 0,
  }) {
    if (_disposed) return;
    _score = 0;
    _stageClearCount = 0;
    _lastClearBonus = 0;
    _updateCount = 0;
    _isEndless = true;
    _endlessMistakes = 0;
    _beginStage(
      endlessPreparationStage,
      targetHp,
      fakeIds,
      const <int, int>{},
      generation,
    );
  }

  void addEndlessBalloon(int id, {required int hp, required bool isFake}) {
    if (_disposed || !_isEndless || _phase != GameSessionPhase.playing) return;
    if (isFake) {
      _fakeIds.add(id);
    } else {
      _targetHp[id] = hp;
    }
    notifyListeners();
  }

  void startNewGame(
    FlameStageDefinition definition,
    Map<int, int> targetHp, {
    Set<int> fakeIds = const <int>{},
    Map<int, int> bossHpById = const <int, int>{},
    int generation = 0,
  }) {
    if (_disposed) return;
    _score = 0;
    _stageClearCount = 0;
    _lastClearBonus = 0;
    _updateCount = 0;
    _beginStage(definition, targetHp, fakeIds, bossHpById, generation);
  }

  void beginNextStage(
    FlameStageDefinition definition,
    Map<int, int> targetHp, {
    Set<int> fakeIds = const <int>{},
    Map<int, int> bossHpById = const <int, int>{},
    required int generation,
  }) {
    if (_disposed ||
        (_phase != GameSessionPhase.stageClear &&
            _phase != GameSessionPhase.bossClear &&
            _phase != GameSessionPhase.loading)) {
      return;
    }
    _beginStage(definition, targetHp, fakeIds, bossHpById, generation);
  }

  void beginLoading() {
    if (_disposed || _phase == GameSessionPhase.loading) return;
    _clearLogicalObjects();
    _phase = GameSessionPhase.loading;
    notifyListeners();
  }

  void _beginStage(
    FlameStageDefinition definition,
    Map<int, int> targetHp,
    Set<int> fakeIds,
    Map<int, int> bossHpById,
    int generation,
  ) {
    if (definition.stage != 0) {
      _isEndless = false;
      _endlessMistakes = 0;
    }
    _definition = definition;
    _generation = generation;
    _targetHp
      ..clear()
      ..addAll(targetHp);
    _fakeIds
      ..clear()
      ..addAll(fakeIds);
    _bossHp
      ..clear()
      ..addAll(bossHpById);
    _secondsLeft = definition.timeLimitSeconds;
    _preciseSecondsLeft = definition.timeLimitSeconds.toDouble();
    _lastClearBonus = 0;
    _stage30SharedHp =
        definition.bossRule?.sharedHp == true ? definition.bossRule!.maxHp : 0;
    _stage30RealBossId = definition.isStage30 && bossHpById.isNotEmpty
        ? bossHpById.keys.first
        : null;
    _phase = definition.isBoss
        ? GameSessionPhase.bossReady
        : GameSessionPhase.playing;
    _phaseBeforePause = _phase;
    notifyListeners();
  }

  bool startBoss() {
    if (_disposed || _phase != GameSessionPhase.bossReady) return false;
    _phase = GameSessionPhase.playing;
    _phaseBeforePause = _phase;
    notifyListeners();
    return true;
  }

  BalloonHitResult hitBalloon(int id) {
    final definition = _definition;
    if (_disposed || !isPlaying || definition == null) {
      return BalloonHitResult.ignored;
    }
    if (_fakeIds.remove(id)) {
      if (_isEndless) {
        _endlessMistakes++;
        if (_endlessMistakes >= EndlessModeRules.mistakeLimit) {
          _phase = GameSessionPhase.endlessComplete;
          _clearLogicalObjects();
        }
        notifyListeners();
        return BalloonHitResult.fakeHit;
      }
      _applyTimePenalty(definition.balloonRule.fakePenaltySeconds);
      notifyListeners();
      return BalloonHitResult.fakeHit;
    }
    final hp = _targetHp[id];
    if (hp == null || hp <= 0) return BalloonHitResult.ignored;
    if (hp > 1) {
      _targetHp[id] = hp - 1;
      notifyListeners();
      return BalloonHitResult.hit;
    }
    _targetHp.remove(id);
    _score += definition.scoreRule.pointsPerBalloon;
    if (_isEndless) {
      notifyListeners();
      return BalloonHitResult.popped;
    }
    if (_targetHp.isNotEmpty) {
      notifyListeners();
      return BalloonHitResult.popped;
    }
    _fakeIds.clear();
    _stageClearCount++;
    _lastClearBonus = definition.scoreRule.clearBonus(_secondsLeft);
    _score += _lastClearBonus;
    _phase = GameSessionPhase.stageClear;
    notifyListeners();
    return BalloonHitResult.stageCleared;
  }

  BossHitResult hitBoss(int id, {required double swapRoll}) {
    final definition = _definition;
    final rule = definition?.bossRule;
    if (_disposed || !isPlaying || rule == null || !_bossHp.containsKey(id)) {
      return BossHitResult.ignored;
    }
    if (rule.sharedHp) {
      if (id != _stage30RealBossId) {
        _applyTimePenalty(definition!.balloonRule.fakePenaltySeconds);
        notifyListeners();
        return BossHitResult.fakeHit;
      }
      if (_stage30SharedHp <= 0) return BossHitResult.ignored;
      _stage30SharedHp--;
      if (_stage30SharedHp > 0) {
        if (swapRoll < rule.swapChance) {
          _stage30RealBossId = _bossHp.keys.firstWhere(
            (bossId) => bossId != _stage30RealBossId,
          );
        }
        notifyListeners();
        return BossHitResult.hit;
      }
      _bossHp.clear();
      return _finishBossStage(rule);
    }

    final hp = _bossHp[id]!;
    if (hp > 1) {
      _bossHp[id] = hp - 1;
      notifyListeners();
      return BossHitResult.hit;
    }
    _bossHp.remove(id);
    _score += rule.defeatPoints;
    if (_bossHp.isNotEmpty) {
      notifyListeners();
      return BossHitResult.bossDefeated;
    }
    return _finishBossStage(rule, awardDefeatPoint: false);
  }

  BossHitResult _finishBossStage(
    FlameBossRule rule, {
    bool awardDefeatPoint = true,
  }) {
    if (awardDefeatPoint) _score += rule.defeatPoints;
    _stageClearCount++;
    _lastClearBonus = _secondsLeft * rule.remainingSecondMultiplier;
    _score += _lastClearBonus;
    _phase = GameSessionPhase.bossClear;
    notifyListeners();
    return BossHitResult.bossCleared;
  }

  void _applyTimePenalty(int seconds) {
    _preciseSecondsLeft = max(0, _preciseSecondsLeft - seconds);
    _secondsLeft = _preciseSecondsLeft.ceil();
    if (_secondsLeft == 0) {
      _phase = GameSessionPhase.failed;
      _clearLogicalObjects();
    }
  }

  int balloonHpFor(int id) => _targetHp[id] ?? (_fakeIds.contains(id) ? 1 : 0);
  int bossHpFor(int id) => _definition?.bossRule?.sharedHp == true
      ? (_bossHp.containsKey(id) ? _stage30SharedHp : 0)
      : (_bossHp[id] ?? 0);
  bool isFakeBalloon(int id) => _fakeIds.contains(id);
  bool isFakeBoss(int id) =>
      _definition?.bossRule?.sharedHp == true && id != _stage30RealBossId;

  void completeCoreClear() {
    if (_phase != GameSessionPhase.bossClear ||
        _definition?.completion != StageCompletion.coreClear) {
      return;
    }
    _phase = GameSessionPhase.coreClear;
    notifyListeners();
  }

  void pause() {
    if (_disposed ||
        !<GameSessionPhase>{
          GameSessionPhase.playing,
          GameSessionPhase.bossReady,
          GameSessionPhase.stageClear,
          GameSessionPhase.bossClear,
        }.contains(_phase)) {
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

  void recordUpdate(double dt) {
    if (_disposed || !isPlaying || dt <= 0) return;
    _updateCount++;
    if (_isEndless) return;
    _preciseSecondsLeft = max(0, _preciseSecondsLeft - dt);
    final displayed = _preciseSecondsLeft.ceil();
    if (displayed == _secondsLeft) return;
    _secondsLeft = displayed;
    if (_secondsLeft == 0) {
      _phase = GameSessionPhase.failed;
      _clearLogicalObjects();
    }
    notifyListeners();
  }

  bool matchesActiveComponentIds(Iterable<int> ids) =>
      setEquals(activeBalloonIds, ids.toSet());
  bool matchesActiveBossComponentIds(Iterable<int> ids) =>
      setEquals(_bossHp.keys.toSet(), ids.toSet());

  void _clearLogicalObjects() {
    _targetHp.clear();
    _fakeIds.clear();
    _bossHp.clear();
    _stage30SharedHp = 0;
    _stage30RealBossId = null;
  }

  void endSession() {
    if (_disposed) return;
    _clearLogicalObjects();
    _phase = GameSessionPhase.ready;
    _isEndless = false;
    _endlessMistakes = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _phase = GameSessionPhase.disposed;
    _clearLogicalObjects();
    super.dispose();
  }
}
