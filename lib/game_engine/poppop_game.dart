import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'components/balloon_component.dart';
import 'components/basic_pop_effect.dart';
import 'components/game_diagnostics_component.dart';
import 'game_session_state.dart';
import 'session/game_session_snapshot.dart';

/// Flame root for the isolated Stage 1 vertical slice.
class PoppopGame extends FlameGame {
  PoppopGame(
    this.sessionState, {
    this.stageOneSpawns = stageOneBalloonSpawns,
  }) {
    // Flame's default lifecycle policy treats `inactive` like `resumed`.
    // The preview page owns lifecycle decisions so inactive/background states
    // are always paused and a manual pause is preserved on foreground return.
    pauseWhenBackgrounded = false;
  }

  final GameSessionState sessionState;
  final List<StageOneBalloonSpawn> stageOneSpawns;
  final Map<int, BalloonComponent> _balloons = <int, BalloonComponent>{};
  final Set<BasicPopEffect> _popEffects = <BasicPopEffect>{};
  bool _shutdown = false;
  bool _hostWantsRunning = true;
  double _lastAppliedDelta = 0;

  bool get isShutdown => _shutdown;
  double get lastAppliedDelta => _lastAppliedDelta;
  int get activeBalloonCount => _balloons.length;
  int get activeParticleCount =>
      _popEffects.length * BasicPopEffect.particleCount;
  Iterable<BalloonComponent> get balloonComponents => _balloons.values;
  bool get isComponentStateSynchronized =>
      sessionState.matchesActiveComponentIds(_balloons.keys);

  @override
  Color backgroundColor() => const Color(0xFF14243A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (_shutdown) return;
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();
    await camera.viewport.add(
      GameDiagnosticsComponent(textProvider: _diagnosticsText),
    );
    await _startStageOne();
    if (_hostWantsRunning) {
      resumeEngine();
    } else {
      pauseEngine();
      sessionState.pause();
    }
  }

  @override
  void update(double dt) {
    if (_shutdown) return;
    final clampedDt = min(dt, BalloonComponent.maxUpdateDelta);
    _lastAppliedDelta = clampedDt;
    if (sessionState.phase == GameSessionPhase.stageClear) {
      if (_popEffects.isNotEmpty) {
        super.update(clampedDt);
      } else {
        // Process the effects' queued removals before stopping the loop.
        super.update(0);
        pauseEngine();
      }
      return;
    }
    if (!sessionState.isPlaying) return;
    super.update(clampedDt);
    sessionState.recordUpdate(clampedDt);
    if (sessionState.phase == GameSessionPhase.failed) pauseEngine();
  }

  Future<void> _startStageOne() async {
    final created = <BalloonComponent>[];
    final availableWidth = max(0.0, size.x - BalloonComponent.balloonWidth);
    final availableHeight = max(0.0, size.y - BalloonComponent.balloonHeight);
    for (final spawn in stageOneSpawns) {
      created.add(
        BalloonComponent(
          balloonId: spawn.id,
          position: Vector2(
            availableWidth * spawn.positionFactor.dx,
            availableHeight * spawn.positionFactor.dy,
          ),
          velocity: Vector2(spawn.velocity.dx, spawn.velocity.dy),
          playfieldSize: () => size,
          onPopRequested: _handlePopRequest,
          color: spawn.color,
        ),
      );
    }
    await world.addAll(created);
    _balloons
      ..clear()
      ..addEntries(
        created.map((balloon) => MapEntry(balloon.balloonId, balloon)),
      );
    sessionState.startStageOne(_balloons.keys);
  }

  bool _handlePopRequest(BalloonComponent balloon) {
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

  Future<void> restartStageOne({bool resume = true}) async {
    if (_shutdown) return;
    _hostWantsRunning = resume;
    for (final balloon in _balloons.values) {
      balloon.removeFromParent();
    }
    for (final effect in _popEffects) {
      effect.removeFromParent();
    }
    _balloons.clear();
    _popEffects.clear();
    processLifecycleEvents();
    await _startStageOne();
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
        'BALLOONS $activeBalloonCount / ${sessionState.remainingBalloons}  '
        'PARTICLES $activeParticleCount\n'
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
    if (sessionState.phase == GameSessionPhase.stageClear ||
        sessionState.phase == GameSessionPhase.failed) {
      return;
    }
    resumeEngine();
    sessionState.resume();
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
