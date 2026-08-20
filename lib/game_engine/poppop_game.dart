import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'components/balloon_component.dart';
import 'components/basic_pop_effect.dart';
import 'components/game_diagnostics_component.dart';
import 'game_session_state.dart';
import 'rendering/basic_balloon_sprite_cache.dart';
import 'session/game_session_snapshot.dart';
import 'stages/flame_stage_definition.dart';
import 'stages/stage_balloon_spawner.dart';

/// Flame root for the isolated Stage 1-9 preview loop.
class PoppopGame extends FlameGame {
  PoppopGame(
    this.sessionState, {
    this.stageDefinitions = flamePreviewStages,
    this.stageSpawner = const StageBalloonSpawner(),
    BasicBalloonSpriteCache? spriteCache,
  })  : spriteCache = spriteCache ?? BasicBalloonSpriteCache(),
        assert(stageDefinitions.isNotEmpty) {
    // The Flutter host owns lifecycle decisions so inactive/background states
    // always pause and a manual pause is preserved on foreground return.
    pauseWhenBackgrounded = false;
  }

  static const double stageTransitionDuration = 0.4;

  final GameSessionState sessionState;
  final List<FlameStageDefinition> stageDefinitions;
  final StageBalloonSpawner stageSpawner;
  final BasicBalloonSpriteCache spriteCache;
  final Map<int, BalloonComponent> _balloons = <int, BalloonComponent>{};
  final Set<BasicPopEffect> _popEffects = <BasicPopEffect>{};
  bool _shutdown = false;
  bool _hostWantsRunning = true;
  bool _stageTransitionInFlight = false;
  bool _restartInFlight = false;
  double _stageTransitionElapsed = 0;
  double _lastAppliedDelta = 0;
  int _operationEpoch = 0;
  int _componentGeneration = 0;

  bool get isShutdown => _shutdown;
  bool get isStageTransitionInFlight => _stageTransitionInFlight;
  double get lastAppliedDelta => _lastAppliedDelta;
  int get activeBalloonCount => _balloons.length;
  int get activeEffectCount => _popEffects.length;
  int get activeParticleCount =>
      _popEffects.length * BasicPopEffect.particleCount;
  int get componentGeneration => _componentGeneration;
  Iterable<BalloonComponent> get balloonComponents => _balloons.values;
  bool get isComponentStateSynchronized =>
      sessionState.matchesActiveComponentIds(_balloons.keys);

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
    await camera.viewport.add(
      GameDiagnosticsComponent(textProvider: _diagnosticsText),
    );
    final operation = ++_operationEpoch;
    await _installStage(
      stageDefinitions.first,
      operation: operation,
      resetSession: true,
    );
    _applyHostRunIntent();
  }

  @override
  void update(double dt) {
    if (_shutdown) return;
    final clampedDt = min(dt, BalloonComponent.maxUpdateDelta);
    _lastAppliedDelta = clampedDt;

    switch (sessionState.phase) {
      case GameSessionPhase.stageClear:
        super.update(clampedDt);
        _stageTransitionElapsed += clampedDt;
        if (_stageTransitionElapsed >= stageTransitionDuration &&
            !_stageTransitionInFlight) {
          unawaited(_advanceToNextStage());
        }
      case GameSessionPhase.normalClear:
        if (_popEffects.isNotEmpty) {
          super.update(clampedDt);
        } else {
          super.update(0);
          pauseEngine();
        }
      case GameSessionPhase.playing:
        super.update(clampedDt);
        sessionState.recordUpdate(clampedDt);
        if (sessionState.phase == GameSessionPhase.failed) pauseEngine();
      case GameSessionPhase.ready:
      case GameSessionPhase.paused:
      case GameSessionPhase.failed:
      case GameSessionPhase.disposed:
        return;
    }
  }

  Future<void> _advanceToNextStage() async {
    if (_shutdown || _stageTransitionInFlight) return;
    final currentIndex = stageDefinitions.indexWhere(
      (definition) => definition.stage == sessionState.stage,
    );
    if (currentIndex < 0 || currentIndex + 1 >= stageDefinitions.length) return;

    _stageTransitionInFlight = true;
    final operation = ++_operationEpoch;
    try {
      await _installStage(
        stageDefinitions[currentIndex + 1],
        operation: operation,
        resetSession: false,
      );
      _applyHostRunIntent();
    } finally {
      if (operation == _operationEpoch) _stageTransitionInFlight = false;
    }
  }

  Future<void> _installStage(
    FlameStageDefinition definition, {
    required int operation,
    required bool resetSession,
  }) async {
    _removeGameplayComponents();
    _stageTransitionElapsed = 0;
    final generation = ++_componentGeneration;
    final created = stageSpawner.create(
      definition: definition,
      playfieldSize: () => size,
      idBase: generation * 1000,
      onPopRequested: _handlePopRequest,
      spriteForColor: spriteCache.imageFor,
    );
    await world.addAll(created);
    if (_shutdown || operation != _operationEpoch) {
      for (final balloon in created) {
        balloon.removeFromParent();
      }
      processLifecycleEvents();
      return;
    }
    _balloons.addEntries(
      created.map((balloon) => MapEntry(balloon.balloonId, balloon)),
    );
    if (resetSession) {
      sessionState.startNewGame(definition, _balloons.keys);
    } else {
      sessionState.beginNextStage(definition, _balloons.keys);
    }
  }

  bool _handlePopRequest(BalloonComponent balloon) {
    if (_shutdown || !identical(_balloons[balloon.balloonId], balloon)) {
      return false;
    }
    final result = sessionState.popBalloon(balloon.balloonId);
    if (result == BalloonPopResult.ignored) return false;
    _balloons.remove(balloon.balloonId);
    balloon.removeFromParent();
    final effect = BasicPopEffect(
      center: balloon.position + balloon.size / 2,
      color: balloon.color,
      onFinished: _handleEffectFinished,
    );
    _popEffects.add(effect);
    world.add(effect);
    return true;
  }

  void _handleEffectFinished(BasicPopEffect effect) {
    _popEffects.remove(effect);
  }

  Future<void> restartGame({bool resume = true}) async {
    if (_shutdown || _restartInFlight) return;
    _restartInFlight = true;
    _hostWantsRunning = resume;
    _stageTransitionInFlight = false;
    final operation = ++_operationEpoch;
    try {
      await _installStage(
        stageDefinitions.first,
        operation: operation,
        resetSession: true,
      );
      _applyHostRunIntent();
    } finally {
      if (operation == _operationEpoch) _restartInFlight = false;
    }
  }

  Future<void> restartStageOne({bool resume = true}) =>
      restartGame(resume: resume);

  void _removeGameplayComponents() {
    for (final balloon in _balloons.values) {
      balloon.removeFromParent();
    }
    for (final effect in _popEffects) {
      effect.removeFromParent();
    }
    _balloons.clear();
    _popEffects.clear();
    processLifecycleEvents();
  }

  void _applyHostRunIntent() {
    if (_shutdown) return;
    if (_hostWantsRunning) {
      resumeEngine();
    } else {
      pauseEngine();
      sessionState.pause();
    }
  }

  String _diagnosticsText(double fps, double averageFrameMilliseconds) {
    return 'FPS ${fps.toStringAsFixed(0)}  '
        '${averageFrameMilliseconds.toStringAsFixed(1)}ms\n'
        'STAGE ${sessionState.stage}  SCORE ${sessionState.score}  '
        'TIME ${sessionState.secondsLeft}\n'
        'BALLOONS $activeBalloonCount / ${sessionState.remainingBalloons}  '
        'EFFECTS $activeEffectCount  PARTICLES $activeParticleCount\n'
        'PHASE ${sessionState.phase.name}';
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
    if (sessionState.phase == GameSessionPhase.normalClear ||
        sessionState.phase == GameSessionPhase.failed) {
      return;
    }
    sessionState.resume();
    resumeEngine();
  }

  void shutdown() {
    if (_shutdown) return;
    _shutdown = true;
    _hostWantsRunning = false;
    _operationEpoch++;
    _stageTransitionInFlight = false;
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
