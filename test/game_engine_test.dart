import 'package:balloon_pop_game/game_engine/components/balloon_component.dart';
import 'package:balloon_pop_game/game_engine/components/basic_pop_effect.dart';
import 'package:balloon_pop_game/game_engine/flame_game_page.dart';
import 'package:balloon_pop_game/game_engine/game_session_state.dart';
import 'package:balloon_pop_game/game_engine/poppop_engine_mode.dart';
import 'package:balloon_pop_game/game_engine/poppop_game.dart';
import 'package:balloon_pop_game/game_engine/session/game_session_snapshot.dart';
import 'package:balloon_pop_game/game_engine/stages/flame_stage_definition.dart';
import 'package:balloon_pop_game/game_engine/stages/stage_balloon_spawner.dart';
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

  test('Stage 1-3 rules are defined once in the Flame stage catalog', () {
    expect(flamePreviewStages.map((stage) => stage.stage), <int>[1, 2, 3]);
    expect(
      flamePreviewStages.map((stage) => stage.balloonCount),
      <int>[2, 3, 4],
    );
    expect(
      flamePreviewStages.take(2).every(
            (stage) => stage.completion == StageCompletion.nextStage,
          ),
      isTrue,
    );
    expect(
      flamePreviewStages.last.completion,
      StageCompletion.gameClear,
    );
    for (final stage in flamePreviewStages) {
      expect(stage.successCondition, StageSuccessCondition.allBalloonsPopped);
      expect(stage.failureCondition, StageFailureCondition.timeExpired);
      expect(stage.timeLimitSeconds, greaterThan(0));
    }
  });

  test('stage spawner uses bounded in-playfield placement on narrow screens',
      () {
    const spawner = StageBalloonSpawner(seed: 41);
    final playfield = Vector2(288, 320);
    final balloons = spawner.create(
      definition: flamePreviewStages.last,
      playfieldSize: playfield,
      idBase: 3000,
      onPopRequested: (_) => true,
    );
    final restarted = spawner.create(
      definition: flamePreviewStages.last,
      playfieldSize: playfield,
      idBase: 9000,
      onPopRequested: (_) => true,
    );

    expect(balloons, hasLength(4));
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
    for (final balloon in balloons) {
      expect(balloon.position.x, greaterThanOrEqualTo(0));
      expect(balloon.position.y, greaterThanOrEqualTo(0));
      expect(
          balloon.position.x + balloon.size.x, lessThanOrEqualTo(playfield.x));
      expect(
          balloon.position.y + balloon.size.y, lessThanOrEqualTo(playfield.y));
    }
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
    expect(session.score, GameSessionState.scorePerBalloon);
    expect(session.popBalloon(1), BalloonPopResult.ignored);
    expect(session.remainingBalloons, 1);

    expect(session.popBalloon(2), BalloonPopResult.stageCleared);
    expect(session.remainingBalloons, 0);
    expect(session.phase, GameSessionPhase.stageClear);
    expect(session.stageClearCount, 1);
    expect(session.score, GameSessionState.scorePerBalloon * 2);
    expect(session.popBalloon(2), BalloonPopResult.ignored);
    expect(session.stageClearCount, 1);
    expect(snapshots.last.remainingBalloons, 0);
    expect(snapshots.last.phase, GameSessionPhase.stageClear);
  });

  test('session advances stages and derives clear and time-over states', () {
    final session = GameSessionState();
    session.startNewGame(flamePreviewStages[0], const <int>[1, 2]);
    session.popBalloon(1);
    session.popBalloon(2);
    expect(session.isStageClear, isTrue);
    session.pause();
    expect(session.isPaused, isTrue);
    session.resume();
    expect(session.isStageClear, isTrue);

    session.beginNextStage(flamePreviewStages[1], const <int>[3, 4, 5]);
    expect(session.stage, 2);
    expect(session.remainingBalloons, 3);
    expect(session.score, GameSessionState.scorePerBalloon * 2);
    for (final id in const <int>[3, 4, 5]) {
      session.popBalloon(id);
    }

    session.beginNextStage(flamePreviewStages[2], const <int>[6, 7, 8, 9]);
    for (final id in const <int>[6, 7, 8]) {
      session.popBalloon(id);
    }
    expect(session.popBalloon(9), BalloonPopResult.gameCleared);
    expect(session.isGameClear, isTrue);
    expect(session.snapshot.isGameClear, isTrue);
    expect(session.stageClearCount, 3);

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
    expect(session.secondsLeft, 15);
    expect(notifications, 0);

    session.recordUpdate(0.55);
    expect(session.secondsLeft, 14);
    expect(notifications, 1);

    for (var frame = 0; frame < 280; frame++) {
      session.recordUpdate(0.05);
    }
    expect(session.secondsLeft, 0);
    expect(session.phase, GameSessionPhase.failed);
  });

  test('BalloonComponent clamps dt, reflects on all bounds, and pops once', () {
    final playfield = Vector2(300, 400);
    var popRequests = 0;
    final balloon = BalloonComponent(
      balloonId: 9,
      position: Vector2(100, 100),
      velocity: Vector2(40, 50),
      playfieldSize: () => playfield,
      onPopRequested: (_) {
        popRequests++;
        return true;
      },
      color: Colors.pink,
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
    expect(balloons[0].velocity.x.sign, isNot(balloons[1].velocity.x.sign));
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
    expect(harness.session.score, GameSessionState.scorePerBalloon);
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
    expect(harness.session.score, GameSessionState.scorePerBalloon);
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
    expect(harness.session.score, GameSessionState.scorePerBalloon * 2);
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

  testWidgets('Stage 1 to 3 progresses once and ends in Game Clear', (
    tester,
  ) async {
    final harness = await _pumpFlamePreview(tester);

    await _popEveryBalloon(harness.game);
    expect(harness.session.phase, GameSessionPhase.stageClear);
    await _pumpStageTransition(tester);
    expect(harness.session.stage, 2);
    expect(harness.game.activeBalloonCount, 3);
    expect(harness.game.isComponentStateSynchronized, isTrue);

    await _popEveryBalloon(harness.game);
    expect(harness.session.phase, GameSessionPhase.stageClear);
    await _pumpStageTransition(tester);
    expect(harness.session.stage, 3);
    expect(harness.game.activeBalloonCount, 4);
    expect(harness.game.isComponentStateSynchronized, isTrue);

    await _popEveryBalloon(harness.game);
    await tester.pump();
    expect(harness.session.stage, 3);
    expect(harness.session.phase, GameSessionPhase.gameClear);
    expect(harness.session.isGameClear, isTrue);
    expect(harness.session.stageClearCount, 3);
    expect(harness.session.score, GameSessionState.scorePerBalloon * 9);
    expect(harness.game.activeBalloonCount, 0);
    expect(harness.game.isComponentStateSynchronized, isTrue);
    expect(find.textContaining('GAME CLEAR'), findsOneWidget);

    await _pumpFlameFrames(tester, 8);
    expect(harness.game.activeEffectCount, 0);
    expect(harness.game.paused, isTrue);

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
    expect(harness.game.isComponentStateSynchronized, isTrue);
  });

  testWidgets('failure restart resets Stage 1 and rejects stale components', (
    tester,
  ) async {
    final harness = await _pumpFlamePreview(tester);
    final initialBalloons = harness.game.balloonComponents.toList();
    final staleBalloon = initialBalloons.first;
    expect(initialBalloons.last.requestPop(), isTrue);
    await tester.pump();
    expect(harness.session.score, GameSessionState.scorePerBalloon);

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
}

class _FlamePreviewHarness {
  const _FlamePreviewHarness(this.game, this.session);

  final PoppopGame game;
  final GameSessionState session;
}

Future<_FlamePreviewHarness> _pumpFlamePreview(
  WidgetTester tester, {
  VoidCallback? onHudBuild,
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
          return game = PoppopGame(createdSession);
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
  await _pumpFlameFrames(tester, 10);
  await tester.pump();
}
