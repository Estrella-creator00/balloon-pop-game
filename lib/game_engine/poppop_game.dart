import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'components/balloon_component.dart';
import 'components/basic_pop_effect.dart';
import 'components/boss_balloon_component.dart';
import 'components/game_diagnostics_component.dart';
import 'game_session_state.dart';
import 'rendering/basic_balloon_sprite_cache.dart';
import 'session/game_session_snapshot.dart';
import 'stages/flame_stage_definition.dart';
import 'stages/stage_balloon_spawner.dart';
import 'stages/stage_boss_spawner.dart';

class PoppopGame extends FlameGame {
  PoppopGame(
    this.sessionState, {
    List<FlameStageDefinition>? stageDefinitions,
    this.initialStage = 1,
    this.stageSpawner = const StageBalloonSpawner(),
    this.stageBossSpawner = const StageBossSpawner(),
    this.stage30SwapRoll,
    BasicBalloonSpriteCache? spriteCache,
  })  : stageDefinitions = stageDefinitions ?? flamePreviewStages,
        spriteCache = spriteCache ?? BasicBalloonSpriteCache(),
        assert(stageDefinitions == null || stageDefinitions.isNotEmpty) {
    pauseWhenBackgrounded = false;
  }

  static const double stageTransitionDuration = 0.4;
  static const double bossClearTransitionDuration = 1;

  final GameSessionState sessionState;
  final List<FlameStageDefinition> stageDefinitions;
  final int initialStage;
  final StageBalloonSpawner stageSpawner;
  final StageBossSpawner stageBossSpawner;
  final double Function()? stage30SwapRoll;
  final BasicBalloonSpriteCache spriteCache;
  final Map<int, BalloonComponent> _balloons = <int, BalloonComponent>{};
  final Map<int, BossBalloonComponent> _bosses = <int, BossBalloonComponent>{};
  final Set<BasicPopEffect> _popEffects = <BasicPopEffect>{};
  final Random _random = Random(30130);
  bool _shutdown = false;
  bool _hostWantsRunning = true;
  bool _transitionInFlight = false;
  bool _restartInFlight = false;
  double _transitionElapsed = 0;
  double _lastAppliedDelta = 0;
  int _operationEpoch = 0;
  int _componentGeneration = 0;

  bool get isShutdown => _shutdown;
  bool get isStageTransitionInFlight => _transitionInFlight;
  double get lastAppliedDelta => _lastAppliedDelta;
  int get activeBalloonCount => _balloons.length;
  int get activeBossCount => _bosses.length;
  int get activeEffectCount => _popEffects.length;
  int get activeParticleCount =>
      _popEffects.length * BasicPopEffect.particleCount;
  int get componentGeneration => _componentGeneration;
  Iterable<BalloonComponent> get balloonComponents => _balloons.values;
  Iterable<BossBalloonComponent> get bossComponents => _bosses.values;
  bool get isComponentStateSynchronized =>
      sessionState.matchesActiveComponentIds(_balloons.keys) &&
      sessionState.matchesActiveBossComponentIds(_bosses.keys);

  @override
  Color backgroundColor() => const Color(0xFF14243A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (_shutdown) return;
    await spriteCache.preload();
    if (_shutdown) return;
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();
    await camera.viewport
        .add(GameDiagnosticsComponent(textProvider: _diagnosticsText));
    final requested = stageDefinitions.where((d) => d.stage == initialStage);
    final definition =
        requested.isEmpty ? stageDefinitions.first : requested.first;
    await _installStage(definition,
        operation: ++_operationEpoch, resetSession: true);
    _applyHostRunIntent();
  }

  @override
  void update(double dt) {
    if (_shutdown) return;
    final clamped = min(dt, BalloonComponent.maxUpdateDelta);
    _lastAppliedDelta = clamped;
    switch (sessionState.phase) {
      case GameSessionPhase.stageClear:
        super.update(clamped);
        _transitionElapsed += clamped;
        if (_transitionElapsed >= stageTransitionDuration &&
            !_transitionInFlight) {
          unawaited(_advanceToNextStage());
        }
      case GameSessionPhase.bossClear:
        super.update(clamped);
        _transitionElapsed += clamped;
        if (_transitionElapsed >= bossClearTransitionDuration &&
            !_transitionInFlight) {
          if (sessionState.stageDefinition?.completion ==
              StageCompletion.coreClear) {
            sessionState.completeCoreClear();
            _transitionElapsed = 0;
          } else {
            unawaited(_advanceToNextStage());
          }
        }
      case GameSessionPhase.coreClear:
        if (_popEffects.isNotEmpty) {
          super.update(clamped);
        } else {
          super.update(0);
          pauseEngine();
        }
      case GameSessionPhase.playing:
        super.update(clamped);
        sessionState.recordUpdate(clamped);
        if (sessionState.phase == GameSessionPhase.failed) {
          _removeGameplayComponents();
          pauseEngine();
        }
      case GameSessionPhase.ready:
      case GameSessionPhase.bossReady:
      case GameSessionPhase.paused:
      case GameSessionPhase.failed:
      case GameSessionPhase.disposed:
        return;
    }
  }

  Future<void> _advanceToNextStage() async {
    if (_shutdown || _transitionInFlight) return;
    final index =
        stageDefinitions.indexWhere((d) => d.stage == sessionState.stage);
    if (index < 0 || index + 1 >= stageDefinitions.length) return;
    _transitionInFlight = true;
    final operation = ++_operationEpoch;
    try {
      await _installStage(stageDefinitions[index + 1],
          operation: operation, resetSession: false);
      _applyHostRunIntent();
    } finally {
      if (operation == _operationEpoch) _transitionInFlight = false;
    }
  }

  Future<void> _installStage(
    FlameStageDefinition definition, {
    required int operation,
    required bool resetSession,
  }) async {
    _removeGameplayComponents();
    _transitionElapsed = 0;
    final generation = ++_componentGeneration;
    final balloons = <BalloonComponent>[];
    final bosses = <BossBalloonComponent>[];
    if (definition.isBoss) {
      final rule = definition.bossRule!;
      final initialSize = rule.initialSizeFor(min(size.x, size.y));
      await spriteCache.prepareBoss(
          stage: definition.stage, initialSize: initialSize, rule: rule);
      bosses.addAll(stageBossSpawner.create(
        definition: definition,
        generation: generation,
        idBase: generation * 1000,
        playfieldSize: () => size,
        readHp: sessionState.bossHpFor,
        readIsFake: sessionState.isFakeBoss,
        onHitRequested: _handleBossHitRequest,
        spriteForHp: spriteCache.bossImageForHp,
      ));
      await world.addAll(bosses);
    } else {
      balloons.addAll(stageSpawner.create(
        definition: definition,
        playfieldSize: () => size,
        generation: generation,
        idBase: generation * 1000,
        onHitRequested: _handleBalloonHitRequest,
        readHp: sessionState.balloonHpFor,
        spriteResolver: spriteCache.imageForBalloon,
      ));
      await world.addAll(balloons);
    }
    if (_shutdown || operation != _operationEpoch) {
      for (final component in <PositionComponent>[...balloons, ...bosses]) {
        component.removeFromParent();
      }
      processLifecycleEvents();
      return;
    }
    _balloons.addEntries(balloons.map((b) => MapEntry(b.balloonId, b)));
    _bosses.addEntries(bosses.map((b) => MapEntry(b.bossId, b)));
    final targetHp = <int, int>{
      for (final b in balloons.where((b) => !b.isFake)) b.balloonId: b.maxHp,
    };
    final fakeIds =
        balloons.where((b) => b.isFake).map((b) => b.balloonId).toSet();
    final bossHp = <int, int>{for (final b in bosses) b.bossId: b.maxHp};
    if (resetSession) {
      sessionState.startNewGame(definition, targetHp,
          fakeIds: fakeIds, bossHpById: bossHp, generation: generation);
    } else {
      sessionState.beginNextStage(definition, targetHp,
          fakeIds: fakeIds, bossHpById: bossHp, generation: generation);
    }
    for (final boss in bosses) {
      boss.refreshRole();
    }
  }

  bool _handleBalloonHitRequest(BalloonComponent balloon) {
    if (_shutdown ||
        !identical(_balloons[balloon.balloonId], balloon) ||
        balloon.generation != sessionState.generation) {
      return false;
    }
    final result = sessionState.hitBalloon(balloon.balloonId);
    if (result == BalloonHitResult.ignored) return false;
    _addEffect(balloon.position + balloon.size / 2, balloon.color);
    if (result == BalloonHitResult.hit) {
      balloon.applyRegisteredHit(sessionState.balloonHpFor(balloon.balloonId));
      return true;
    }
    _balloons.remove(balloon.balloonId);
    balloon.markRemoved();
    balloon.removeFromParent();
    if (result == BalloonHitResult.stageCleared) _removeFakeBalloons();
    if (sessionState.phase == GameSessionPhase.failed) {
      _removeGameplayComponents();
      pauseEngine();
    }
    return true;
  }

  bool _handleBossHitRequest(
    BossBalloonComponent requestedBoss,
    Vector2? worldPoint,
  ) {
    final boss =
        sessionState.stageDefinition?.isStage30 == true && worldPoint != null
            ? _closestStage30Boss(worldPoint) ?? requestedBoss
            : requestedBoss;
    if (_shutdown ||
        !identical(_bosses[boss.bossId], boss) ||
        boss.generation != sessionState.generation) {
      return false;
    }
    final result = sessionState.hitBoss(
      boss.bossId,
      swapRoll: stage30SwapRoll?.call() ?? _random.nextDouble(),
    );
    if (result == BossHitResult.ignored) return false;
    _addEffect(boss.position + boss.size / 2, boss.displayColor);
    if (result == BossHitResult.fakeHit) {
      if (sessionState.phase == GameSessionPhase.failed) {
        _removeGameplayComponents();
        pauseEngine();
      }
      return true;
    }
    if (result == BossHitResult.hit) {
      if (sessionState.stageDefinition?.bossRule?.sharedHp == true) {
        for (final candidate in _bosses.values) {
          candidate.applyRegisteredHit(
              hp: sessionState.bossHpFor(candidate.bossId));
          candidate.refreshRole();
        }
      } else {
        boss.applyRegisteredHit(hp: sessionState.bossHpFor(boss.bossId));
      }
      return true;
    }
    if (result == BossHitResult.bossDefeated) {
      _bosses.remove(boss.bossId);
      boss.markDefeated();
      boss.removeFromParent();
      return true;
    }
    for (final candidate in _bosses.values) {
      candidate.markDefeated();
      candidate.removeFromParent();
    }
    _bosses.clear();
    _transitionElapsed = 0;
    return true;
  }

  BossBalloonComponent? _closestStage30Boss(Vector2 point) {
    BossBalloonComponent? closest;
    var closestDistance = double.infinity;
    for (final candidate in _bosses.values) {
      if (!candidate.playfieldBounds.contains(Offset(point.x, point.y))) {
        continue;
      }
      final dx = point.x - (candidate.position.x + candidate.size.x / 2);
      final dy = point.y - (candidate.position.y + candidate.size.x / 2);
      final distance = dx * dx + dy * dy;
      if (distance <= closestDistance) {
        closest = candidate;
        closestDistance = distance;
      }
    }
    return closest;
  }

  void _addEffect(Vector2 center, Color color) {
    final effect = BasicPopEffect(
        center: center, color: color, onFinished: _handleEffectFinished);
    _popEffects.add(effect);
    world.add(effect);
  }

  void _handleEffectFinished(BasicPopEffect effect) =>
      _popEffects.remove(effect);

  void _removeFakeBalloons() {
    final fakes = _balloons.values.where((b) => b.isFake).toList();
    for (final fake in fakes) {
      _balloons.remove(fake.balloonId);
      fake.markRemoved();
      fake.removeFromParent();
    }
  }

  bool startBossStage() {
    if (_shutdown || !sessionState.startBoss()) return false;
    if (_hostWantsRunning) resumeEngine();
    return true;
  }

  Future<void> jumpToStage(int stage, {bool resume = true}) async {
    if (_shutdown || _restartInFlight) return;
    final matches = stageDefinitions.where((d) => d.stage == stage);
    final definition = matches.isEmpty ? stageDefinitions.first : matches.first;
    _restartInFlight = true;
    _hostWantsRunning = resume;
    _transitionInFlight = false;
    final operation = ++_operationEpoch;
    try {
      await _installStage(definition, operation: operation, resetSession: true);
      _applyHostRunIntent();
    } finally {
      if (operation == _operationEpoch) _restartInFlight = false;
    }
  }

  Future<void> restartGame({bool resume = true}) =>
      jumpToStage(1, resume: resume);
  Future<void> restartStageOne({bool resume = true}) =>
      restartGame(resume: resume);

  void _removeGameplayComponents() {
    for (final balloon in _balloons.values) {
      balloon.markRemoved();
      balloon.removeFromParent();
    }
    for (final boss in _bosses.values) {
      boss.markDefeated();
      boss.removeFromParent();
    }
    for (final effect in _popEffects) {
      effect.removeFromParent();
    }
    _balloons.clear();
    _bosses.clear();
    _popEffects.clear();
    processLifecycleEvents();
  }

  void _applyHostRunIntent() {
    if (_shutdown) return;
    if (_hostWantsRunning && sessionState.phase != GameSessionPhase.bossReady) {
      resumeEngine();
    } else {
      pauseEngine();
    }
  }

  String _diagnosticsText(double fps, double ms) =>
      'FPS ${fps.toStringAsFixed(0)}  ${ms.toStringAsFixed(1)}ms\n'
      'STAGE ${sessionState.stage}  SCORE ${sessionState.score}  TIME ${sessionState.secondsLeft}\n'
      'TARGETS ${sessionState.remainingBalloons}  HP1 ${sessionState.damagedBalloonCount}  '
      'FAKES ${sessionState.fakeCount}\n'
      'BOSSES $activeBossCount  HP ${sessionState.bossHp}/${sessionState.bossMaxHp}  '
      'REAL ${sessionState.stage30RealBossId ?? '-'}\n'
      'EFFECTS $activeEffectCount  PHASE ${sessionState.phase.name}';

  void pausePreview() {
    if (_shutdown) return;
    _hostWantsRunning = false;
    pauseEngine();
    sessionState.pause();
  }

  void resumePreview() {
    if (_shutdown) return;
    _hostWantsRunning = true;
    if (sessionState.phase == GameSessionPhase.coreClear ||
        sessionState.phase == GameSessionPhase.failed ||
        sessionState.phase == GameSessionPhase.bossReady) {
      return;
    }
    sessionState.resume();
    if (sessionState.phase == GameSessionPhase.bossReady) {
      return;
    }
    resumeEngine();
  }

  void shutdown() {
    if (_shutdown) return;
    _shutdown = true;
    _hostWantsRunning = false;
    _operationEpoch++;
    _transitionInFlight = false;
    _restartInFlight = false;
    pauseEngine();
    _removeGameplayComponents();
    spriteCache.dispose();
    sessionState.endSession();
  }

  @override
  void onDispose() {
    shutdown();
    super.onDispose();
  }
}
