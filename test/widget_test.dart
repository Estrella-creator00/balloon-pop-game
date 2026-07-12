import 'package:balloon_pop_game/main.dart';
import 'package:balloon_pop_game/storage/progress_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('1 STAGE starts with two balloons and has no pop text',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.text('1~10 STAGE 시작'));
    await tester.pump();

    expect(find.text('1 STAGE'), findsOneWidget);
    expect(find.text('팡!'), findsNothing);
    expect(find.byType(GestureDetector), findsNWidgets(2));
  });

  testWidgets('only the tapped balloon is removed', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.text('1~10 STAGE 시작'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey(0)));
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const ValueKey(0)), findsNothing);
    expect(find.byKey(const ValueKey(1)), findsOneWidget);
    expect(find.text('1 STAGE'), findsOneWidget);
    expect(find.text('점수  0'), findsOneWidget);
  });

  testWidgets('the next stage starts only after every balloon is popped',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.text('1~10 STAGE 시작'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey(0)));
    await tester.pump();
    expect(find.text('1 STAGE'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey(1)));
    await tester.pump();
    expect(find.text('Stage Clear!'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('2 STAGE'), findsOneWidget);
    expect(find.text('시간  10'), findsOneWidget);
    expect(find.text('점수  10'), findsOneWidget);
    expect(find.byType(GestureDetector), findsNWidgets(3));
  });

  testWidgets('each stage group receives its own time limit', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.text('1~10 STAGE 시작'));
    await tester.pump();

    var nextBalloonId = 0;
    for (var stage = 1; stage <= 6; stage++) {
      final expectedSeconds = stage <= 3 ? '10' : '15';
      expect(find.text('시간  $expectedSeconds'), findsOneWidget);

      for (var i = 0; i < stage + 1; i++) {
        await tester.tap(find.byKey(ValueKey(nextBalloonId++)));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('7 STAGE'), findsOneWidget);
    expect(find.text('시간  20'), findsOneWidget);
  });

  testWidgets('stage one ends when its ten seconds expire', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.text('1~10 STAGE 시작'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 10));

    expect(find.text('시간 끝!'), findsOneWidget);
    expect(find.text('1 STAGE'), findsOneWidget);
  });

  testWidgets('first launch locks the second section', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();

    expect(find.text('1~10 STAGE 시작'), findsOneWidget);
    expect(find.text('11~20 STAGE 시작 🔒'), findsOneWidget);
    expect(find.text('10 STAGE 보스를 먼저 클리어하세요'), findsOneWidget);

    await tester.tap(find.text('11~20 STAGE 시작 🔒'));
    await tester.pump();
    expect(find.text('11 STAGE'), findsNothing);
    expect(find.text('11~20 STAGE 시작 🔒'), findsOneWidget);
  });

  testWidgets('stage ten boss unlocks section and it survives app reload',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.text('1~10 STAGE 시작'));
    await tester.pump();

    var nextBalloonId = 0;
    for (var stage = 1; stage <= 9; stage++) {
      for (var i = 0; i < stage + 1; i++) {
        await tester.tap(find.byKey(ValueKey(nextBalloonId++)));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('10 STAGE'), findsOneWidget);
    expect(find.text('시간  8'), findsOneWidget);
    expect(find.byKey(const ValueKey('boss-balloon-0')), findsOneWidget);

    for (var hit = 0; hit < 10; hit++) {
      await tester.tap(find.byKey(const ValueKey('boss-balloon-0')));
      await tester.pump();
    }
    expect(find.text('BOSS CLEAR!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('11 STAGE'), findsOneWidget);
    expect(find.text('점수  153'), findsOneWidget);

    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    expect(find.text('11~20 STAGE 시작'), findsOneWidget);
    await tester.tap(find.text('11~20 STAGE 시작'));
    await tester.pump();
    expect(find.text('11 STAGE'), findsOneWidget);
    expect(find.text('점수  0'), findsOneWidget);
  });

  testWidgets('two-hit balloon survives first hit and only itself changes',
      (tester) async {
    ProgressStorage.unlockSecondSection();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.text('11~20 STAGE 시작'));
    await tester.pump();

    const firstId = 0;
    const secondId = 1;
    final firstSizeBefore = tester.getSize(find.byKey(ValueKey(firstId)));
    final secondSizeBefore = tester.getSize(find.byKey(ValueKey(secondId)));

    await tester.tap(find.byKey(ValueKey(firstId)));
    await tester.pump();

    expect(find.byKey(ValueKey(firstId)), findsOneWidget);
    expect(find.byKey(ValueKey(secondId)), findsOneWidget);
    expect(
      tester.getSize(find.byKey(ValueKey(firstId))).width <
          firstSizeBefore.width,
      true,
    );
    expect(tester.getSize(find.byKey(ValueKey(secondId))), secondSizeBefore);
    expect(find.text('남은 풍선  2'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey(firstId)));
    await tester.pump();
    expect(find.byKey(ValueKey(firstId)), findsNothing);
    expect(find.byKey(ValueKey(secondId)), findsOneWidget);
    expect(find.text('11 STAGE'), findsOneWidget);
    expect(find.text('남은 풍선  1'), findsOneWidget);
  });

  testWidgets('stage twenty has two independent bosses and scores once each',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.text('1~10 STAGE 시작'));
    await tester.pump();

    var nextBalloonId = 0;
    for (var stage = 1; stage <= 19; stage++) {
      if (stage == 10) {
        for (var hit = 0; hit < 10; hit++) {
          await tester.tap(find.byKey(const ValueKey('boss-balloon-0')));
          await tester.pump();
        }
        await tester.pump(const Duration(seconds: 1));
        continue;
      }
      final count = (stage - 1) % 10 + 2;
      final hitsPerBalloon = stage >= 11 ? 2 : 1;
      for (var i = 0; i < count; i++) {
        for (var hit = 0; hit < hitsPerBalloon; hit++) {
          await tester.tap(find.byKey(ValueKey(nextBalloonId)));
          await tester.pump();
        }
        nextBalloonId++;
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('20 STAGE'), findsOneWidget);
    expect(find.text('시간  10'), findsOneWidget);
    expect(find.byKey(const ValueKey('boss-balloon-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('boss-balloon-1')), findsOneWidget);
    expect(find.text('남은 풍선  2'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('boss-balloon-0'))).overlaps(
          tester.getRect(find.byKey(const ValueKey('boss-balloon-1')))),
      false,
    );

    final bossBSize = tester.getSize(
      find.byKey(const ValueKey('boss-balloon-1')),
    );
    await tester.tap(find.byKey(const ValueKey('boss-balloon-0')));
    await tester.pump();
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
      await tester.tap(find.byKey(const ValueKey('boss-balloon-0')));
      await tester.pump();
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
      await tester.tap(find.byKey(const ValueKey('boss-balloon-1')));
      await tester.pump();
    }
    expect(find.text('BOSS CLEAR!'), findsOneWidget);
    expect(find.text('점수  336'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('게임 완료!'), findsOneWidget);
    expect(find.text('336점'), findsOneWidget);
  });

  testWidgets('progress reset locks the second section again', (tester) async {
    ProgressStorage.unlockSecondSection();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    expect(find.text('11~20 STAGE 시작'), findsOneWidget);

    await tester.tap(find.text('진행 초기화'));
    await tester.pumpAndSettle();
    expect(find.text('저장된 진행 상태를 초기화할까요?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '초기화'));
    await tester.pumpAndSettle();

    expect(find.text('11~20 STAGE 시작 🔒'), findsOneWidget);
    expect(ProgressStorage.isSecondSectionUnlocked(), false);
  });

  testWidgets('pause freezes time movement and balloon input', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.text('1~10 STAGE 시작'));
    await tester.pump();

    final positionBefore = tester.getTopLeft(find.byKey(const ValueKey(0)));
    expect(find.text('시간  10'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pause-button')));
    await tester.pump();
    expect(find.text('일시정지'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('시간  10'), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const ValueKey(0))), positionBefore);
    await tester.tap(
      find.byKey(const ValueKey(0)),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(find.byKey(const ValueKey(0)), findsOneWidget);
    expect(find.text('점수  0'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('resume-button')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('일시정지'), findsNothing);
    expect(find.text('시간  9'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey(0))) != positionBefore,
      true,
    );
  });

  testWidgets('cancelling end dialog resumes the same game', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.text('1~10 STAGE 시작'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('end-button')));
    await tester.pumpAndSettle();
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
    expect(find.text('시간  9'), findsOneWidget);
  });

  testWidgets('confirming end returns to menu and keeps unlock',
      (tester) async {
    ProgressStorage.unlockSecondSection();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.text('11~20 STAGE 시작'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('end-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '끝내기'));
    await tester.pumpAndSettle();

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
    await tester.tap(find.text('1~10 STAGE 시작'));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(find.text('일시정지'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('일시정지'), findsOneWidget);
    expect(find.text('시간  10'), findsOneWidget);
  });
}
