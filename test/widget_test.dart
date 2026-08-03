import 'dart:async';

import 'package:balloon_pop_game/main.dart';
import 'package:balloon_pop_game/storage/progress_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapSectionStart(WidgetTester tester, int section) async {
  final button = find.byKey(ValueKey('start-section-$section'));
  final widget = tester.widget<FilledButton>(button);
  widget.onPressed?.call();
  await tester.pump();
  await tester.pump();
}

Future<void> tapGameTarget(WidgetTester tester, Object key) async {
  final target = key is int
      ? find.byKey(ValueKey<int>(key))
      : find.byKey(ValueKey<String>(key as String));
  final positioned = tester.widget<Positioned>(target);
  final detector = positioned.child as GestureDetector;
  detector.onTap?.call();
  await tester.pump();
}

void main() {
  setUp(ProgressStorage.clear);

  test('stage rules are generated for normal and boss tiers', () {
    final stage10 = StageConfig.forStage(10);
    final stage11 = StageConfig.forStage(11);
    final stage19 = StageConfig.forStage(19);
    final stage20 = StageConfig.forStage(20);

    expect(stage10.isBoss, true);
    expect(stage10.bossHp, 10);
    expect(stage11.balloonCount, 2);
    expect(stage11.balloonHp, 2);
    expect(stage11.duration, const Duration(seconds: 12));
    expect(stage19.balloonCount, 10);
    expect(stage19.duration, const Duration(seconds: 22));
    expect(stage20.isBoss, true);
    expect(stage20.bossHp, 15);
    expect((stage20.bossSpeed - stage10.bossSpeed * 1.2).abs() < 0.001, true);
    expect(stage10.bossCount, 1);
    expect(stage20.bossCount, 2);
    expect(stage20.duration, const Duration(seconds: 10));
  });

  test('30fps elapsed-time integration preserves movement and caps long frames',
      () {
    const speed = 120.0;
    final distanceAt30Fps = List.filled(
      30,
      calculateFrameDelta(const Duration(microseconds: 33333)),
    ).fold<double>(0, (distance, dt) => distance + speed * dt);
    final distanceAt60Fps = List.filled(
      60,
      calculateFrameDelta(const Duration(microseconds: 16667)),
    ).fold<double>(0, (distance, dt) => distance + speed * dt);

    expect(gameLoopInterval, const Duration(milliseconds: 33));
    expect((distanceAt30Fps - distanceAt60Fps).abs(), lessThan(0.01));
    expect(
      calculateFrameDelta(const Duration(milliseconds: 250)),
      maxFrameDeltaSeconds,
    );
  });

  test('game loop start always cancels the previous timer', () {
    final timers = <Timer>[];
    final loop = SinglePeriodicGameLoop(
      timerFactory: (interval, callback) {
        final timer = Timer(const Duration(days: 1), () {});
        timers.add(timer);
        return timer;
      },
    );

    loop.start(gameLoopInterval, (_) {});
    loop.start(gameLoopInterval, (_) {});

    expect(timers.where((timer) => timer.isActive), hasLength(1));
    expect(loop.isRunning, true);
    loop.stop();
    expect(timers.where((timer) => timer.isActive), isEmpty);
  });

  test('pieces and rings are removed after their lifetime', () {
    final pieces = [
      PopPiece(
        position: Offset.zero,
        velocity: const Offset(10, -10),
        color: Colors.red,
        size: 8,
        rotation: 0,
        spin: 1,
        life: 0.82,
        maxLife: 1.15,
      ),
    ];
    final rings = [
      BurstRing(
        center: Offset.zero,
        color: Colors.yellow,
        radius: 20,
        life: 0.38,
        maxLife: 0.38,
      ),
    ];

    for (var frame = 0; frame < 30; frame++) {
      advanceEffects(pieces, rings, 1 / 30);
    }

    expect(pieces, isEmpty);
    expect(rings, isEmpty);
  });

  test('best and last scores persist independently', () {
    expect(ProgressStorage.saveScore(94), true);
    expect(ProgressStorage.bestScore(), 94);
    expect(ProgressStorage.lastScore(), 94);
    expect(ProgressStorage.saveScore(40), false);
    expect(ProgressStorage.bestScore(), 94);
    expect(ProgressStorage.lastScore(), 40);
  });

  testWidgets('home uses compact top controls and three-item navigation',
      (tester) async {
    ProgressStorage.saveScore(128);
    ProgressStorage.saveScore(94);
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();

    expect(find.text('P'), findsAtLeastNWidgets(4));
    expect(find.text('O'), findsAtLeastNWidgets(2));
    expect(find.text('터치해서 터뜨려!'), findsOneWidget);
    expect(find.text('BEST SCORE'), findsOneWidget);
    expect(find.text('LAST SCORE'), findsOneWidget);
    expect(find.text('v0.6 UI REFRESH'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-coin-hud')), findsOneWidget);
    expect(find.text('23,450'), findsOneWidget);
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byKey(const ValueKey('home-settings-button')), findsOneWidget);
    expect(find.text('진행 초기화'), findsNothing);
    expect(find.byKey(const ValueKey('home-nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nav-shop')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nav-ranking')), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('샵'), findsOneWidget);
    expect(find.text('랭킹'), findsOneWidget);
    expect(find.text('업적'), findsNothing);
    expect(find.text('도움말'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pump();
    expect(find.text('샵 준비 중'), findsOneWidget);
    expect(find.text('POPPOP SHOP'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('home-nav-ranking')));
    await tester.pump();
    expect(find.text('랭킹 준비 중'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-settings-button')));
    await tester.pump();
    expect(find.text('설정 준비 중'), findsOneWidget);
    expect(find.byType(HomeFloatingBalloons), findsOneWidget);
  });

  testWidgets('home controls remain inside short and tall mobile viewports',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const [
      Size(390, 667),
      Size(390, 844),
      Size(1280, 900)
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const BalloonPopApp());
      await tester.pump();

      final coinRect = tester.getRect(
        find.byKey(const ValueKey('home-coin-hud')),
      );
      final settingsRect = tester.getRect(
        find.byKey(const ValueKey('home-settings-button')),
      );
      final homeRect =
          tester.getRect(find.byKey(const ValueKey('home-nav-home')));
      final rankingRect = tester.getRect(
        find.byKey(const ValueKey('home-nav-ranking')),
      );
      expect(coinRect.top, greaterThanOrEqualTo(0));
      expect(settingsRect.top, greaterThanOrEqualTo(0));
      expect(homeRect.bottom, lessThanOrEqualTo(size.height));
      expect(rankingRect.bottom, lessThanOrEqualTo(size.height));
      expect(find.byKey(const ValueKey('start-section-1')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('home balloons animate independently and stop during gameplay',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();

    const balloonKey = ValueKey('home-floating-balloon-0');
    final before = tester.getTopLeft(find.byKey(balloonKey));
    await tester.pump(const Duration(seconds: 2));
    final after = tester.getTopLeft(find.byKey(balloonKey));
    expect((after.dy - before.dy).abs(), inInclusiveRange(0.1, 10));

    await tapSectionStart(tester, 1);
    expect(find.byType(HomeFloatingBalloons), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('backgrounded home balloons stop until the app resumes',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();

    const balloonKey = ValueKey('home-floating-balloon-1');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    final pausedPosition = tester.getTopLeft(find.byKey(balloonKey));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.getTopLeft(find.byKey(balloonKey)), pausedPosition);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.getTopLeft(find.byKey(balloonKey)), isNot(pausedPosition));
  });

  testWidgets('1 STAGE starts with two balloons and has no pop text',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    expect(find.text('1 STAGE'), findsOneWidget);
    expect(find.text('팡!'), findsNothing);
    expect(find.byKey(const ValueKey(0)), findsOneWidget);
    expect(find.byKey(const ValueKey(1)), findsOneWidget);
    expect(find.byKey(const ValueKey('play-sky-boundary')), findsOneWidget);
    expect(find.byKey(const ValueKey('game-header-boundary')), findsOneWidget);
    expect(find.byKey(const ValueKey('balloon-raster-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('balloon-raster-1')), findsOneWidget);
  });

  testWidgets('only the tapped balloon is removed', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    await tapGameTarget(tester, 0);
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const ValueKey(0)), findsNothing);
    expect(find.byKey(const ValueKey(1)), findsOneWidget);
    expect(find.text('1 STAGE'), findsOneWidget);
    expect(find.text('점수  0'), findsOneWidget);
  });

  testWidgets('effects use one batched painter instead of particle widgets',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    await tapGameTarget(tester, 0);
    final painter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('effects-boundary')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter! as EffectsPainter;
    expect(painter.pieceCount, inInclusiveRange(6, 8));
    expect(painter.ringCount, 1);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is EffectsPainter,
      ),
      findsOneWidget,
    );
  });

  testWidgets('the next stage starts only after every balloon is popped',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    await tapGameTarget(tester, 0);
    expect(find.text('1 STAGE'), findsOneWidget);

    await tapGameTarget(tester, 1);
    expect(find.text('Stage Clear!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2 STAGE'), findsOneWidget);
    expect(find.text('시간  10'), findsOneWidget);
    expect(find.text('점수  10'), findsOneWidget);
    expect(find.byKey(const ValueKey(2)), findsOneWidget);
    expect(find.byKey(const ValueKey(3)), findsOneWidget);
    expect(find.byKey(const ValueKey(4)), findsOneWidget);
  });

  testWidgets('each stage group receives its own time limit', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    var nextBalloonId = 0;
    for (var stage = 1; stage <= 6; stage++) {
      final expectedSeconds = stage <= 3 ? '10' : '15';
      expect(find.text('시간  $expectedSeconds'), findsOneWidget);

      for (var i = 0; i < stage + 1; i++) {
        await tapGameTarget(tester, nextBalloonId++);
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('7 STAGE'), findsOneWidget);
    expect(find.text('시간  20'), findsOneWidget);
  });

  testWidgets('stage one starts with a ten second limit', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    expect(find.text('시간  10'), findsOneWidget);
    expect(find.text('1 STAGE'), findsOneWidget);
  });

  testWidgets('first launch locks the second section', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();

    expect(find.text('1~10 STAGE 시작'), findsOneWidget);
    expect(find.text('11~20 STAGE 시작 🔒'), findsOneWidget);
    final lockedButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('start-section-2')),
    );
    expect(lockedButton.onPressed, isNull);

    await tapSectionStart(tester, 2);
    expect(find.text('11 STAGE'), findsNothing);
    expect(find.text('11~20 STAGE 시작 🔒'), findsOneWidget);
  });

  testWidgets('stage ten boss unlocks section and it survives app reload',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    var nextBalloonId = 0;
    for (var stage = 1; stage <= 9; stage++) {
      for (var i = 0; i < stage + 1; i++) {
        await tapGameTarget(tester, nextBalloonId++);
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('10 STAGE'), findsOneWidget);
    expect(find.text('시간  8'), findsOneWidget);
    expect(find.byKey(const ValueKey('boss-balloon-0')), findsOneWidget);

    for (var hit = 0; hit < 10; hit++) {
      await tapGameTarget(tester, 'boss-balloon-0');
    }
    expect(find.text('BOSS CLEAR!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('11 STAGE'), findsOneWidget);
    expect(find.text('점수  153'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    expect(find.text('11~20 STAGE 시작'), findsOneWidget);
    await tapSectionStart(tester, 2);
    expect(find.text('11 STAGE'), findsOneWidget);
    expect(find.text('점수  0'), findsOneWidget);
  });

  testWidgets('two-hit balloon survives first hit and only itself changes',
      (tester) async {
    ProgressStorage.unlockSecondSection();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 2);

    const firstId = 0;
    const secondId = 1;
    final firstSizeBefore = tester.getSize(find.byKey(ValueKey(firstId)));
    final secondSizeBefore = tester.getSize(find.byKey(ValueKey(secondId)));

    await tapGameTarget(tester, firstId);

    expect(find.byKey(ValueKey(firstId)), findsOneWidget);
    expect(find.byKey(ValueKey(secondId)), findsOneWidget);
    expect(
      tester.getSize(find.byKey(ValueKey(firstId))).width <
          firstSizeBefore.width,
      true,
    );
    expect(tester.getSize(find.byKey(ValueKey(secondId))), secondSizeBefore);
    expect(find.text('남은 풍선  2'), findsOneWidget);

    await tapGameTarget(tester, firstId);
    expect(find.byKey(ValueKey(firstId)), findsNothing);
    expect(find.byKey(ValueKey(secondId)), findsOneWidget);
    expect(find.text('11 STAGE'), findsOneWidget);
    expect(find.text('남은 풍선  1'), findsOneWidget);
  });

  testWidgets('stage twenty has two independent bosses and scores once each',
      (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    var nextBalloonId = 0;
    for (var stage = 1; stage <= 19; stage++) {
      if (stage == 10) {
        for (var hit = 0; hit < 10; hit++) {
          await tapGameTarget(tester, 'boss-balloon-0');
        }
        await tester.pump(const Duration(seconds: 1));
        continue;
      }
      final count = (stage - 1) % 10 + 2;
      final hitsPerBalloon = stage >= 11 ? 2 : 1;
      for (var i = 0; i < count; i++) {
        for (var hit = 0; hit < hitsPerBalloon; hit++) {
          await tapGameTarget(tester, nextBalloonId);
        }
        nextBalloonId++;
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('20 STAGE'), findsOneWidget);
    expect(find.text('시간  10'), findsOneWidget);
    expect(find.byKey(const ValueKey('boss-balloon-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('boss-balloon-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('boss-raster-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('boss-raster-1')), findsOneWidget);
    expect(find.text('남은 풍선  2'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('boss-balloon-0'))) !=
          tester.getTopLeft(find.byKey(const ValueKey('boss-balloon-1'))),
      true,
    );

    final bossBSize = tester.getSize(
      find.byKey(const ValueKey('boss-balloon-1')),
    );
    await tapGameTarget(tester, 'boss-balloon-0');
    expect(find.byKey(const ValueKey('boss-balloon-0')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('boss-balloon-0'))).width <
          bossBSize.width,
      true,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('boss-balloon-1'))),
      bossBSize,
    );

    for (var hit = 1; hit < 15; hit++) {
      await tapGameTarget(tester, 'boss-balloon-0');
    }
    expect(find.byKey(const ValueKey('boss-balloon-0')), findsNothing);
    expect(find.byKey(const ValueKey('boss-balloon-1')), findsOneWidget);
    expect(find.text('BOSS CLEAR!'), findsNothing);
    expect(find.text('남은 풍선  1'), findsOneWidget);
    expect(find.text('점수  316'), findsOneWidget);

    final bossBPosition = tester.getTopLeft(
      find.byKey(const ValueKey('boss-balloon-1')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('boss-balloon-1'))) !=
          bossBPosition,
      true,
    );

    for (var hit = 0; hit < 15; hit++) {
      await tapGameTarget(tester, 'boss-balloon-1');
    }
    expect(find.text('BOSS CLEAR!'), findsOneWidget);
    final timeText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .singleWhere((text) => text.startsWith('시간  '));
    final remainingTime = int.parse(timeText.substring('시간  '.length));
    final expectedFinalScore = 326 + remainingTime;
    expect(find.text('점수  $expectedFinalScore'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('게임 완료!'), findsOneWidget);
    expect(find.text('$expectedFinalScore점'), findsOneWidget);
    final effects = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('effects-boundary')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter! as EffectsPainter;
    expect(effects.pieceCount, 0);
    expect(effects.ringCount, 0);

    tester.view.physicalSize = const Size(390, 667);
    await tester.pump();
    final retryButton = find.byKey(const ValueKey('result-retry-button'));
    final homeButton = find.byKey(const ValueKey('result-home-button'));
    expect(retryButton, findsOneWidget);
    expect(homeButton, findsOneWidget);
    expect(tester.getRect(retryButton).bottom, lessThanOrEqualTo(655));
    expect(tester.getRect(homeButton).bottom, lessThanOrEqualTo(655));

    await tester.tap(retryButton);
    await tester.pump();
    await tester.pump();
    expect(find.text('20 STAGE'), findsOneWidget);
    expect(find.byKey(const ValueKey('boss-balloon-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('boss-balloon-1')), findsOneWidget);

    for (var hit = 0; hit < 15; hit++) {
      await tapGameTarget(tester, 'boss-balloon-0');
      await tapGameTarget(tester, 'boss-balloon-1');
    }
    await tester.pump(const Duration(seconds: 1));
    expect(homeButton, findsOneWidget);
    await tester.tap(homeButton);
    await tester.pump();
    expect(find.text('1~10 STAGE 시작'), findsOneWidget);
    expect(find.text('20 STAGE'), findsNothing);
  });

  testWidgets('home hides progress reset and preserves second-section unlock',
      (tester) async {
    ProgressStorage.unlockSecondSection();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    expect(find.text('11~20 STAGE 시작'), findsOneWidget);
    expect(find.text('진행 초기화'), findsNothing);
    expect(ProgressStorage.isSecondSectionUnlocked(), true);
    final secondSection = tester.widget<FilledButton>(
      find.byKey(const ValueKey('start-section-2')),
    );
    expect(secondSection.onPressed, isNotNull);
  });

  testWidgets('pause freezes time movement and balloon input', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    final positionBefore = tester.getTopLeft(find.byKey(const ValueKey(0)));
    expect(find.text('시간  10'), findsOneWidget);

    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('pause-button')),
        )
        .onPressed!
        .call();
    await tester.pump();
    expect(find.text('일시정지'), findsWidgets);
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('시간  10'), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const ValueKey(0))), positionBefore);
    await tapGameTarget(tester, 0);
    expect(find.byKey(const ValueKey(0)), findsOneWidget);
    expect(find.text('점수  0'), findsOneWidget);

    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('resume-button')),
        )
        .onPressed!
        .call();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('일시정지'), findsOneWidget);
    expect(find.text('시간  10'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey(0))) != positionBefore,
      true,
    );
  });

  testWidgets('cancelling end dialog resumes the same game', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    await tester.tap(find.byKey(const ValueKey('end-button')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.text('현재 게임을 끝내고 시작 화면으로 돌아갈까요?'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('시간  10'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1 STAGE'), findsOneWidget);
    expect(find.text('시간  10'), findsOneWidget);
  });

  testWidgets('confirming end returns to menu and keeps unlock',
      (tester) async {
    ProgressStorage.unlockSecondSection();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 2);

    await tester.tap(find.byKey(const ValueKey('end-button')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.widgetWithText(FilledButton, '끝내기').last);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('1~10 STAGE 시작'), findsOneWidget);
    expect(find.text('11~20 STAGE 시작'), findsOneWidget);
    expect(ProgressStorage.isSecondSectionUnlocked(), true);
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('11 STAGE'), findsNothing);
  });

  testWidgets('backgrounding the app pauses without automatic resume',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(find.text('일시정지'), findsWidgets);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('일시정지'), findsWidgets);
    expect(find.text('시간  10'), findsOneWidget);
  });
}
