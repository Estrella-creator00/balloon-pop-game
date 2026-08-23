import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../balloon_skin_catalog.dart';
import 'components/balloon_component.dart';
import 'components/basic_pop_effect.dart';
import 'components/boss_balloon_component.dart';
import 'components/game_diagnostics_component.dart';
import 'components/legendary_background_component.dart';
import 'components/legendary_burst_effect.dart';
import 'game_session_state.dart';
import 'integration/flame_integration_contract.dart';
import 'legendary/flame_preview_skin.dart';
import 'legendary/flame_skin_runtime.dart';
import 'legendary/legendary_sprite_cache.dart';
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
    this.initialSkin = FlamePreviewSkin.basic,
    this.stageSpawner = const StageBalloonSpawner(),
    this.stageBossSpawner = const StageBossSpawner(),
    this.stage30SwapRoll,
    this.legendaryImageLoader,
    this.onGameplayFeedback,
    this.showDiagnostics = true,
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
  final FlamePreviewSkin initialSkin;
  final StageBalloonSpawner stageSpawner;
  final StageBossSpawner stageBossSpawner;
  final double Function()? stage30SwapRoll;
  final LegendaryImageLoader? legendaryImageLoader;
  final FlameGameplayFeedbackCallback? onGameplayFeedback;
  final bool showDiagnostics;
  final BasicBalloonSpriteCache spriteCache;
  final Map<int, BalloonComponent> _balloons = <int, BalloonComponent>{};
  final Map<int, BossBalloonComponent> _bosses = <int, BossBalloonComponent>{};
  final Set<BasicPopEffect> _popEffects = <BasicPopEffect>{};
  final Set<LegendaryBurstEffect> _legendaryEffects = <LegendaryBurstEffect>{};
  final Set<LegendaryBackgroundPulseComponent> _backgroundPulses =
      <LegendaryBackgroundPulseComponent>{};
  final Random _random = Random(30130);
  late final LegendaryEffectFactory _legendaryEffectFactory =
      LegendaryEffectFactory(random: _random);
  late final FlameSkinRuntime skinRuntime = FlameSkinRuntime(
    basicCache: spriteCache,
    initialSkin: initialSkin,
    legendaryImageLoader: legendaryImageLoader,
  );
  LegendaryBackgroundComponent? _legendaryBackground;
  bool _shutdown = false;
  bool _hostWantsRunning = true;
  bool _transitionInFlight = false;
  bool _restartInFlight = false;
  double _transitionElapsed = 0;
  double _lastAppliedDelta = 0;
  int _operationEpoch = 0;
  int _componentGeneration = 0;
  Vector2? _lastEffectOrigin;

  bool get isShutdown => _shutdown;
  bool get isStageTransitionInFlight => _transitionInFlight;
  double get lastAppliedDelta => _lastAppliedDelta;
  int get activeBalloonCount => _balloons.length;
  int get activeBossCount => _bosses.length;
  int get activeEffectCount => _popEffects.length + _legendaryEffects.length;
  int get activeParticleCount =>
      _popEffects.fold(0, (sum, effect) => sum + effect.activeParticleCount) +
      _legendaryEffects.fold(0, (sum, effect) => sum + effect.particleCount);
  bool get isBackgroundEffectActive => _backgroundPulses.isNotEmpty;
  bool get hasLegendaryBackground => _legendaryBackground != null;
  int get activeCacheImageCount => skinRuntime.imageCount;
  int get activeCacheRgbaBytes => skinRuntime.estimatedRgbaBytes;
  FlamePreviewSkin get selectedSkin => skinRuntime.skin;
  int get componentGeneration => _componentGeneration;
  Iterable<BalloonComponent> get balloonComponents => _balloons.values;
  Iterable<BossBalloonComponent> get bossComponents => _bosses.values;
  Iterable<BasicPopEffect> get basicPopEffects => _popEffects;
  Vector2? get lastEffectOrigin => _lastEffectOrigin?.clone();
  bool get isComponentStateSynchronized =>
      sessionState.matchesActiveComponentIds(_balloons.keys) &&
      sessionState.matchesActiveBossComponentIds(_bosses.keys);

  @override
  Color backgroundColor() => const Color(0xFF14243A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (_shutdown) return;
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();
    if (showDiagnostics) {
      await camera.viewport
          .add(GameDiagnosticsComponent(textProvider: _diagnosticsText));
    }
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
        if (_popEffects.isNotEmpty ||
            _legendaryEffects.isNotEmpty ||
            _backgroundPulses.isNotEmpty) {
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
      case GameSessionPhase.loading:
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
    pauseEngine();
    sessionState.beginLoading();
    _removeGameplayComponents();
    _transitionElapsed = 0;
    final generation = ++_componentGeneration;
    final balloons = <BalloonComponent>[];
    final bosses = <BossBalloonComponent>[];
    final bossRule = definition.bossRule;
    final bossInitialSize =
        bossRule == null ? 0.0 : bossRule.initialSizeFor(min(size.x, size.y));
    try {
      await skinRuntime.prepareForStage(
        definition,
        bossInitialSize: bossInitialSize,
      );
    } catch (_) {
      if (_shutdown || operation != _operationEpoch) return;
      rethrow;
    }
    if (_shutdown || operation != _operationEpoch) return;
    _installLegendaryBackground();
    if (definition.isBoss) {
      bosses.addAll(stageBossSpawner.create(
        definition: definition,
        generation: generation,
        idBase: generation * 1000,
        playfieldSize: () => size,
        readHp: sessionState.bossHpFor,
        readIsFake: sessionState.isFakeBoss,
        onHitRequested: _handleBossHitRequest,
        spriteForHp: skinRuntime.bossFrame,
        palette: skinRuntime.palette,
        preserveSpriteAspectRatio: skinRuntime.preserveSpriteAspectRatio,
        useSourceAspectGeometry: skinRuntime.usesSourceAspectGeometry,
        breatheIdle: skinRuntime.breathes,
        ghostIdle: skinRuntime.ghostIdle,
        baseSpriteOpacity: skinRuntime.baseSpriteOpacity,
        drawHealthBarSeparately: skinRuntime.usesSeparateBossHealthBar,
        fakeSpriteOpacity: skinRuntime.fakeOpacity,
        visualVariantCount: skinRuntime.visualVariantCount,
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
        spriteResolver: skinRuntime.balloonFrame,
        palette: skinRuntime.palette,
        preserveSpriteAspectRatio: skinRuntime.preserveSpriteAspectRatio,
        useSourceAspectGeometry: skinRuntime.usesSourceAspectGeometry,
        breatheIdle: skinRuntime.breathes,
        ghostIdle: skinRuntime.ghostIdle,
        baseSpriteOpacity: skinRuntime.baseSpriteOpacity,
        fakeSpriteOpacity: skinRuntime.fakeOpacity,
        visualVariantCount: skinRuntime.visualVariantCount,
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
    if (definition.isBoss) {
      onGameplayFeedback?.call(FlameGameplayFeedbackEvent(
        kind: FlameGameplayFeedbackKind.bossReady,
        skinId: selectedSkin.queryValue,
      ));
    }
  }

  void _installLegendaryBackground() {
    final cache = skinRuntime.legendaryCache;
    if (cache == null) return;
    final background = LegendaryBackgroundComponent(cache.backgroundImage);
    _legendaryBackground = background;
    world.add(background);
  }

  bool _handleBalloonHitRequest(BalloonComponent balloon) {
    if (_shutdown ||
        !identical(_balloons[balloon.balloonId], balloon) ||
        balloon.generation != sessionState.generation) {
      return false;
    }
    if (!balloon.isFake &&
        balloon.currentHp == 1 &&
        skinRuntime.exitAnimation == BalloonExitAnimationType.kickAway) {
      return _beginKickExit(balloon);
    }
    final result = sessionState.hitBalloon(balloon.balloonId);
    if (result == BalloonHitResult.ignored) return false;
    _reportBalloonFeedback(result);
    final center = skinRuntime.usesSourceAspectGeometry
        ? Vector2(
            balloon.visualCenterInParent.dx,
            balloon.visualCenterInParent.dy,
          )
        : balloon.position + balloon.size / 2;
    if (result != BalloonHitResult.fakeHit) {
      _addHitEffect(
        center,
        balloon.color,
        balloon.size.x,
        result == BalloonHitResult.hit
            ? LegendaryHitKind.firstHit
            : LegendaryHitKind.finalPop,
        boss: false,
      );
    } else {
      _addFakeEffect(center, balloon.color);
    }
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
    _reportBossFeedback(result);
    final center = skinRuntime.usesSourceAspectGeometry
        ? Vector2(
            boss.visualCenterInParent.dx,
            boss.visualCenterInParent.dy,
          )
        : boss.position + boss.size / 2;
    if (result != BossHitResult.fakeHit) {
      _addHitEffect(
        center,
        boss.color,
        boss.size.x,
        result == BossHitResult.hit
            ? LegendaryHitKind.firstHit
            : LegendaryHitKind.bossPop,
        boss: true,
      );
    } else {
      _addFakeEffect(center, boss.displayColor);
    }
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

  void _reportBalloonFeedback(BalloonHitResult result) {
    final kind = switch (result) {
      BalloonHitResult.hit => FlameGameplayFeedbackKind.balloonFirstHit,
      BalloonHitResult.popped ||
      BalloonHitResult.stageCleared =>
        FlameGameplayFeedbackKind.balloonPop,
      BalloonHitResult.fakeHit => FlameGameplayFeedbackKind.fakeHit,
      BalloonHitResult.ignored => null,
    };
    if (kind != null) {
      onGameplayFeedback?.call(FlameGameplayFeedbackEvent(
        kind: kind,
        skinId: selectedSkin.queryValue,
      ));
    }
  }

  void _reportBossFeedback(BossHitResult result) {
    final kind = switch (result) {
      BossHitResult.hit => FlameGameplayFeedbackKind.bossHit,
      BossHitResult.bossDefeated => FlameGameplayFeedbackKind.bossDefeated,
      BossHitResult.bossCleared => FlameGameplayFeedbackKind.bossClear,
      BossHitResult.fakeHit => FlameGameplayFeedbackKind.fakeHit,
      BossHitResult.ignored => null,
    };
    if (kind != null) {
      onGameplayFeedback?.call(FlameGameplayFeedbackEvent(
        kind: kind,
        skinId: selectedSkin.queryValue,
      ));
    }
  }

  BossBalloonComponent? _closestStage30Boss(Vector2 point) {
    BossBalloonComponent? closest;
    var closestDistance = double.infinity;
    for (final candidate in _bosses.values) {
      final hitBounds = skinRuntime.usesSourceAspectGeometry
          ? candidate.visualBoundsInParent
          : candidate.playfieldBounds;
      if (!hitBounds.contains(Offset(point.x, point.y))) {
        continue;
      }
      final center = skinRuntime.usesSourceAspectGeometry
          ? candidate.visualCenterInParent
          : Offset(
              candidate.position.x + candidate.size.x / 2,
              candidate.position.y + candidate.size.x / 2,
            );
      final dx = point.x - center.dx;
      final dy = point.y - center.dy;
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

  void _addHitEffect(
      Vector2 center, Color color, double sourceSize, LegendaryHitKind kind,
      {required bool boss}) {
    _lastEffectOrigin = center.clone();
    final definition = skinRuntime.legendaryDefinition;
    final cache = skinRuntime.legendaryCache;
    if (definition == null || cache == null) {
      if (selectedSkin.usesCatalogImage) {
        final catalog = skinRuntime.catalogDefinition;
        if (kind == LegendaryHitKind.firstHit && !boss) return;
        _addCatalogEffect(
          center,
          color,
          catalog.popEffectType,
          big: boss && kind == LegendaryHitKind.bossPop,
        );
      } else {
        _addEffect(center, color);
      }
      return;
    }
    while (_legendaryEffects.length >= 12) {
      final oldest = _legendaryEffects.first;
      _legendaryEffects.remove(oldest);
      oldest.removeFromParent();
    }
    final effect = _legendaryEffectFactory.create(
      definition: definition,
      cache: cache,
      kind: kind,
      center: center,
      sourceSize: sourceSize,
      color: color,
      playfieldSize: size,
      onFinished: _handleLegendaryEffectFinished,
    );
    _legendaryEffects.add(effect);
    world.add(effect);
    if (selectedSkin == FlamePreviewSkin.gemi) {
      _addBackgroundPulse(kind == LegendaryHitKind.firstHit ? 0.55 : 1);
    }
  }

  void _addCatalogEffect(
    Vector2 center,
    Color color,
    BalloonPopEffectType type, {
    required bool big,
  }) {
    while (_popEffects.length >= 12) {
      final oldest = _popEffects.first;
      _popEffects.remove(oldest);
      oldest.removeFromParent();
    }
    final effect = BasicPopEffect(
      center: center,
      color: color,
      onFinished: _handleEffectFinished,
      effectType: type,
      themed: true,
      big: big,
    );
    _popEffects.add(effect);
    world.add(effect);
  }

  void _addFakeEffect(Vector2 center, Color color) {
    if (selectedSkin.usesCatalogImage) {
      _addCatalogEffect(
        center,
        color,
        skinRuntime.catalogDefinition.popEffectType,
        big: false,
      );
    } else {
      _addEffect(center, color);
    }
  }

  bool _beginKickExit(BalloonComponent balloon) {
    final center = balloon.position + balloon.size / 2;
    final screenCenter = size / 2;
    var direction = center - screenCenter;
    if (direction.length2 < 0.001) direction = Vector2(1, -0.4);
    direction.normalize();
    final distance = size.length + balloon.size.length * 2;
    final accepted = balloon.beginKickExit(
      velocity: direction * (distance / 0.24),
      onFinished: _completeKickExit,
    );
    if (accepted) {
      onGameplayFeedback?.call(FlameGameplayFeedbackEvent(
        kind: FlameGameplayFeedbackKind.kickExitStarted,
        skinId: selectedSkin.queryValue,
      ));
    }
    return accepted;
  }

  void _completeKickExit(BalloonComponent balloon) {
    if (_shutdown ||
        !identical(_balloons[balloon.balloonId], balloon) ||
        balloon.generation != sessionState.generation) {
      return;
    }
    final result = sessionState.hitBalloon(balloon.balloonId);
    if (result != BalloonHitResult.popped &&
        result != BalloonHitResult.stageCleared) {
      return;
    }
    _balloons.remove(balloon.balloonId);
    balloon.markRemoved();
    balloon.removeFromParent();
    if (result == BalloonHitResult.stageCleared) _removeFakeBalloons();
  }

  void _addBackgroundPulse(double strength) {
    final definition = skinRuntime.legendaryDefinition;
    final cache = skinRuntime.legendaryCache;
    if (definition == null || cache == null) return;
    final glowPath = definition.effectAssets.keys.where(
      (path) => path.contains('crack_glow'),
    );
    if (glowPath.isEmpty) return;
    for (final pulse in _backgroundPulses) {
      pulse.removeFromParent();
    }
    _backgroundPulses.clear();
    final pulse = LegendaryBackgroundPulseComponent(
      image: cache.imageForAsset(glowPath.first),
      strength: strength,
      onFinished: _handleBackgroundPulseFinished,
    );
    _backgroundPulses.add(pulse);
    world.add(pulse);
  }

  void _handleEffectFinished(BasicPopEffect effect) =>
      _popEffects.remove(effect);

  void _handleLegendaryEffectFinished(LegendaryBurstEffect effect) =>
      _legendaryEffects.remove(effect);

  void _handleBackgroundPulseFinished(
    LegendaryBackgroundPulseComponent pulse,
  ) =>
      _backgroundPulses.remove(pulse);

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

  Future<void> switchSkin(
    FlamePreviewSkin skin, {
    bool resume = true,
  }) async {
    if (_shutdown || _restartInFlight || selectedSkin == skin) return;
    _restartInFlight = true;
    _hostWantsRunning = resume;
    pauseEngine();
    final operation = ++_operationEpoch;
    final stage = sessionState.stage.clamp(1, 30);
    try {
      _removeGameplayComponents();
      await skinRuntime.switchSkin(skin);
      final definition = stageDefinitions.firstWhere(
        (candidate) => candidate.stage == stage,
        orElse: () => stageDefinitions.first,
      );
      await _installStage(
        definition,
        operation: operation,
        resetSession: true,
      );
      _applyHostRunIntent();
    } finally {
      if (operation == _operationEpoch) _restartInFlight = false;
    }
  }

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
    for (final effect in _legendaryEffects) {
      effect.removeFromParent();
    }
    for (final pulse in _backgroundPulses) {
      pulse.removeFromParent();
    }
    _legendaryBackground?.removeFromParent();
    _legendaryBackground = null;
    _balloons.clear();
    _bosses.clear();
    _popEffects.clear();
    _legendaryEffects.clear();
    _backgroundPulses.clear();
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
      'SKIN ${selectedSkin.label}  EFFECTS $activeEffectCount/$activeParticleCount  '
      'BG ${isBackgroundEffectActive ? 'ACTIVE' : 'IDLE'}\n'
      'CACHE $activeCacheImageCount  ${(activeCacheRgbaBytes / 1048576).toStringAsFixed(1)}MB  '
      'PHASE ${sessionState.phase.name}';

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
        sessionState.phase == GameSessionPhase.bossReady ||
        sessionState.phase == GameSessionPhase.loading) {
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
    skinRuntime.dispose();
    sessionState.endSession();
  }

  @override
  void onDispose() {
    shutdown();
    super.onDispose();
  }
}
