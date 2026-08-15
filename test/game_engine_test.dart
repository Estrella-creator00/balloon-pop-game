import 'package:balloon_pop_game/game_engine/game_session_state.dart';
import 'package:balloon_pop_game/game_engine/poppop_engine_mode.dart';
import 'package:balloon_pop_game/game_engine/poppop_game.dart';
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

  testWidgets('default entry keeps the production game and renderer', (
    tester,
  ) async {
    await tester.pumpWidget(const PoppopAppEntry());
    await tester.pump();

    expect(defaultGameplayRendererMode, GameplayRendererMode.canvasPhase4A);
    expect(find.byType(BalloonGamePage), findsOneWidget);
    expect(find.byType(GameWidget<PoppopGame>), findsNothing);
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
    await tester.tap(
      find.byKey(const ValueKey('flame-preview-pause-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(session.updateCount, beforePause);
    expect(game.paused, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('flame-preview-pause-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(session.updateCount, greaterThan(beforePause));
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
    await tester.pump(const Duration(milliseconds: 200));
    expect(session.updateCount, countWhileInactive);
    expect(game.paused, isTrue);

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(session.isRunning, isTrue);
    expect(session.updateCount, greaterThan(countWhileInactive));

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
    await game.onLoad();
    game.update(1 / 60);
    expect(session.updateCount, 1);

    game.shutdown();
    session.dispose();
    game.update(1 / 60);

    expect(session.updateCount, 1);
    expect(session.isDisposed, isTrue);
  });
}
