import 'package:balloon_pop_game/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('1 STAGE starts with two balloons and has no pop text',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();

    expect(find.text('1 STAGE'), findsOneWidget);
    expect(find.text('팡!'), findsNothing);
    expect(find.byType(GestureDetector), findsNWidgets(2));
  });

  testWidgets('only the tapped balloon is removed', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
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

    await tester.pump(const Duration(seconds: 10));

    expect(find.text('시간 끝!'), findsOneWidget);
    expect(find.text('1 STAGE'), findsOneWidget);
  });

  testWidgets('stage ten contains one boss and awards boss bonus',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
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
    expect(find.byKey(const ValueKey('boss-balloon')), findsOneWidget);

    for (var hit = 0; hit < 10; hit++) {
      await tester.tap(find.byKey(const ValueKey('boss-balloon')));
      await tester.pump();
    }
    expect(find.text('BOSS CLEAR!'), findsOneWidget);
    expect(find.text('Bonus +200'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('게임 완료!'), findsOneWidget);
    expect(find.text('343점'), findsOneWidget);
  });
}
