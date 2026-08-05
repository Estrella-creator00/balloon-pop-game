import 'dart:async';

import 'package:balloon_pop_game/dev/dev_coin_tool.dart';
import 'package:balloon_pop_game/main.dart';
import 'package:balloon_pop_game/services/coin_service.dart';
import 'package:balloon_pop_game/services/purchase_service.dart';
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
  test('screen identifiers stay stable', () {
    expect(ScreenIds.names[ScreenIds.home], '홈 화면');
    expect(ScreenIds.names[ScreenIds.shopCategories], '상점 카테고리 화면');
    expect(ScreenIds.names[ScreenIds.shopProductList], '상점 상품 목록 화면');
    expect(ScreenIds.names[ScreenIds.event], '이벤트 화면');
    expect(ScreenIds.names[ScreenIds.ranking], '랭킹 화면');
    expect(ScreenIds.names[ScreenIds.settings], '설정 화면');
    expect(ScreenIds.names[ScreenIds.gameplay], '게임 플레이 화면');
    expect(ScreenIds.names[ScreenIds.gameResult], '게임 완료 및 게임오버 화면');
  });

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

  test('coin rewards floor score and persist cumulatively', () {
    expect(CoinService.balance, 0);
    expect(CoinService.rewardForScore(9), 0);
    expect(CoinService.rewardForScore(10), 1);
    expect(CoinService.rewardForScore(27), 2);
    expect(CoinService.rewardForScore(99), 9);
    expect(CoinService.rewardForScore(302), 30);

    expect(CoinService.grantScoreReward(302), 30);
    expect(CoinService.balance, 30);
    expect(CoinService.grantScoreReward(27), 2);
    expect(CoinService.balance, 32);
    expect(ProgressStorage.coinBalance(), 32);
  });

  test('a game result coin session cannot grant twice', () {
    final session = CoinRewardSession();

    expect(session.grantForScore(302), 30);
    expect(session.hasGranted, true);
    expect(session.grantForScore(999), 30);
    expect(CoinService.balance, 30);

    session.reset();
    expect(session.grantForScore(27), 2);
    expect(CoinService.balance, 32);
  });

  test('purchase service charges once and persists ownership', () {
    ProgressStorage.addCoins(320);

    expect(
      PurchaseService.purchase(
        productId: 'test-product',
        price: 250,
        initiallyOwned: false,
      ),
      PurchaseResult.success,
    );
    expect(CoinService.balance, 70);
    expect(PurchaseService.ownedProductIds, contains('test-product'));

    expect(
      PurchaseService.purchase(
        productId: 'test-product',
        price: 250,
        initiallyOwned: false,
      ),
      PurchaseResult.alreadyOwned,
    );
    expect(CoinService.balance, 70);

    expect(
      PurchaseService.purchase(
        productId: 'expensive-product',
        price: 100,
        initiallyOwned: false,
      ),
      PurchaseResult.insufficientCoins,
    );
    expect(CoinService.balance, 70);
  });

  test('equipped products persist independently by category', () {
    ProgressStorage.addCoins(1000);
    expect(
      PurchaseService.purchase(
        productId: 'balloon-a',
        price: 500,
        initiallyOwned: false,
      ),
      PurchaseResult.success,
    );
    expect(
      PurchaseService.purchase(
        productId: 'sound-a',
        price: 300,
        initiallyOwned: false,
      ),
      PurchaseResult.success,
    );

    expect(
      PurchaseService.equip(
        category: 'balloon',
        productId: 'balloon-a',
        initiallyOwned: false,
      ),
      EquipResult.success,
    );
    expect(
      PurchaseService.equip(
        category: 'soundEffect',
        productId: 'sound-a',
        initiallyOwned: false,
      ),
      EquipResult.success,
    );
    expect(
      PurchaseService.equippedProductId(
        'balloon',
        defaultProductId: 'balloon-default',
      ),
      'balloon-a',
    );
    expect(
      PurchaseService.equippedProductId(
        'soundEffect',
        defaultProductId: 'sound-default',
      ),
      'sound-a',
    );
  });

  test('developer coin tap gate requires seven taps inside its window', () {
    final gate = DevCoinTapGate();
    final startedAt = DateTime(2026, 8, 5);
    for (var tap = 0; tap < 6; tap++) {
      expect(
        gate.registerTap(startedAt.add(Duration(milliseconds: tap * 100))),
        false,
      );
    }
    expect(
      gate.registerTap(startedAt.add(const Duration(milliseconds: 600))),
      true,
    );

    final expiredGate = DevCoinTapGate();
    expect(expiredGate.registerTap(startedAt), false);
    expect(
      expiredGate.registerTap(
        startedAt.add(tempDevCoinTapWindow + const Duration(milliseconds: 1)),
      ),
      false,
    );
    for (var tap = 1; tap < 6; tap++) {
      expect(
        expiredGate.registerTap(
          startedAt.add(
            tempDevCoinTapWindow + Duration(milliseconds: 1 + tap * 100),
          ),
        ),
        false,
      );
    }
  });

  testWidgets('home and store share the persisted coin balance',
      (tester) async {
    ProgressStorage.addCoins(1234);
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    expect(find.text('1,234'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();
    expect(find.text('1,234'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    expect(find.text('1,234'), findsOneWidget);
  });

  testWidgets('home uses shared top controls and four-item navigation',
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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-coin-hud')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.diamond_rounded), findsNothing);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byKey(const ValueKey('home-settings-button')), findsOneWidget);
    expect(find.text('진행 초기화'), findsNothing);
    expect(find.byKey(const ValueKey('home-nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nav-shop')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nav-event')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nav-ranking')), findsOneWidget);
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('상점'), findsOneWidget);
    expect(find.text('샵'), findsNothing);
    expect(find.text('랭킹'), findsOneWidget);
    expect(find.text('업적'), findsNothing);
    expect(find.text('도움말'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-settings-button')));
    await tester.pump();
    expect(find.text('설정 준비 중'), findsOneWidget);
    expect(find.byType(HomeFloatingBalloons), findsOneWidget);
  });

  testWidgets('hidden developer coin flow rejects a wrong password',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    final coinTarget = find.byKey(const ValueKey('home-coin-dev-tap-target'));

    for (var tap = 0; tap < 6; tap++) {
      await tester.tap(coinTarget);
    }
    await tester.pump();
    expect(find.byKey(const ValueKey('dev-coin-password-input')), findsNothing);

    await tester.tap(coinTarget);
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      find.byKey(const ValueKey('dev-coin-password-input')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('dev-coin-password-input')),
      '0000',
    );
    await tester.tap(find.byKey(const ValueKey('dev-coin-confirm')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('비밀번호가 올바르지 않습니다.'), findsOneWidget);
    expect(CoinService.balance, 0);
  });

  testWidgets('hidden developer coin flow grants once and updates shared HUD',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    final coinTarget = find.byKey(const ValueKey('home-coin-dev-tap-target'));

    for (var tap = 0; tap < 7; tap++) {
      await tester.tap(coinTarget);
    }
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(
      find.byKey(const ValueKey('dev-coin-password-input')),
      tempDevCoinPassword,
    );
    final confirm = tester.widget<FilledButton>(
      find.byKey(const ValueKey('dev-coin-confirm')),
    );
    confirm.onPressed!.call();
    confirm.onPressed!.call();
    await tester.pump(const Duration(milliseconds: 800));

    expect(CoinService.balance, tempDevCoinGrantAmount);
    expect(
      find.text('테스트 코인 10,000개가 추가되었습니다.'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-coin-hud')),
        matching: find.text('10,000'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-coin-hud')),
        matching: find.text('10,000'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('store root shows a fixed two-column category menu',
      (tester) async {
    tester.view.physicalSize = const Size(390, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('store-title')), findsOneWidget);
    expect(find.text('상점'), findsWidgets);
    expect(find.text('샵'), findsNothing);
    expect(find.byKey(const ValueKey('home-nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nav-shop')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nav-event')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nav-ranking')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('home-nav-selected-store')), findsOneWidget);
    expect(find.byType(HomeFloatingBalloons), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.byKey(const ValueKey('store-category-grid')), findsOneWidget);
    expect(find.byType(StoreCategoryMenuCard), findsNWidgets(6));
    expect(find.byType(StoreProductCard), findsNothing);
    expect(find.byKey(const ValueKey('store-vertical-scroll')), findsNothing);
    expect(find.byKey(const ValueKey('store-detail-scroll')), findsNothing);
    expect(find.byKey(const ValueKey('store-bottom-nav-slide')), findsNothing);

    const categoryNames = [
      'balloon',
      'popEffect',
      'background',
      'soundEffect',
      'music',
      'limited',
    ];
    final categoryRects = categoryNames
        .map(
          (name) => tester.getRect(
            find.byKey(ValueKey('store-category-card-$name')),
          ),
        )
        .toList();
    for (final name in categoryNames) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('store-category-card-$name')),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
    }
    expect(categoryRects[0].top, categoryRects[1].top);
    expect(categoryRects[2].top, categoryRects[3].top);
    expect(categoryRects[4].top, categoryRects[5].top);
    expect(categoryRects[0].left, categoryRects[2].left);
    expect(categoryRects[1].left, categoryRects[3].left);
    expect(categoryRects[2].top, greaterThan(categoryRects[0].bottom));
    expect(categoryRects[4].top, greaterThan(categoryRects[2].bottom));

    await tester.tap(
      find.byKey(const ValueKey('store-category-card-balloon')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('store-detail-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-detail-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-product-grid')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-filter-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-filter-owned')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-filter-unowned')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-filter-limited')), findsOneWidget);
    expect(find.byType(StoreProductCard), findsNWidgets(3));

    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('store-product-grid')),
    );
    expect(grid.scrollDirection, Axis.vertical);
    final gridDelegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(gridDelegate.crossAxisCount, 4);

    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('store-action-balloon-default')),
          )
          .onTap,
      isNull,
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('store-action-balloon-a')),
          )
          .onTap,
      isNotNull,
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('store-action-balloon-b')),
          )
          .onTap,
      isNotNull,
    );

    final cardRects = ['balloon-default', 'balloon-a', 'balloon-b']
        .map((id) => tester.getRect(find.byKey(ValueKey('store-product-$id'))))
        .toList();
    expect(cardRects[0].top, cardRects[1].top);
    expect(cardRects[1].top, cardRects[2].top);
    expect(cardRects[0].left, lessThan(cardRects[1].left));
    expect(cardRects[1].left, lessThan(cardRects[2].left));

    await tester.tap(find.byKey(const ValueKey('store-filter-owned')));
    await tester.pump();
    expect(find.byType(StoreProductCard), findsNWidgets(2));
    expect(find.byKey(const ValueKey('store-product-balloon-default')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('store-product-balloon-b')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('store-filter-unowned')));
    await tester.pump();
    expect(find.byType(StoreProductCard), findsOneWidget);
    expect(
        find.byKey(const ValueKey('store-product-balloon-a')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('store-filter-limited')));
    await tester.pump();
    expect(find.byType(StoreProductCard), findsNothing);
    expect(find.byKey(const ValueKey('store-products-empty')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('store-filter-all')));
    await tester.pump();
    expect(find.byType(StoreProductCard), findsNWidgets(3));

    await tester.tap(find.byKey(const ValueKey('store-detail-back')));
    await tester.pumpAndSettle();
    expect(find.byType(StoreCategoryMenuCard), findsNWidgets(6));
    expect(find.byType(StoreProductCard), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-nav-event')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('event-coming-soon')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('home-nav-selected-event')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-nav-ranking')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ranking-coming-soon')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-nav-selected-ranking')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('home-nav-home')));
    await tester.pump();
    expect(find.text('BEST SCORE'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('home-nav-selected-home')), findsOneWidget);
    expect(find.byType(HomeFloatingBalloons), findsOneWidget);
  });

  testWidgets('buying a store product updates coins and survives reload',
      (tester) async {
    ProgressStorage.addCoins(600);
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('store-category-card-balloon')),
    );
    await tester.pumpAndSettle();

    final productCard = find.byKey(const ValueKey('store-product-balloon-a'));
    expect(
      find.descendant(of: productCard, matching: find.text('500')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('store-action-balloon-a')),
    );
    await tester.pump();
    expect(find.text('특별 풍선 A 구매 완료!'), findsOneWidget);
    expect(CoinService.balance, 100);
    expect(
      find.descendant(of: productCard, matching: find.text('사용하기')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: productCard, matching: find.text('500')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-coin-hud')),
        matching: find.text('100'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('store-action-balloon-a')),
    );
    await tester.pump();
    expect(CoinService.balance, 100);
    expect(
      find.descendant(of: productCard, matching: find.text('사용 중')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('store-product-balloon-default')),
        matching: find.text('사용하기'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('store-category-card-balloon')),
    );
    await tester.pumpAndSettle();
    final reloadedCard = find.byKey(const ValueKey('store-product-balloon-a'));
    expect(
      find.descendant(of: reloadedCard, matching: find.text('사용 중')),
      findsOneWidget,
    );
    expect(CoinService.balance, 100);
  });

  testWidgets('insufficient coins do not purchase or charge a product',
      (tester) async {
    ProgressStorage.addCoins(100);
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('store-category-card-balloon')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('store-action-balloon-a')),
    );
    await tester.pump();
    expect(find.text('코인이 부족해요!'), findsOneWidget);
    expect(CoinService.balance, 100);
    final productCard = find.byKey(const ValueKey('store-product-balloon-a'));
    expect(
      find.descendant(of: productCard, matching: find.text('500')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: productCard, matching: find.text('사용하기')),
      findsNothing,
    );
  });

  testWidgets('store header cards and navigation fit tall mobile and desktop',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const [
      Size(390, 667),
      Size(390, 844),
      Size(1280, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const BalloonPopApp());
      await tester.pump();

      final homeCoinSize =
          tester.getSize(find.byKey(const ValueKey('home-coin-hud')));
      final homeSettingsSize = tester.getSize(
        find.byKey(const ValueKey('home-settings-button')),
      );
      final homeNavigationSize =
          tester.getSize(find.byKey(const ValueKey('home-nav-shop')));
      final homeNavigationBarSize = tester.getSize(
        find.byKey(const ValueKey('main-bottom-navigation-bar')),
      );
      final homeCoinRect =
          tester.getRect(find.byKey(const ValueKey('home-coin-hud')));
      final homeSettingsRect = tester.getRect(
        find.byKey(const ValueKey('home-settings-button')),
      );
      final homeNavigationRect =
          tester.getRect(find.byKey(const ValueKey('home-nav-shop')));
      final homeNavigationBarRect = tester.getRect(
        find.byKey(const ValueKey('main-bottom-navigation-bar')),
      );
      expect(homeCoinSize.height, 38);
      expect(homeSettingsSize, const Size(40, 38));
      expect(homeNavigationSize, const Size(96, 80));
      expect(homeNavigationBarSize.height, 80);
      await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
      await tester.pumpAndSettle();

      final coinRect =
          tester.getRect(find.byKey(const ValueKey('home-coin-hud')));
      final titleRect =
          tester.getRect(find.byKey(const ValueKey('store-title')));
      final settingsRect = tester.getRect(
        find.byKey(const ValueKey('home-settings-button')),
      );
      final navRect =
          tester.getRect(find.byKey(const ValueKey('home-nav-shop')));
      final navigationBarRect = tester.getRect(
        find.byKey(const ValueKey('main-bottom-navigation-bar')),
      );
      final firstCategoryRect = tester.getRect(
        find.byKey(const ValueKey('store-category-card-balloon')),
      );
      final lastCategoryRect = tester.getRect(
        find.byKey(const ValueKey('store-category-card-limited')),
      );
      expect(coinRect.width, closeTo(homeCoinRect.width, 0.01));
      expect(coinRect.height, closeTo(homeCoinRect.height, 0.01));
      expect(settingsRect.width, closeTo(homeSettingsRect.width, 0.01));
      expect(settingsRect.height, closeTo(homeSettingsRect.height, 0.01));
      expect(navRect.width, closeTo(homeNavigationRect.width, 0.01));
      expect(navRect.height, closeTo(homeNavigationRect.height, 0.01));
      expect(
        navigationBarRect.width,
        closeTo(homeNavigationBarRect.width, 0.01),
      );
      expect(
        navigationBarRect.height,
        closeTo(homeNavigationBarRect.height, 0.01),
      );
      expect(titleRect.overlaps(coinRect), false);
      expect(titleRect.overlaps(settingsRect), false);
      expect(titleRect.top, greaterThan(coinRect.bottom));
      expect(titleRect.top, greaterThan(settingsRect.bottom));
      expect(navRect.bottom, lessThanOrEqualTo(size.height));
      expect(firstCategoryRect.width, lessThanOrEqualTo(248));
      expect(lastCategoryRect.bottom, lessThan(navigationBarRect.top));
      expect(find.byType(StoreCategoryMenuCard), findsNWidgets(6));
      expect(find.byType(StoreProductCard), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
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
    final firstReward = expectedFinalScore ~/ 10;
    expect(find.text('+$firstReward COINS'), findsOneWidget);
    expect(ProgressStorage.coinBalance(), firstReward);
    await tester.pump(const Duration(seconds: 2));
    expect(ProgressStorage.coinBalance(), firstReward);
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

  testWidgets('locked store product uses a compact disabled placeholder',
      (tester) async {
    const lockedProduct = StoreProduct(
      id: 'locked-balloon',
      category: StoreCategory.balloon,
      name: '아주 긴 잠금 풍선 상품 이름',
      price: 1200,
      owned: false,
      equipped: false,
      previewType: StorePreviewType.balloon,
      previewData: Colors.grey,
      locked: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 82,
            height: 104,
            child: StoreProductCard(
              product: lockedProduct,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('???'), findsOneWidget);
    expect(find.text('잠김'), findsOneWidget);
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('store-action-locked-balloon')),
          )
          .onTap,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
