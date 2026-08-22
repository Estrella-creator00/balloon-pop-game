import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:balloon_pop_game/balloon_skin_catalog.dart';
import 'package:balloon_pop_game/game_engine/components/balloon_component.dart';
import 'package:balloon_pop_game/game_engine/components/basic_pop_effect.dart';
import 'package:balloon_pop_game/game_engine/components/boss_balloon_component.dart';
import 'package:balloon_pop_game/game_engine/flame_game_page.dart';
import 'package:balloon_pop_game/game_engine/game_session_state.dart';
import 'package:balloon_pop_game/game_engine/poppop_engine_mode.dart';
import 'package:balloon_pop_game/game_engine/poppop_game.dart';
import 'package:balloon_pop_game/game_engine/rendering/basic_balloon_sprite_cache.dart';
import 'package:balloon_pop_game/game_engine/session/game_session_snapshot.dart';
import 'package:balloon_pop_game/game_engine/stages/flame_stage_definition.dart';
import 'package:balloon_pop_game/game_engine/stages/stage_balloon_spawner.dart';
import 'package:balloon_pop_game/game_engine/stages/stage_boss_spawner.dart';
import 'package:balloon_pop_game/gameplay/game_canvas.dart';
import 'package:balloon_pop_game/main.dart';
import 'package:balloon_pop_game/services/settings_service.dart';
import 'package:balloon_pop_game/storage/progress_storage.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    ProgressStorage.clear();
    ProgressStorage.setNicknameOnboardingCompleted(true);
    SettingsService.applyStoredPreferences();
  });

  test('engine query selects Flame preview only for the explicit value', () {
    expect(defaultPoppopEngineMode, PoppopEngineMode.production);
    expect(
      poppopEngineModeFromUri(Uri.parse('https://example.test/')),
      PoppopEngineMode.production,
    );
    expect(
      poppopEngineModeFromUri(
        Uri.parse('https://example.test/?engine=flame-preview'),
      ),
      PoppopEngineMode.flamePreview,
    );
    expect(
      poppopEngineModeFromUri(
        Uri.parse('https://example.test/?engine=unknown'),
      ),
      PoppopEngineMode.production,
    );
  });

  test('Flame Stage 1-9 definitions match production normal-stage rules', () {
    expect(
      flamePreviewStages.map((stage) => stage.stage),
      List<int>.generate(10, (index) => index + 1),
    );
    expect(
      flamePreviewStages.take(9).map((stage) => stage.balloonCount),
      List<int>.generate(9, (index) => index + 2),
    );
    for (final stage in flamePreviewStages.take(9)) {
      final production = StageConfig.forStage(stage.stage);
      expect(stage.balloonCount, production.balloonCount);
      expect(stage.timeLimitSeconds, production.duration.inSeconds);
      expect(
        stage.speedRange.minimum,
        closeTo(48 + stage.stage * 4.2, 0.0001),
      );
      expect(
        stage.speedRange.maximum,
        closeTo(80 + stage.stage * 4.2, 0.0001),
      );
      expect(stage.sizeRange.minimum, 78);
      expect(stage.sizeRange.maximum, 102);
      expect(stage.scoreRule.pointsPerBalloon, 0);
      expect(stage.scoreRule.remainingSecondMultiplier, 1);
      expect(stage.successCondition, StageSuccessCondition.allBalloonsPopped);
      expect(stage.failureCondition, StageFailureCondition.timeExpired);
      expect(stage.completion, StageCompletion.nextStage);
    }
  });

  test('Flame Stage 10 definition matches the production boss rule', () {
    final production = StageConfig.forStage(10);
    final definition = flamePreviewStage(10);
    final rule = definition.bossRule!;

    expect(definition.type, FlameStageType.boss);
    expect(definition.timeLimitSeconds, production.duration.inSeconds);
    expect(rule.bossCount, production.bossCount);
    expect(rule.maxHp, production.bossHp);
    expect(rule.initialSpeed, production.bossSpeed);
    expect(rule.maximumSpeed, closeTo(105 * math.pow(1.075, 9), 0.0001));
    expect(rule.minimumSize, 210);
    expect(rule.maximumSize, 270);
    expect(rule.hitSizeMultiplier, 0.965);
    expect(rule.hitSpeedMultiplier, 1.075);
    expect(rule.defeatPoints, 10);
    expect(rule.remainingSecondMultiplier, 1);
    expect(rule.fakeBossCount, 0);
    expect(definition.completion, StageCompletion.sectionClear);
  });

  test('stage spawner uses bounded in-playfield placement on narrow screens',
      () async {
    const spawner = StageBalloonSpawner(seed: 41);
    final cache = BasicBalloonSpriteCache();
    await cache.preload();
    addTearDown(cache.dispose);
    final playfield = Vector2(288, 320);
    final balloons = spawner.create(
      definition: flamePreviewStage(9),
      playfieldSize: () => playfield,
      idBase: 3000,
      onPopRequested: (_) => true,
      spriteForColor: cache.imageFor,
    );
    final restarted = spawner.create(
      definition: flamePreviewStage(9),
      playfieldSize: () => playfield,
      idBase: 9000,
      onPopRequested: (_) => true,
      spriteForColor: cache.imageFor,
    );

    expect(balloons, hasLength(10));
    expect(
      restarted.map((balloon) => balloon.position),
      balloons.map((balloon) => balloon.position),
    );
    expect(
      restarted.map((balloon) => balloon.velocity),
      balloons.map((balloon) => balloon.velocity),
    );
    expect(
      StageBalloonSpawner.maxPlacementAttemptsPerBalloon,
      lessThanOrEqualTo(20),
    );
    expect(
      balloons.map((balloon) => balloon.position.toString()).toSet(),
      hasLength(10),
    );
    for (final balloon in balloons) {
      expect(balloon.size.x, inInclusiveRange(78, 102));
      expect(balloon.size.y, balloon.size.x + 26);
      expect(balloon.sprite, same(cache.imageFor(balloon.color)));
      expect(balloon.position.x, greaterThanOrEqualTo(0));
      expect(balloon.position.y, greaterThanOrEqualTo(0));
      expect(
          balloon.position.x + balloon.size.x, lessThanOrEqualTo(playfield.x));
      expect(
          balloon.position.y + balloon.size.y, lessThanOrEqualTo(playfield.y));
    }
  });

  test('production default artwork is pre-rasterized once and reused',
      () async {
    expect(BalloonSkinCatalog.defaultSkin.assetPath, isNull);
    final cache = BasicBalloonSpriteCache();
    addTearDown(cache.dispose);

    await cache.preload();
    await cache.preload();

    expect(cache.isReady, isTrue);
    expect(cache.preloadCount, 1);
    expect(
        cache.imageCount, BalloonSkinCatalog.defaultSkin.colorPalette.length);
    final color = BalloonSkinCatalog.defaultSkin.colorPalette.first;
    expect(cache.imageFor(color), same(cache.imageFor(color)));

    final rule = flamePreviewStage(10).bossRule!;
    final initialSize = rule.initialSizeFor(320);
    await cache.prepareStage10Boss(initialSize: initialSize, rule: rule);
    await cache.prepareStage10Boss(initialSize: initialSize, rule: rule);
    expect(cache.bossPreloadCount, 1);
    expect(cache.bossImageCount, rule.maxHp);
    expect(
      cache.bossImageCount,
      lessThanOrEqualTo(BasicBalloonSpriteCache.maxBossSpriteCount),
    );
    expect(cache.bossImageForHp(10), same(cache.bossImageForHp(10)));
  });

  test('Stage 1 session atomically owns count score and clear phase', () {
    final session = GameSessionState();
    final snapshots = <GameSessionSnapshot>[];
    session.addListener(() => snapshots.add(session.snapshot));

    session.startNewGame(flamePreviewStages.first, const <int>[1, 2]);
    expect(session.remainingBalloons, 2);
    expect(session.phase, GameSessionPhase.playing);
    expect(session.score, 0);

    expect(session.popBalloon(1), BalloonPopResult.popped);
    expect(session.remainingBalloons, 1);
    expect(session.score, 0);
    expect(session.popBalloon(1), BalloonPopResult.ignored);
    expect(session.remainingBalloons, 1);

    expect(session.popBalloon(2), BalloonPopResult.stageCleared);
    expect(session.remainingBalloons, 0);
    expect(session.phase, GameSessionPhase.stageClear);
    expect(session.stageClearCount, 1);
    expect(session.lastClearBonus, 10);
    expect(session.score, 10);
    expect(session.popBalloon(2), BalloonPopResult.ignored);
    expect(session.stageClearCount, 1);
    expect(snapshots.last.remainingBalloons, 0);
    expect(snapshots.last.phase, GameSessionPhase.stageClear);
  });

  test('session advances Stage 1-10 and awards boss score once', () {
    final session = GameSessionState();
    var nextId = 1;
    var expectedScore = 0;
    for (var index = 0; index < 9; index++) {
      final definition = flamePreviewStages[index];
      final ids = List<int>.generate(
        definition.balloonCount,
        (_) => nextId++,
      );
      if (index == 0) {
        session.startNewGame(definition, ids);
      } else {
        session.beginNextStage(definition, ids);
      }
      for (final id in ids.take(ids.length - 1)) {
        expect(session.popBalloon(id), BalloonPopResult.popped);
      }
      final result = session.popBalloon(ids.last);
      expectedScore += definition.timeLimitSeconds;
      expect(session.score, expectedScore);
      expect(session.lastClearBonus, definition.timeLimitSeconds);
      expect(session.stageClearCount, index + 1);
      expect(
        result,
        BalloonPopResult.stageCleared,
      );
    }
    expect(session.stageClearCount, 9);
    expect(session.score, 135);

    final bossDefinition = flamePreviewStage(10);
    session.beginNextStage(
      bossDefinition,
      const <int>[],
      bossHpById: const <int, int>{100: 10},
    );
    expect(session.bossHp, 10);
    for (var hit = 0; hit < 9; hit++) {
      expect(session.hitBoss(100), BossHitResult.hit);
    }
    expect(session.score, 135);
    expect(session.hitBoss(100), BossHitResult.bossCleared);
    expect(session.bossHp, 0);
    expect(session.score, 153);
    expect(session.lastClearBonus, 8);
    expect(session.hitBoss(100), BossHitResult.ignored);
    expect(session.score, 153);
    expect(session.isBossClear, isTrue);
    session.completeSectionClear();
    expect(session.isSectionClear, isTrue);
    expect(session.snapshot.isSectionClear, isTrue);
    expect(session.stageClearCount, 10);

    session.startNewGame(flamePreviewStages[0], const <int>[10, 11]);
    session.recordUpdate(flamePreviewStages[0].timeLimitSeconds.toDouble());
    expect(session.isTimeOver, isTrue);
    expect(session.snapshot.isTimeOver, isTrue);
  });

  test('Stage 1 clock notifies only on displayed-second changes', () {
    final session = GameSessionState();
    session.startNewGame(flamePreviewStages.first, const <int>[1, 2]);
    var notifications = 0;
    session.addListener(() => notifications++);

    for (var frame = 0; frame < 10; frame++) {
      session.recordUpdate(0.05);
    }
    expect(session.secondsLeft, 10);
    expect(notifications, 0);

    session.recordUpdate(0.55);
    expect(session.secondsLeft, 9);
    expect(notifications, 1);

    for (var frame = 0; frame < 180; frame++) {
      session.recordUpdate(0.05);
    }
    expect(session.secondsLeft, 0);
    expect(session.phase, GameSessionPhase.failed);
  });

  test('remaining-time bonus uses the displayed second exactly once', () {
    final session = GameSessionState();
    session.startNewGame(flamePreviewStages.first, const <int>[1, 2]);
    session.recordUpdate(1.2);
    expect(session.secondsLeft, 9);

    expect(session.popBalloon(1), BalloonPopResult.popped);
    expect(session.score, 0);
    expect(session.popBalloon(2), BalloonPopResult.stageCleared);
    expect(session.lastClearBonus, 9);
    expect(session.score, 9);
    expect(session.popBalloon(2), BalloonPopResult.ignored);
    expect(session.score, 9);
  });

  test('BalloonComponent clamps dt, reflects on all bounds, and pops once',
      () async {
    final playfield = Vector2(300, 400);
    final sprite = await _createTestSprite();
    addTearDown(sprite.dispose);
    var popRequests = 0;
    final balloon = BalloonComponent(
      balloonId: 9,
      position: Vector2(100, 100),
      balloonSize: Vector2(80, 106),
      velocity: Vector2(40, 50),
      playfieldSize: () => playfield,
      onPopRequested: (_) {
        popRequests++;
        return true;
      },
      color: Colors.pink,
      sprite: sprite,
      floatPhase: 0,
      floatPower: 0,
    );

    balloon.update(1);
    expect(balloon.lastAppliedDelta, BalloonComponent.maxUpdateDelta);
    expect(balloon.position, Vector2(102, 102.5));

    balloon
      ..position.setValues(-1, -1)
      ..velocity.setValues(-40, -50)
      ..update(0);
    expect(balloon.position, Vector2.zero());
    expect(balloon.velocity.x, greaterThan(0));
    expect(balloon.velocity.y, greaterThan(0));

    balloon
      ..position.setValues(400, 500)
      ..velocity.setValues(40, 50)
      ..update(0);
    expect(balloon.position.x, playfield.x - balloon.size.x);
    expect(balloon.position.y, playfield.y - balloon.size.y);
    expect(balloon.velocity.x, lessThan(0));
    expect(balloon.velocity.y, lessThan(0));
    expect(balloon.requestPop(), isTrue);
    expect(balloon.requestPop(), isFalse);
    expect(popRequests, 1);
  });

  test('basic pop effect has a fixed particle cap and removes once', () {
    var completions = 0;
    late BasicPopEffect effect;
    effect = BasicPopEffect(
      center: Vector2.zero(),
      color: Colors.pink,
      onFinished: (_) => completions++,
    );

    expect(BasicPopEffect.particleCount, 6);
    for (var frame = 0; frame < 8; frame++) {
      effect.update(BalloonComponent.maxUpdateDelta);
    }
    expect(completions, 1);
  });

  testWidgets('default entry keeps the production game and renderer', (
    tester,
  ) async {
    await tester.pumpWidget(const PoppopAppEntry());
    await tester.pump();

    expect(defaultGameplayRendererMode, GameplayRendererMode.canvasPhase4A);
    expect(find.byType(BalloonGamePage), findsOneWidget);
    expect(find.byType(GameWidget<PoppopGame>), findsNothing);
  });

  testWidgets('Stage 1 starts with two synchronized non-overlapping balloons', (
    tester,
  ) async {
    final harness = await _pumpFlamePreview(tester);
    final balloons = harness.game.balloonComponents.toList();

    expect(balloons, hasLength(2));
    expect(harness.session.remainingBalloons, 2);
    expect(harness.game.isComponentStateSynchronized, isTrue);
    expect(find.textContaining('LEFT 2'), findsOneWidget);
    expect(balloons[0].playfieldBounds.overlaps(balloons[1].playfieldBounds),
        isFalse);
    expect(balloons[0].velocity, isNot(balloons[1].velocity));
    for (final balloon in balloons) {
      expect(balloon.position.x, greaterThanOrEqualTo(0));
      expect(balloon.position.y, greaterThanOrEqualTo(0));
      expect(balloon.position.x + balloon.size.x,
          lessThanOrEqualTo(harness.game.size.x));
      expect(balloon.position.y + balloon.size.y,
          lessThanOrEqualTo(harness.game.size.y));
    }
  });

  testWidgets('Flame Stage 1 fits a narrow iPhone-sized logical viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final harness = await _pumpFlamePreview(tester);

    expect(harness.game.activeBalloonCount, 2);
    expect(find.byKey(const ValueKey('flame-preview-pause-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('flame-preview-restart-button')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('flame-preview-exit-button')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('movement does not rebuild Flutter HUD every Flame frame', (
    tester,
  ) async {
    var hudBuilds = 0;
    final harness = await _pumpFlamePreview(
      tester,
      onHudBuild: () => hudBuilds++,
    );
    final balloon = harness.game.balloonComponents.first;
    final start = balloon.position.clone();
    final buildsBeforeMovement = hudBuilds;

    await tester.pump(const Duration(milliseconds: 300));

    expect(balloon.position, isNot(start));
    expect(hudBuilds, buildsBeforeMovement);
    await _pumpFlameFrames(tester, 20);
    expect(hudBuilds, greaterThan(buildsBeforeMovement));
  });

  testWidgets('same balloon rejects duplicate pointers and empty space', (
    tester,
  ) async {
    final harness = await _pumpFlamePreview(tester);
    final balloon = harness.game.balloonComponents.first;
    final target = _componentCenter(tester, balloon);

    final first = await tester.startGesture(target, pointer: 1);
    final second = await tester.startGesture(target, pointer: 2);
    await tester.pump();

    expect(harness.session.remainingBalloons, 1);
    expect(harness.session.score, 0);
    expect(harness.game.activeBalloonCount, 1);
    expect(harness.game.isComponentStateSynchronized, isTrue);
    expect(find.textContaining('LEFT 1'), findsOneWidget);
    await first.up();
    await second.up();

    final emptyLocal = _findEmptyPoint(harness.game);
    final gameOrigin = tester.getTopLeft(
      find.byKey(const ValueKey('flame-preview-game-widget')),
    );
    await tester.tapAt(gameOrigin + emptyLocal);
    await tester.pump();
    expect(harness.session.remainingBalloons, 1);
    expect(harness.session.score, 0);
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('two pointers clear Stage 1 once and create Stage 2 once', (
    tester,
  ) async {
    final harness = await _pumpFlamePreview(tester);
    final balloons = harness.game.balloonComponents.toList();
    final firstTarget = _componentCenter(tester, balloons[0]);
    final secondTarget = _componentCenter(tester, balloons[1]);

    final first = await tester.startGesture(firstTarget, pointer: 11);
    final second = await tester.startGesture(secondTarget, pointer: 12);
    await tester.pump();

    expect(harness.game.activeBalloonCount, 0);
    expect(harness.session.remainingBalloons, 0);
    expect(harness.session.score, 10);
    expect(harness.session.phase, GameSessionPhase.stageClear);
    expect(harness.session.stageClearCount, 1);
    expect(harness.game.isComponentStateSynchronized, isTrue);
    expect(harness.game.activeParticleCount,
        lessThanOrEqualTo(BasicPopEffect.particleCount * 2));
    expect(find.textContaining('STAGE CLEAR'), findsOneWidget);
    expect(find.textContaining('LEFT 0'), findsOneWidget);
    await first.up();
    await second.up();

    final updatesAtClear = harness.session.updateCount;
    await _pumpStageTransition(tester);
    expect(harness.session.updateCount, updatesAtClear);
    expect(harness.game.activeParticleCount, 0);
    expect(harness.session.stage, 2);
    expect(harness.game.activeBalloonCount, 3);
    expect(harness.session.remainingBalloons, 3);
    expect(harness.session.phase, GameSessionPhase.playing);
    expect(harness.session.stageClearCount, 1);
    expect(harness.game.isComponentStateSynchronized, isTrue);
    expect(find.textContaining('STAGE 2'), findsOneWidget);
    expect(balloons.every((balloon) => balloon.isRemoved), isTrue);
    expect(
      harness.game.world.children.whereType<BasicPopEffect>(),
      isEmpty,
    );

    final generationAtStageTwo = harness.game.componentGeneration;
    await _pumpFlameFrames(tester, 12);
    expect(harness.game.componentGeneration, generationAtStageTwo);
    expect(harness.game.activeBalloonCount, 3);
  });

  testWidgets('Stage 10 boss accepts multitouch without movement HUD rebuild', (
    tester,
  ) async {
    addTearDown(() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    var hudBuilds = 0;
    final harness = await _pumpFlamePreview(
      tester,
      onHudBuild: () => hudBuilds++,
      stageDefinitions: <FlameStageDefinition>[flamePreviewStage(10)],
    );
    final boss = harness.game.bossComponents.single;
    final rule = flamePreviewStage(10).bossRule!;

    expect(harness.session.stage, 10);
    expect(harness.session.bossHp, 10);
    expect(harness.game.activeBossCount, 1);
    expect(boss.diameter, inInclusiveRange(rule.minimumSize, rule.maximumSize));
    expect(boss.displayColor, rule.colorForHp(10));
    expect(harness.game.isComponentStateSynchronized, isTrue);

    final point = _bossComponentCenter(tester, boss);
    final first = await tester.startGesture(point, pointer: 101);
    final second = await tester.startGesture(point, pointer: 102);
    await tester.pump();
    expect(harness.session.bossHp, 8);
    expect(boss.visualHp, 8);
    expect(harness.session.score, 0);
    expect(harness.session.phase, GameSessionPhase.playing);
    await first.up();
    await second.up();

    final buildsBeforeMovement = hudBuilds;
    final positionBeforeMovement = boss.position.clone();
    await tester.pump(const Duration(milliseconds: 300));
    expect(boss.position, isNot(positionBeforeMovement));
    expect(hudBuilds, buildsBeforeMovement);

    await tester.tap(
      find.byKey(const ValueKey('flame-preview-pause-button')),
    );
    await tester.pump();
    final pausedPosition = boss.position.clone();
    final pausedSeconds = harness.session.secondsLeft;
    await tester.pump(const Duration(milliseconds: 300));
    expect(boss.position, pausedPosition);
    expect(harness.session.secondsLeft, pausedSeconds);
    await tester.tap(
      find.byKey(const ValueKey('flame-preview-pause-button')),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final inactivePosition = boss.position.clone();
    final inactiveSeconds = harness.session.secondsLeft;
    await tester.pump(const Duration(milliseconds: 300));
    expect(boss.position, inactivePosition);
    expect(harness.session.secondsLeft, inactiveSeconds);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(boss.position, isNot(inactivePosition));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(harness.game.isShutdown, isTrue);
    expect(harness.game.activeBossCount, 0);
    expect(harness.session.isDisposed, isTrue);
  });

  testWidgets('Stage 1 to 10 progresses once and ends in SECTION CLEAR', (
    tester,
  ) async {
    final harness = await _pumpFlamePreview(tester);
    var expectedScore = 0;
    expect(harness.game.spriteCache.preloadCount, 1);

    for (var stage = 1; stage <= 9; stage++) {
      final definition = flamePreviewStage(stage);
      expect(harness.session.stage, stage);
      expect(harness.game.activeBalloonCount, definition.balloonCount);
      expect(harness.session.remainingBalloons, definition.balloonCount);
      expect(harness.game.isComponentStateSynchronized, isTrue);
      await _popEveryBalloon(harness.game);
      if (stage == 9) {
        expect(harness.game.activeEffectCount, 10);
        expect(
          harness.game.activeParticleCount,
          BasicPopEffect.particleCount * 10,
        );
      }
      await tester.pump();
      expectedScore += definition.timeLimitSeconds;
      expect(harness.session.score, expectedScore);
      expect(harness.session.stageClearCount, stage);
      expect(harness.session.phase, GameSessionPhase.stageClear);
      await _pumpStageTransition(tester);
    }

    expect(harness.session.stage, 10);
    expect(harness.session.phase, GameSessionPhase.playing);
    expect(harness.session.stageClearCount, 9);
    expect(harness.session.score, 135);
    expect(harness.game.activeBalloonCount, 0);
    expect(harness.game.activeBossCount, 1);
    expect(harness.game.isComponentStateSynchronized, isTrue);
    expect(harness.game.spriteCache.preloadCount, 1);
    expect(harness.game.spriteCache.bossPreloadCount, 1);
    expect(harness.game.spriteCache.bossImageCount, 10);

    final boss = harness.game.bossComponents.single;
    final staleBoss = boss;
    final initialSize = boss.diameter;
    final initialColor = boss.displayColor;
    final initialSpeed = boss.velocity.length;
    for (var hit = 0; hit < 9; hit++) {
      expect(boss.requestHit(), isTrue);
      final expectedHp = 9 - hit;
      expect(boss.currentHp, expectedHp);
      expect(boss.visualHp, expectedHp);
      expect(
        boss.diameter,
        closeTo(
          stage10BossRule.sizeForHp(initialSize, expectedHp),
          0.0001,
        ),
      );
      expect(boss.displayColor, stage10BossRule.colorForHp(expectedHp));
    }
    expect(harness.session.bossHp, 1);
    expect(boss.visualHp, 1);
    expect(
      boss.diameter,
      closeTo(initialSize * math.pow(0.965, 9), 0.0001),
    );
    expect(
      boss.velocity.length,
      closeTo(initialSpeed * math.pow(1.075, 9), 0.0001),
    );
    expect(boss.displayColor, isNot(initialColor));
    expect(boss.requestHit(), isTrue);
    expect(boss.requestHit(), isFalse);
    expect(harness.session.phase, GameSessionPhase.bossClear);
    expect(harness.session.score, 153);
    expect(harness.session.stageClearCount, 10);
    expect(harness.game.activeBossCount, 0);
    expect(harness.game.isComponentStateSynchronized, isTrue);
    await tester.pump();
    expect(find.textContaining('BOSS CLEAR'), findsOneWidget);

    await _pumpFlameFrames(tester, 19);
    expect(harness.session.phase, GameSessionPhase.bossClear);
    await _pumpFlameFrames(tester, 2);
    await tester.pump();
    expect(harness.game.activeEffectCount, 0);
    expect(harness.game.paused, isTrue);
    expect(harness.session.phase, GameSessionPhase.sectionClear);
    expect(find.textContaining('SECTION CLEAR'), findsOneWidget);
    final generationAtClear = harness.game.componentGeneration;
    await _pumpFlameFrames(tester, 8);
    expect(harness.game.componentGeneration, generationAtClear);
    expect(harness.game.activeBalloonCount, 0);
    expect(harness.game.activeBossCount, 0);

    await tester.tap(
      find.byKey(const ValueKey('flame-preview-restart-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.session.stage, 1);
    expect(harness.session.phase, GameSessionPhase.playing);
    expect(harness.session.score, 0);
    expect(harness.session.remainingBalloons, 2);
    expect(harness.game.activeBalloonCount, 2);
    expect(harness.game.activeBossCount, 0);
    expect(harness.game.isComponentStateSynchronized, isTrue);
    expect(staleBoss.requestHit(), isFalse);
  });

  testWidgets('failure restart resets Stage 1 and rejects stale components', (
    tester,
  ) async {
    final harness = await _pumpFlamePreview(tester);
    final initialBalloons = harness.game.balloonComponents.toList();
    final staleBalloon = initialBalloons.first;
    expect(initialBalloons.last.requestPop(), isTrue);
    await tester.pump();
    expect(harness.session.score, 0);

    for (var frame = 0; frame < 310; frame++) {
      harness.game.update(BalloonComponent.maxUpdateDelta);
    }
    expect(harness.session.phase, GameSessionPhase.failed);
    expect(harness.session.isTimeOver, isTrue);
    await tester.pump();
    expect(find.textContaining('TIME UP'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('flame-preview-restart-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(harness.session.stage, 1);
    expect(harness.session.phase, GameSessionPhase.playing);
    expect(harness.session.score, 0);
    expect(harness.session.remainingBalloons, 2);
    expect(
        harness.session.secondsLeft, flamePreviewStages.first.timeLimitSeconds);
    expect(harness.game.activeBalloonCount, 2);
    expect(harness.game.activeEffectCount, 0);
    expect(harness.game.isComponentStateSynchronized, isTrue);
    expect(staleBalloon.requestPop(), isFalse);
    expect(harness.session.remainingBalloons, 2);
  });

  testWidgets('Flame preview creates one game without production game loop', (
    tester,
  ) async {
    var creationCount = 0;
    late GameSessionState session;
    late PoppopGame game;

    await tester.pumpWidget(
      PoppopAppEntry(
        engineMode: PoppopEngineMode.flamePreview,
        flameGameFactory: (createdSession) {
          creationCount++;
          session = createdSession;
          return game = PoppopGame(createdSession);
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GameWidget<PoppopGame>), findsOneWidget);
    expect(find.byKey(const ValueKey('flame-preview-title')), findsOneWidget);
    expect(find.byType(BalloonGamePage), findsNothing);
    expect(creationCount, 1);
    expect(session.updateCount, greaterThan(0));

    final beforePause = session.updateCount;
    final secondsBeforePause = session.secondsLeft;
    final positionBeforePause = game.balloonComponents.first.position.clone();
    await tester.tap(
      find.byKey(const ValueKey('flame-preview-pause-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(session.updateCount, beforePause);
    expect(session.secondsLeft, secondsBeforePause);
    expect(game.balloonComponents.first.position, positionBeforePause);
    expect(game.paused, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('flame-preview-pause-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(session.updateCount, greaterThan(beforePause));
    expect(game.balloonComponents.first.position, isNot(positionBeforePause));
    expect(game.paused, isFalse);
    expect(creationCount, 1);

    await tester.tap(find.byKey(const ValueKey('flame-preview-exit-button')));
    await tester.pump();
    final countAtExit = session.updateCount;
    await tester.pump(const Duration(milliseconds: 200));

    expect(game.isShutdown, isTrue);
    expect(session.isDisposed, isTrue);
    expect(session.updateCount, countAtExit);
    expect(find.byType(GameWidget<PoppopGame>), findsNothing);
    expect(find.byType(BalloonGamePage), findsOneWidget);
  });

  testWidgets('lifecycle pause stops updates and preserves manual pause', (
    tester,
  ) async {
    late GameSessionState session;
    late PoppopGame game;

    addTearDown(() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await tester.pumpWidget(
      PoppopAppEntry(
        engineMode: PoppopEngineMode.flamePreview,
        flameGameFactory: (createdSession) {
          session = createdSession;
          return game = PoppopGame(createdSession);
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.inactive,
    );
    await tester.pump();
    final countWhileInactive = session.updateCount;
    final positionWhileInactive = game.balloonComponents.first.position.clone();
    await tester.pump(const Duration(milliseconds: 200));
    expect(session.updateCount, countWhileInactive);
    expect(game.balloonComponents.first.position, positionWhileInactive);
    expect(game.paused, isTrue);

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(session.isRunning, isTrue);
    expect(session.updateCount, greaterThan(countWhileInactive));
    expect(game.balloonComponents.first.position, isNot(positionWhileInactive));

    await tester.tap(
      find.byKey(const ValueKey('flame-preview-pause-button')),
    );
    await tester.pump();
    final manuallyPausedCount = session.updateCount;
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(session.updateCount, manuallyPausedCount);
    expect(game.paused, isTrue);
  });

  test('disposed session ignores late game updates', () async {
    final session = GameSessionState();
    final game = PoppopGame(session);
    game.onGameResize(Vector2(320, 480));
    await game.onLoad();
    game.update(1 / 60);
    expect(session.updateCount, 1);

    game.shutdown();
    expect(game.activeBalloonCount, 0);
    expect(session.remainingBalloons, 0);
    expect(session.phase, GameSessionPhase.ready);
    expect(game.isComponentStateSynchronized, isTrue);
    session.dispose();
    game.update(1 / 60);

    expect(session.updateCount, 1);
    expect(session.isDisposed, isTrue);
  });

  test('time expiry stops Stage 1 in an explicit failed state', () async {
    final session = GameSessionState();
    final game = PoppopGame(session);
    game.onGameResize(Vector2(320, 480));
    await game.onLoad();

    for (var frame = 0; frame < 310; frame++) {
      game.update(BalloonComponent.maxUpdateDelta);
    }

    expect(session.secondsLeft, 0);
    expect(session.phase, GameSessionPhase.failed);
    expect(game.paused, isTrue);
    expect(game.activeBalloonCount, 2);
  });

  test('Stage 10 boss turns, reflects, times out, and is cleaned up', () async {
    final session = GameSessionState();
    final game = PoppopGame(
      session,
      stageDefinitions: <FlameStageDefinition>[flamePreviewStage(10)],
      stageBossSpawner: const StageBossSpawner(seed: 77),
    );
    game.onGameResize(Vector2(320, 480));
    await game.onLoad();
    final boss = game.bossComponents.single;
    final initialVelocity = boss.velocity.clone();

    for (var frame = 0; frame < 14; frame++) {
      game.update(BalloonComponent.maxUpdateDelta);
    }
    expect(boss.velocity, isNot(initialVelocity));
    expect(
      boss.velocity.length,
      closeTo(stage10BossRule.initialSpeed, 0.0001),
    );

    boss
      ..position.setValues(-1, -1)
      ..velocity.setValues(-10, -10)
      ..update(0);
    expect(boss.position, Vector2.zero());
    expect(boss.velocity.x, greaterThan(0));
    expect(boss.velocity.y, greaterThan(0));

    for (var frame = 0; frame < 143; frame++) {
      game.update(BalloonComponent.maxUpdateDelta);
    }
    expect(session.phase, GameSessionPhase.playing);
    expect(boss.requestHit(), isTrue);
    expect(game.activeEffectCount, 1);
    game.processLifecycleEvents();

    while (session.phase == GameSessionPhase.playing) {
      game.update(BalloonComponent.maxUpdateDelta);
    }
    expect(session.phase, GameSessionPhase.failed);
    expect(session.bossHp, 0);
    expect(game.activeBossCount, 0);
    expect(game.activeEffectCount, 0);
    expect(game.isComponentStateSynchronized, isTrue);
    expect(boss.requestHit(), isFalse);
    game.shutdown();
  });
}

class _FlamePreviewHarness {
  const _FlamePreviewHarness(this.game, this.session);

  final PoppopGame game;
  final GameSessionState session;
}

Future<_FlamePreviewHarness> _pumpFlamePreview(
  WidgetTester tester, {
  VoidCallback? onHudBuild,
  List<FlameStageDefinition> stageDefinitions = flamePreviewStages,
}) async {
  late PoppopGame game;
  late GameSessionState session;
  await tester.pumpWidget(
    MaterialApp(
      home: FlameGamePage(
        onExit: () {},
        onHudBuild: onHudBuild,
        gameFactory: (createdSession) {
          session = createdSession;
          return game = PoppopGame(
            createdSession,
            stageDefinitions: stageDefinitions,
          );
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return _FlamePreviewHarness(game, session);
}

Offset _componentCenter(WidgetTester tester, BalloonComponent component) {
  final gameOrigin = tester.getTopLeft(
    find.byKey(const ValueKey('flame-preview-game-widget')),
  );
  return gameOrigin +
      Offset(
        component.position.x + component.size.x / 2,
        component.position.y + component.size.y / 2,
      );
}

Offset _bossComponentCenter(
  WidgetTester tester,
  BossBalloonComponent component,
) {
  final gameOrigin = tester.getTopLeft(
    find.byKey(const ValueKey('flame-preview-game-widget')),
  );
  return gameOrigin +
      Offset(
        component.position.x + component.size.x / 2,
        component.position.y + component.size.y / 2,
      );
}

Offset _findEmptyPoint(PoppopGame game) {
  for (final candidate in const <Offset>[
    Offset(8, 8),
    Offset(150, 20),
    Offset(20, 240),
    Offset(150, 240),
  ]) {
    if (game.balloonComponents
        .every((balloon) => !balloon.playfieldBounds.contains(candidate))) {
      return candidate;
    }
  }
  throw StateError('No deterministic empty test point was available.');
}

Future<void> _pumpFlameFrames(WidgetTester tester, int count) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _popEveryBalloon(PoppopGame game) async {
  final balloons = game.balloonComponents.toList();
  for (final balloon in balloons) {
    expect(balloon.requestPop(), isTrue);
  }
}

Future<void> _pumpStageTransition(WidgetTester tester) async {
  await _pumpFlameFrames(tester, 9);
  await tester.pump();
}

Future<ui.Image> _createTestSprite() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xFFFF5C8A),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(2, 2);
  picture.dispose();
  return image;
}
