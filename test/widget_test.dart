import 'dart:async';
import 'dart:ui' as ui;

import 'package:balloon_pop_game/dev/dev_coin_tool.dart';
import 'package:balloon_pop_game/audio/pop_sound.dart';
import 'package:balloon_pop_game/balloon_background.dart';
import 'package:balloon_pop_game/balloon_skin_catalog.dart';
import 'package:balloon_pop_game/main.dart';
import 'package:balloon_pop_game/onboarding_page.dart';
import 'package:balloon_pop_game/ranking/mock_ranking_repository.dart';
import 'package:balloon_pop_game/ranking/ranking_entry.dart';
import 'package:balloon_pop_game/ranking/ranking_page.dart';
import 'package:balloon_pop_game/ranking/ranking_repository.dart';
import 'package:balloon_pop_game/services/coin_service.dart';
import 'package:balloon_pop_game/services/haptic_service.dart';
import 'package:balloon_pop_game/services/purchase_service.dart';
import 'package:balloon_pop_game/services/settings_service.dart';
import 'package:balloon_pop_game/settings_page.dart';
import 'package:balloon_pop_game/storage/progress_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<void> openBalloonPreview(WidgetTester tester, String productId) async {
  // Tap the same full-card InkWell a real touch user hits. The former helper
  // targeted an internal child and did not protect the production tap path.
  await tester.tap(find.byKey(ValueKey('store-product-$productId')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  expect(find.byKey(const ValueKey('balloon-preview-dialog')), findsOneWidget);
}

Future<void> tapBalloonPreviewAction(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('balloon-preview-action')));
  await tester.pump();
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('home-settings-button')));
  await tester.pumpAndSettle();
  expect(find.byType(SettingsPage), findsOneWidget);
}

class _LoadingRankingRepository implements RankingRepository {
  final Completer<List<RankingEntry>> _top20 = Completer<List<RankingEntry>>();

  @override
  Future<List<RankingEntry>> fetchCurrentWeekTop20(RankingWeek week) =>
      _top20.future;

  @override
  Future<RankingEntry?> fetchCurrentUserRanking({
    required RankingWeek week,
    required String? nickname,
  }) async =>
      null;

  @override
  Future<RankingEntry?> fetchCurrentWeekLeader(RankingWeek week) async => null;

  @override
  Future<RankingEntry?> fetchPreviousWeekLeader(RankingWeek week) async => null;
}

class _EmptyRankingRepository implements RankingRepository {
  const _EmptyRankingRepository();

  @override
  Future<List<RankingEntry>> fetchCurrentWeekTop20(RankingWeek week) async =>
      const [];

  @override
  Future<RankingEntry?> fetchCurrentUserRanking({
    required RankingWeek week,
    required String? nickname,
  }) async =>
      null;

  @override
  Future<RankingEntry?> fetchCurrentWeekLeader(RankingWeek week) async => null;

  @override
  Future<RankingEntry?> fetchPreviousWeekLeader(RankingWeek week) async => null;
}

class _ErrorRankingRepository implements RankingRepository {
  const _ErrorRankingRepository();

  @override
  Future<List<RankingEntry>> fetchCurrentWeekTop20(RankingWeek week) async =>
      throw StateError('mock ranking failure');

  @override
  Future<RankingEntry?> fetchCurrentUserRanking({
    required RankingWeek week,
    required String? nickname,
  }) async =>
      null;

  @override
  Future<RankingEntry?> fetchCurrentWeekLeader(RankingWeek week) async => null;

  @override
  Future<RankingEntry?> fetchPreviousWeekLeader(RankingWeek week) async => null;
}

void main() {
  test('screen identifiers stay stable', () {
    expect(
      ScreenIds.names[ScreenIds.nicknameOnboarding],
      '최초 닉네임 설정 화면',
    );
    expect(ScreenIds.names[ScreenIds.home], '홈 화면');
    expect(ScreenIds.names[ScreenIds.shopCategories], '상점 카테고리 화면');
    expect(ScreenIds.names[ScreenIds.shopProductList], '상점 상품 목록 화면');
    expect(ScreenIds.names[ScreenIds.event], '이벤트 화면');
    expect(ScreenIds.names[ScreenIds.ranking], '주간 랭킹 화면');
    expect(ScreenIds.names[ScreenIds.settings], '설정 화면');
    expect(ScreenIds.names[ScreenIds.nicknameEdit], '닉네임 변경 팝업');
    expect(ScreenIds.names[ScreenIds.terms], '이용약관 화면');
    expect(ScreenIds.names[ScreenIds.privacy], '개인정보처리방침 화면');
    expect(ScreenIds.names[ScreenIds.contact], '문의하기 화면');
    expect(ScreenIds.names[ScreenIds.dataReset], '데이터 초기화 확인 팝업');
    expect(ScreenIds.names[ScreenIds.gameplay], '게임 플레이 화면');
    expect(ScreenIds.names[ScreenIds.gameResult], '게임 완료 및 게임오버 화면');
  });

  setUp(() {
    ProgressStorage.clear();
    ProgressStorage.setNicknameOnboardingCompleted(true);
    SettingsService.applyStoredPreferences();
    PopSound.resetDebug();
    HapticService.setPerformerForTest(() async {});
  });

  tearDown(HapticService.resetPerformerForTest);

  test('stage rules are generated for normal and boss tiers', () {
    final stage10 = StageConfig.forStage(10);
    final stage11 = StageConfig.forStage(11);
    final stage19 = StageConfig.forStage(19);
    final stage20 = StageConfig.forStage(20);
    final stage21 = StageConfig.forStage(21);
    final stage29 = StageConfig.forStage(29);

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
    expect(stage21.isBoss, false);
    expect(stage21.balloonCount, 2);
    expect(stage21.balloonHp, 1);
    expect(stage21.duration, const Duration(seconds: 14));
    expect(stage21.fakeBalloonCount, 2);
    expect(stage29.balloonCount, 10);
    expect(stage29.balloonHp, 1);
    expect(stage29.duration, const Duration(seconds: 24));
    expect(stage29.fakeBalloonCount, 2);
    for (var stage = 1; stage <= 20; stage++) {
      expect(StageConfig.forStage(stage).fakeBalloonCount, 0);
    }
    for (var stage = 11; stage <= 19; stage++) {
      expect(StageConfig.forStage(stage).balloonHp, 2);
    }
    for (var stage = 21; stage <= 29; stage++) {
      expect(StageConfig.forStage(stage).fakeBalloonCount, 2);
      expect(StageConfig.forStage(stage).balloonHp, 1);
    }
    expect(StageConfig.fakeBalloonHp, 1);
    expect(() => StageConfig.forStage(30), throwsRangeError);
  });

  test('fake balloon tone keeps hue with a clearly faded shared treatment', () {
    const normal = Color(0xFFFF5C8A);
    final fake = fakeBalloonColor(normal);
    final normalHsl = HSLColor.fromColor(normal);
    final fakeHsl = HSLColor.fromColor(fake);

    expect(fakeHsl.hue, closeTo(normalHsl.hue, 0.6));
    expect(
      fakeHsl.saturation,
      closeTo(normalHsl.saturation * fakeBalloonSaturationFactor, 0.02),
    );
    expect(
      fakeHsl.lightness,
      closeTo(normalHsl.lightness * fakeBalloonBrightnessFactor, 0.02),
    );
    expect(normalHsl.saturation - fakeHsl.saturation, greaterThan(0.25));
    final matrix = BalloonSkinArtwork.visualColorMatrix(
      BalloonSkinCatalog.byIdOrDefault('balloon-heart'),
      normal,
      isFake: true,
    );
    expect(matrix[18], 1);
    expect(matrix[19], 0);
  });

  testWidgets('every balloon definition uses the shared fake renderer path',
      (tester) async {
    for (final definition in BalloonSkinCatalog.definitions) {
      final key = ValueKey('shared-fake-${definition.id}');
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox.square(
              dimension: 120,
              child: BalloonSkinRenderer(
                key: key,
                definition: definition,
                color: definition.previewColor,
                isFake: true,
              ),
            ),
          ),
        ),
      );

      final renderer = tester.widget<BalloonSkinRenderer>(find.byKey(key));
      expect(renderer.isFake, isTrue);
      if (definition.rendererType == BalloonRendererType.painted) {
        final paint = tester.widget<CustomPaint>(
          find.descendant(
              of: find.byKey(key), matching: find.byType(CustomPaint)),
        );
        expect(
          (paint.painter! as BalloonPainter).color,
          fakeBalloonColor(definition.previewColor),
        );
      } else {
        expect(
          find.descendant(
              of: find.byKey(key), matching: find.byType(ColorFiltered)),
          findsOneWidget,
        );
      }
    }
  });

  test('ranking week uses the Monday 17:00 KST boundary', () {
    final beforeBoundary = RankingWeek.forInstant(
      DateTime.utc(2026, 8, 10, 7, 59, 59),
    );
    final atBoundary = RankingWeek.forInstant(
      DateTime.utc(2026, 8, 10, 8),
    );

    expect(beforeBoundary.id, '2026-08-03');
    expect(atBoundary.id, '2026-08-10');
    expect(atBoundary.startKst.weekday, DateTime.monday);
    expect(atBoundary.startKst.hour, 17);
    expect(atBoundary.nextStartKst.weekday, DateTime.monday);
    expect(atBoundary.nextStartKst.hour, 17);
  });

  test('mock ranking provides a sorted current top 20 and weekly leaders',
      () async {
    const repository = MockRankingRepository();
    final week = RankingWeek.forInstant(DateTime.utc(2026, 8, 12));
    final entries = await repository.fetchCurrentWeekTop20(week);
    final current = await repository.fetchCurrentWeekLeader(week);
    final previous = await repository.fetchPreviousWeekLeader(week);

    expect(entries, hasLength(20));
    expect(
      entries.map((entry) => entry.rank),
      orderedEquals(List.generate(20, (index) => index + 1)),
    );
    for (var index = 1; index < entries.length; index++) {
      expect(entries[index - 1].score, greaterThan(entries[index].score));
    }
    expect(entries.every((entry) => entry.weekId == week.id), isTrue);
    expect(current?.rank, 1);
    expect(previous?.weekId, week.previous.id);
  });

  test('unsupported haptics never interrupt gameplay', () async {
    HapticService.setPerformerForTest(() async {
      throw UnsupportedError('haptics unavailable');
    });

    expect(HapticService.shortImpact, returnsNormally);
    await Future<void>.delayed(Duration.zero);
  });

  test('boss health fraction is visible, proportional, and clamped', () {
    expect(bossHealthFraction(10, 10), 1);
    expect(bossHealthFraction(9, 10), closeTo(0.9, 0.0001));
    expect(bossHealthFraction(14, 15), closeTo(14 / 15, 0.0001));
    expect(bossHealthFraction(0, 15), 0);
    expect(bossHealthFraction(-1, 15), 0);
    expect(bossHealthFraction(16, 15), 1);
    expect(bossHealthFraction(1, 0), 0);
  });

  test('balloon catalog is unique, ordered, and defines basic and heart', () {
    expect(BalloonSkinCatalog.hasUniqueIds, isTrue);
    expect(
      BalloonSkinCatalog.definitions.map((skin) => skin.id).toSet().length,
      BalloonSkinCatalog.definitions.length,
    );
    expect(
      BalloonSkinCatalog.shopDefinitions.map((skin) => skin.shopOrder),
      orderedEquals([0, 1, 2, 3]),
    );

    final basic = BalloonSkinCatalog.byIdOrDefault('balloon-default');
    expect(basic.isDefault, isTrue);
    expect(basic.rendererType, BalloonRendererType.painted);
    expect(basic.popEffectType, BalloonPopEffectType.shards);
    expect(basic.popSoundType, BalloonPopSoundType.basic);
    expect(basic.supportsBossSkin, isTrue);
    expect(basic.background, BalloonBackgroundType.none);

    final heart = BalloonSkinCatalog.byIdOrDefault('balloon-heart');
    expect(heart.price, 100);
    expect(heart.rarity, BalloonRarity.common);
    expect(heart.assetPath, 'assets/images/heart_balloon.png');
    expect(heart.colorPalette, hasLength(6));
    expect(heart.popEffectType, BalloonPopEffectType.hearts);
    expect(heart.popSoundType, BalloonPopSoundType.heart);
    expect(heart.supportsBossSkin, isTrue);
    expect(heart.badge, BalloonBadge.newItem);
    expect(heart.background, BalloonBackgroundType.none);
  });

  testWidgets('preview and gameplay use the same optional background renderer',
      (tester) async {
    const mock = BalloonSkinDefinition(
      id: 'mock-background-skin',
      displayName: 'Mock',
      price: 0,
      rarity: BalloonRarity.legendary,
      rendererType: BalloonRendererType.painted,
      colorPalette: [Colors.pink],
      popEffectType: BalloonPopEffectType.shards,
      popSoundType: BalloonPopSoundType.basic,
      isDefault: false,
      supportsBossSkin: true,
      shopOrder: 99,
      previewColor: Colors.pink,
      background: BalloonBackgroundType.galaxy,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: GameBalloonBackground(definition: mock),
      ),
    );
    final gameBackground = tester.widget<BalloonBackgroundRenderer>(
      find.byKey(const ValueKey('game-balloon-background')),
    );
    expect(gameBackground.background, BalloonBackgroundType.galaxy);
    expect(gameBackground.fit, BoxFit.cover);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BalloonPreviewDialog(
            definition: mock,
            productProvider: () => StoreProduct.fromBalloonSkin(mock),
            onAction: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    final previewBackground = tester.widget<BalloonBackgroundRenderer>(
      find.byKey(const ValueKey('balloon-preview-background')),
    );
    expect(previewBackground.background, gameBackground.background);
    expect(previewBackground.fit, gameBackground.fit);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('heart balloon asset has a fully transparent surrounding area',
      (tester) async {
    await tester.runAsync(() async {
      final asset = await rootBundle.load('assets/images/heart_balloon.png');
      final codec = await ui.instantiateImageCodec(
        asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(image.width, 256);
      expect(image.height, 256);
      expect(rgba, isNotNull);

      int alphaAt(int x, int y) =>
          rgba!.getUint8(((y * image.width) + x) * 4 + 3);

      for (final point in const [
        Offset(0, 0),
        Offset(255, 0),
        Offset(0, 255),
        Offset(255, 255),
        Offset(10, 128),
        Offset(128, 10),
        Offset(245, 128),
        Offset(30, 30),
        Offset(225, 225),
      ]) {
        expect(alphaAt(point.dx.toInt(), point.dy.toInt()), 0);
      }
      for (var x = 0; x < image.width; x++) {
        expect(alphaAt(x, 0), 0);
        expect(alphaAt(x, image.height - 1), 0);
      }
      for (var y = 0; y < image.height; y++) {
        expect(alphaAt(0, y), 0);
        expect(alphaAt(image.width - 1, y), 0);
      }

      image.dispose();
      codec.dispose();
    });
  });

  testWidgets('all six heart colors preserve the asset alpha mask',
      (tester) async {
    final definition = BalloonSkinCatalog.byIdOrDefault('balloon-heart');
    final colors = definition.colorPalette;
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            for (var index = 0; index < colors.length; index++)
              SizedBox(
                width: 40,
                height: 50,
                child: BalloonSkinRenderer(
                  key: ValueKey('heart-color-$index'),
                  definition: definition,
                  color: colors[index],
                ),
              ),
          ],
        ),
      ),
    );

    for (var index = 0; index < colors.length; index++) {
      final sprite = find.byKey(ValueKey('heart-color-$index'));
      final image = tester.widget<Image>(
        find.descendant(of: sprite, matching: find.byType(Image)),
      );
      expect(image.color, isNull);
      expect(image.colorBlendMode, isNull);
      expect(
        find.descendant(of: sprite, matching: find.byType(ColorFiltered)),
        index == 0 ? findsNothing : findsOneWidget,
      );
      final artwork = tester.widget<BalloonSkinArtwork>(
        find.descendant(of: sprite, matching: find.byType(BalloonSkinArtwork)),
      );
      expect(artwork.color, colors[index]);
      expect(
        BalloonSkinArtwork.usesOriginalAsset(definition, colors[index]),
        index == 0,
      );
      final matrix = BalloonSkinArtwork.colorMatrix(
        definition,
        colors[index],
      );
      expect(matrix.sublist(15), <double>[0, 0, 0, 1, 0]);
      expect(matrix[4], 0);
      expect(matrix[9], 0);
      expect(matrix[14], 0);
    }
  });

  testWidgets('shop, normal, and boss pink use the same raw heart artwork',
      (tester) async {
    final definition = BalloonSkinCatalog.byIdOrDefault('balloon-heart');
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            for (final contextName in ['shop', 'normal', 'boss'])
              SizedBox(
                key: ValueKey('pink-$contextName'),
                width: 90,
                height: 110,
                child: BalloonSkinRenderer(
                  definition: definition,
                  color: definition.previewColor,
                  isBoss: contextName == 'boss',
                  hp: 10,
                  maxHp: 10,
                ),
              ),
          ],
        ),
      ),
    );

    for (final contextName in ['shop', 'normal', 'boss']) {
      final scope = find.byKey(ValueKey('pink-$contextName'));
      final artwork = find.descendant(
        of: scope,
        matching: find.byType(BalloonSkinArtwork),
      );
      expect(artwork, findsOneWidget);
      expect(
        tester.widget<BalloonSkinArtwork>(artwork).color,
        definition.previewColor,
      );
      expect(
        find.descendant(of: artwork, matching: find.byType(ColorFiltered)),
        findsNothing,
      );
      final image = tester.widget<Image>(
        find.descendant(of: artwork, matching: find.byType(Image)),
      );
      expect(image.image, isA<AssetImage>());
      expect((image.image as AssetImage).assetName, definition.assetPath);
      expect(image.color, isNull);
      expect(image.opacity, isNull);
    }
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
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.byType(HomeFloatingBalloons), findsNothing);
    await tester.tap(find.byKey(const ValueKey('settings-back-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.byType(SettingsPage), findsNothing);
    expect(find.byType(HomeFloatingBalloons), findsOneWidget);
  });

  test('nickname and preference services validate and persist values',
      () async {
    expect(SettingsService.nickname, isNull);
    expect(SettingsService.saveNickname(''), isFalse);
    expect(SettingsService.saveNickname(' '), isFalse);
    expect(SettingsService.saveNickname('A'), isFalse);
    expect(SettingsService.saveNickname('12345678901'), isFalse);
    expect(SettingsService.saveNickname('  POPPOP  '), isTrue);
    expect(SettingsService.nickname, 'POPPOP');

    SettingsService.setSoundEnabled(false);
    PopSound.play();
    PopSound.playHeart();
    PopSound.playBossExplosion();
    expect(PopSound.basicPlayCount, 0);
    expect(PopSound.heartPlayCount, 0);
    expect(PopSound.bossExplosionPlayCount, 0);

    SettingsService.setSoundEnabled(true);
    PopSound.play();
    expect(PopSound.basicPlayCount, 1);

    var hapticCount = 0;
    HapticService.setPerformerForTest(() async => hapticCount++);
    SettingsService.setHapticEnabled(false);
    HapticService.shortImpact();
    await Future<void>.delayed(Duration.zero);
    expect(hapticCount, 0);
    SettingsService.setHapticEnabled(true);
    HapticService.shortImpact();
    await Future<void>.delayed(Duration.zero);
    expect(hapticCount, 1);
  });

  testWidgets('new users complete ON-01 once and return directly to home',
      (tester) async {
    ProgressStorage.clear();

    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    expect(find.byType(NicknameOnboardingPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('nickname-onboarding-page')),
      findsOneWidget,
    );

    final startButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('onboarding-start-button')),
    );
    expect(startButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('onboarding-nickname-input')),
      '  새사용자  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding-start-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(SettingsService.nickname, '새사용자');
    expect(SettingsService.nicknameOnboardingCompleted, isTrue);
    expect(find.byType(NicknameOnboardingPage), findsNothing);
    expect(find.text('BEST SCORE'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    expect(find.byType(NicknameOnboardingPage), findsNothing);
    expect(find.text('BEST SCORE'), findsOneWidget);
  });

  testWidgets('existing user data survives first ON-01 migration',
      (tester) async {
    ProgressStorage.clear();
    ProgressStorage.addCoins(1000);
    ProgressStorage.unlockSecondSection();
    ProgressStorage.saveScore(88);
    expect(
      ProgressStorage.tryPurchaseProduct('balloon-heart', 100),
      isTrue,
    );
    ProgressStorage.setEquippedProductId('balloon', 'balloon-heart');
    SettingsService.saveNickname('기존사용자');
    SettingsService.setSoundEnabled(false);
    SettingsService.setHapticEnabled(false);

    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    expect(find.byType(NicknameOnboardingPage), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('onboarding-nickname-input')),
    );
    expect(field.controller?.text, '기존사용자');

    await tester.tap(find.byKey(const ValueKey('onboarding-start-button')));
    await tester.pump();

    expect(CoinService.balance, 900);
    expect(ProgressStorage.isSecondSectionUnlocked(), isTrue);
    expect(ProgressStorage.bestScore(), 88);
    expect(PurchaseService.ownedProductIds, contains('balloon-heart'));
    expect(
      ProgressStorage.equippedProductId('balloon'),
      'balloon-heart',
    );
    expect(SettingsService.soundEnabled, isFalse);
    expect(SettingsService.hapticEnabled, isFalse);
    expect(SettingsService.nickname, '기존사용자');
    expect(SettingsService.nicknameOnboardingCompleted, isTrue);
  });

  testWidgets('home ranking button opens R-01 with ordered top 20 and returns',
      (tester) async {
    SettingsService.saveNickname('시원이');
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('home-nav-ranking')));
    await tester.pumpAndSettle();

    expect(find.byType(WeeklyRankingPage), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking-week-info')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('previous-week-leader-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('current-week-leader-card')),
      findsOneWidget,
    );
    final rows = tester.widgetList<RankingEntryRow>(
      find.byType(RankingEntryRow),
    );
    expect(rows, hasLength(20));
    expect(
      rows.map((row) => row.entry.rank),
      orderedEquals(List.generate(20, (index) => index + 1)),
    );
    final scores = rows.map((row) => row.entry.score).toList();
    expect(scores, orderedEquals([...scores]..sort((a, b) => b.compareTo(a))));
    expect(find.byKey(const ValueKey('ranking-top-accent-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking-top-accent-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking-top-accent-3')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('ranking-current-user-badge')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('ranking-row-20')));
    await tester.pump();
    expect(find.byKey(const ValueKey('ranking-row-20')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byKey(const ValueKey('ranking-scroll')),
      const Offset(0, 1800),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ranking-back-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.text('BEST SCORE'), findsOneWidget);
  });

  testWidgets(
      'ranking supports outside-top20, loading, empty, and error states',
      (tester) async {
    final fixedNow = DateTime.utc(2026, 8, 12);
    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyRankingPage(
          currentNickname: '목록밖테스터',
          now: () => fixedNow,
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var drag = 0; drag < 6; drag++) {
      await tester.drag(
        find.byKey(const ValueKey('ranking-scroll')),
        const Offset(0, -400),
      );
      await tester.pump();
    }
    expect(
      find.byKey(const ValueKey('ranking-outside-top20-card')),
      findsOneWidget,
    );
    expect(find.text('34위'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyRankingPage(
          key: const ValueKey('ranking-loading-page'),
          repository: _LoadingRankingRepository(),
          now: () => fixedNow,
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('ranking-loading')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyRankingPage(
          key: const ValueKey('ranking-empty-page'),
          repository: const _EmptyRankingRepository(),
          now: () => fixedNow,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ranking-empty')), findsOneWidget);
    expect(find.text('이번 주 랭킹이 아직 없어요.'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyRankingPage(
          key: const ValueKey('ranking-error-page'),
          repository: const _ErrorRankingRepository(),
          now: () => fixedNow,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ranking-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('ranking-retry-button')), findsOneWidget);
  });

  testWidgets('R-01 fits a narrow mobile viewport without overflow',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 667);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: WeeklyRankingPage(
          currentNickname: '목록밖테스터',
          now: () => DateTime.utc(2026, 8, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (var drag = 0; drag < 6; drag++) {
      await tester.drag(
        find.byKey(const ValueKey('ranking-scroll')),
        const Offset(0, -400),
      );
      await tester.pump();
    }
    await tester.pump();
    expect(
      find.byKey(const ValueKey('ranking-outside-top20-card')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('home and store open the same settings page and return',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();

    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('settings-back-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.text('BEST SCORE'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('store-product-grid')), findsOneWidget);
    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('settings-back-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.byKey(const ValueKey('store-product-grid')), findsOneWidget);
  });

  testWidgets('settings content remains scrollable without mobile overflow',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 667);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await openSettings(tester);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-reset-button')),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('settings-version')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nickname dialog validates, trims, updates, and survives reload',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await openSettings(tester);

    await tester.tap(find.byKey(const ValueKey('settings-nickname-row')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nickname-dialog')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('nickname-input')), ' ');
    await tester.tap(find.byKey(const ValueKey('nickname-save-button')));
    await tester.pump();
    expect(find.text('닉네임은 2자 이상 10자 이하로 입력해 주세요.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('nickname-input')), 'A');
    await tester.tap(find.byKey(const ValueKey('nickname-save-button')));
    await tester.pump();
    expect(find.byKey(const ValueKey('nickname-dialog')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('nickname-input')),
      '  팝팝  ',
    );
    await tester.tap(find.byKey(const ValueKey('nickname-save-button')));
    await tester.pumpAndSettle();
    expect(find.text('팝팝'), findsOneWidget);
    expect(SettingsService.nickname, '팝팝');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await openSettings(tester);
    expect(find.text('팝팝'), findsOneWidget);
  });

  testWidgets('information rows open replaceable SET-03 to SET-05 pages',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await openSettings(tester);

    for (final entry in const [
      ('settings-terms-row', 'settings-terms-page', '이용약관'),
      ('settings-privacy-row', 'settings-privacy-page', '개인정보처리방침'),
      ('settings-contact-row', 'settings-contact-page', '문의하기'),
    ]) {
      await tester.ensureVisible(find.byKey(ValueKey(entry.$1)));
      await tester.tap(find.byKey(ValueKey(entry.$1)));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(entry.$2)), findsOneWidget);
      expect(find.text(entry.$3), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('settings-back-button')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
    }
  });

  testWidgets('disabled sound blocks preview and disabled haptics block play',
      (tester) async {
    var hapticCount = 0;
    HapticService.setPerformerForTest(() async => hapticCount++);
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await openSettings(tester);

    await tester.tap(find.byKey(const ValueKey('settings-sound-switch')));
    await tester.tap(find.byKey(const ValueKey('settings-haptic-switch')));
    await tester.pump();
    expect(SettingsService.soundEnabled, isFalse);
    expect(SettingsService.hapticEnabled, isFalse);

    await tester.tap(find.byKey(const ValueKey('settings-back-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();
    await openBalloonPreview(tester, 'balloon-default');
    await tester.pump(const Duration(milliseconds: 1100));
    expect(PopSound.basicPlayCount, 0);
    await tester.tap(find.byKey(const ValueKey('balloon-preview-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-nav-home')));
    await tester.pump();
    await tapSectionStart(tester, 1);
    await tapGameTarget(tester, 0);
    await tester.pump();
    expect(hapticCount, 0);
    expect(PopSound.basicPlayCount, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await openSettings(tester);
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('settings-sound-switch')))
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('settings-haptic-switch')))
          .value,
      isFalse,
    );
  });

  testWidgets('data reset cancellation preserves and confirmation clears all',
      (tester) async {
    ProgressStorage.addCoins(1000);
    ProgressStorage.unlockSecondSection();
    ProgressStorage.saveScore(99);
    expect(
      ProgressStorage.tryPurchaseProduct('balloon-heart', 100),
      isTrue,
    );
    ProgressStorage.setEquippedProductId('balloon', 'balloon-heart');
    SettingsService.saveNickname('테스터');
    SettingsService.setSoundEnabled(false);
    SettingsService.setHapticEnabled(false);

    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await openSettings(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-reset-button')),
    );
    await tester.tap(find.byKey(const ValueKey('settings-reset-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-reset-cancel')));
    await tester.pumpAndSettle();
    expect(CoinService.balance, 900);
    expect(SettingsService.nickname, '테스터');
    expect(PurchaseService.ownedProductIds, contains('balloon-heart'));

    await tester.tap(find.byKey(const ValueKey('settings-reset-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-reset-confirm')));
    await tester.pumpAndSettle();

    expect(CoinService.balance, 0);
    expect(SettingsService.nickname, isNull);
    expect(SettingsService.soundEnabled, isTrue);
    expect(SettingsService.hapticEnabled, isTrue);
    expect(PurchaseService.ownedProductIds, isEmpty);
    expect(ProgressStorage.equippedProductId('balloon'), isNull);
    expect(ProgressStorage.isSecondSectionUnlocked(), isFalse);
    expect(ProgressStorage.bestScore(), 0);
    expect(SettingsService.nicknameOnboardingCompleted, isFalse);
    expect(find.text('설정 안 됨'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-back-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-coin-hud')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    expect(find.byType(NicknameOnboardingPage), findsOneWidget);
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

  testWidgets('shop opens the balloon product list directly', (tester) async {
    tester.view.physicalSize = const Size(390, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('store-title')), findsNothing);
    expect(find.text('풍선 모양'), findsNothing);
    expect(find.byKey(const ValueKey('home-nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nav-shop')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nav-event')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-nav-ranking')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('home-nav-selected-store')), findsOneWidget);
    expect(find.byType(HomeFloatingBalloons), findsNothing);
    expect(find.byKey(const ValueKey('store-category-grid')), findsNothing);
    expect(find.byKey(const ValueKey('store-product-grid')), findsOneWidget);
    expect(find.byType(StoreProductCard), findsNWidgets(4));
    expect(find.byKey(const ValueKey('store-vertical-scroll')), findsNothing);
    expect(find.byKey(const ValueKey('store-detail-scroll')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('store-bottom-nav-slide')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-filter-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-filter-owned')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-filter-unowned')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-filter-limited')), findsOneWidget);
    expect(find.byType(StoreProductCard), findsNWidgets(4));
    final storeScrollable = find
        .descendant(
          of: find.byKey(const ValueKey('store-product-grid')),
          matching: find.byType(Scrollable),
        )
        .first;
    for (final rarity in BalloonRarity.values) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('store-rarity-grid-${rarity.name}')),
        180,
        scrollable: storeScrollable,
      );
      expect(
        find.byKey(ValueKey('store-rarity-header-${rarity.name}')),
        findsOneWidget,
      );
      expect(find.text(rarity.label), findsAtLeastNWidgets(1));
      final grid = tester.widget<GridView>(
        find.byKey(ValueKey('store-rarity-grid-${rarity.name}')),
      );
      final gridDelegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(gridDelegate.crossAxisCount, 4);
      expect(grid.childrenDelegate.estimatedChildCount, 8);
    }
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('store-product-balloon-default')),
      -220,
      scrollable: storeScrollable,
    );

    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('store-product-balloon-default')),
          )
          .onTap,
      isNotNull,
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('store-product-balloon-a')),
          )
          .onTap,
      isNotNull,
    );
    expect(
      tester
          .widget<InkWell>(
            find.byKey(const ValueKey('store-product-balloon-b')),
          )
          .onTap,
      isNotNull,
    );

    final cardRects = [
      'balloon-default',
      'balloon-heart',
      'balloon-a',
      'balloon-b',
    ]
        .map((id) => tester.getRect(find.byKey(ValueKey('store-product-$id'))))
        .toList();
    expect(cardRects[0].top, cardRects[1].top);
    expect(cardRects[1].top, cardRects[2].top);
    expect(cardRects[2].top, cardRects[3].top);
    expect(cardRects[0].left, lessThan(cardRects[1].left));
    expect(cardRects[1].left, lessThan(cardRects[2].left));
    expect(cardRects[2].left, lessThan(cardRects[3].left));

    await tester.tap(find.byKey(const ValueKey('store-filter-owned')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('store-product-balloon-default')),
      -220,
      scrollable: storeScrollable,
    );
    expect(find.byType(StoreProductCard), findsNWidgets(2));
    expect(find.byKey(const ValueKey('store-product-balloon-default')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('store-product-balloon-b')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('store-filter-unowned')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('store-product-balloon-heart')),
      -220,
      scrollable: storeScrollable,
    );
    expect(find.byType(StoreProductCard), findsNWidgets(2));
    expect(find.byKey(const ValueKey('store-product-balloon-heart')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('store-product-balloon-a')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('store-filter-limited')));
    await tester.pump();
    expect(find.byType(StoreProductCard), findsNothing);
    final commonPlaceholderGrid = tester.widget<GridView>(
      find.byKey(const ValueKey('store-rarity-grid-common')),
    );
    expect(commonPlaceholderGrid.childrenDelegate.estimatedChildCount, 8);

    await tester.tap(find.byKey(const ValueKey('store-filter-all')));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('store-product-balloon-default')),
      -220,
      scrollable: storeScrollable,
    );
    expect(find.byType(StoreProductCard), findsNWidgets(4));

    await tester.tap(find.byKey(const ValueKey('home-nav-event')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('event-coming-soon')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('home-nav-selected-event')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-nav-ranking')));
    await tester.pumpAndSettle();
    expect(find.byType(WeeklyRankingPage), findsOneWidget);
    expect(find.text('주간 랭킹'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ranking-back-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-nav-home')));
    await tester.pump();
    expect(find.text('BEST SCORE'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('home-nav-selected-home')), findsOneWidget);
    expect(find.byType(HomeFloatingBalloons), findsOneWidget);
  });

  testWidgets(
      'balloon preview reuses renderer effects and sound and cleans up on close',
      (tester) async {
    var hapticCount = 0;
    HapticService.setPerformerForTest(() async {
      hapticCount++;
    });
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();

    await openBalloonPreview(tester, 'balloon-default');
    expect(find.text('기본 풍선'), findsWidgets);
    expect(
        find.byKey(const ValueKey('balloon-preview-rarity')), findsOneWidget);
    final previewRenderer = tester.widget<BalloonSkinRenderer>(
      find.descendant(
        of: find.byKey(const ValueKey('balloon-preview-renderer')),
        matching: find.byType(BalloonSkinRenderer),
      ),
    );
    expect(previewRenderer.definition, BalloonSkinCatalog.defaultSkin);
    expect(
      tester
          .widget<BalloonBackgroundRenderer>(
            find.byKey(const ValueKey('balloon-preview-background')),
          )
          .background,
      BalloonBackgroundType.none,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('balloon-preview-action')),
          )
          .onPressed,
      isNull,
    );
    expect(PopSound.basicPlayCount, 0);

    await tester.pump(const Duration(milliseconds: 810));
    final effects = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('balloon-preview-effects')),
        )
        .painter! as EffectsPainter;
    expect(PopSound.basicPlayCount, 1);
    expect(effects.pieceCount, inInclusiveRange(6, 8));
    expect(effects.ringCount, 1);
    expect(hapticCount, 0);
    expect(CoinService.balance, 0);

    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
    expect(
        find.byKey(const ValueKey('balloon-preview-renderer')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1010));
    expect(PopSound.basicPlayCount, 2);
    expect(hapticCount, 0);

    await tester.tap(find.byKey(const ValueKey('balloon-preview-close')));
    await tester.pumpAndSettle();
    final soundCountAfterClose = PopSound.basicPlayCount;
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey('balloon-preview-dialog')), findsNothing);
    expect(PopSound.basicPlayCount, soundCountAfterClose);
    expect(hapticCount, 0);

    await openBalloonPreview(tester, 'balloon-default');
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('balloon-preview-dialog')), findsNothing);
  });

  testWidgets(
      'real balloon card surfaces open preview and coming soon stays inert',
      (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();

    await openBalloonPreview(tester, 'balloon-default');
    expect(find.text('기본 풍선'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('balloon-preview-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('store-product-grid')), findsOneWidget);

    await openBalloonPreview(tester, 'balloon-heart');
    expect(find.text('하트 풍선'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('balloon-preview-close')));
    await tester.pumpAndSettle();

    final comingSoon = find.byKey(const ValueKey('store-placeholder-common-4'));
    await tester.ensureVisible(comingSoon);
    await tester.tap(comingSoon);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const ValueKey('balloon-preview-dialog')), findsNothing);
    expect(find.byKey(const ValueKey('store-product-grid')), findsOneWidget);
  });

  testWidgets('buying a store product updates coins and survives reload',
      (tester) async {
    ProgressStorage.addCoins(600);
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();

    final productCard = find.byKey(const ValueKey('store-product-balloon-a'));
    expect(
      find.descendant(of: productCard, matching: find.text('500')),
      findsOneWidget,
    );

    await openBalloonPreview(tester, 'balloon-a');
    expect(find.text('특별 풍선 A'), findsWidgets);
    expect(find.text('500 구매'), findsOneWidget);
    await tapBalloonPreviewAction(tester);
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

    expect(find.text('사용하기'), findsWidgets);
    await tapBalloonPreviewAction(tester);
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

    await tester.tap(find.byKey(const ValueKey('balloon-preview-close')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
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

    await openBalloonPreview(tester, 'balloon-a');
    await tapBalloonPreviewAction(tester);
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

  testWidgets(
      'heart balloon can be bought, equipped, rendered, and popped with hearts',
      (tester) async {
    ProgressStorage.addCoins(100);
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();

    final heartCard = find.byKey(
      const ValueKey('store-product-balloon-heart'),
    );
    final storeHeartImage = tester.widget<Image>(
      find.descendant(of: heartCard, matching: find.byType(Image)),
    );
    expect(storeHeartImage.color, isNull);
    expect(storeHeartImage.colorBlendMode, isNull);
    expect(
      find.descendant(of: heartCard, matching: find.byType(ColorFiltered)),
      findsNothing,
    );
    expect(
      find.descendant(of: heartCard, matching: find.byType(BalloonSkinArtwork)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: heartCard, matching: find.text('일반')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: heartCard, matching: find.text('100')),
      findsOneWidget,
    );

    var previewHapticCount = 0;
    HapticService.setPerformerForTest(() async {
      previewHapticCount++;
    });
    await openBalloonPreview(tester, 'balloon-heart');
    expect(find.text('하트 풍선'), findsWidgets);
    final previewRenderer = tester.widget<BalloonSkinRenderer>(
      find.descendant(
        of: find.byKey(const ValueKey('balloon-preview-renderer')),
        matching: find.byType(BalloonSkinRenderer),
      ),
    );
    expect(previewRenderer.definition.id, 'balloon-heart');
    expect(previewRenderer.color, previewRenderer.definition.previewColor);
    await tester.pump(const Duration(milliseconds: 810));
    final previewEffects = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('balloon-preview-effects')),
        )
        .painter! as EffectsPainter;
    expect(previewEffects.heartPieceCount, 5);
    expect(PopSound.heartPlayCount, 1);
    expect(previewHapticCount, 0);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
    final recoloredPreview = tester.widget<BalloonSkinRenderer>(
      find.descendant(
        of: find.byKey(const ValueKey('balloon-preview-renderer')),
        matching: find.byType(BalloonSkinRenderer),
      ),
    );
    expect(
      recoloredPreview.definition.colorPalette,
      contains(recoloredPreview.color),
    );
    expect(recoloredPreview.color, isNot(previewRenderer.color));
    await tapBalloonPreviewAction(tester);
    expect(CoinService.balance, 0);
    expect(
      find.descendant(of: heartCard, matching: find.text('사용하기')),
      findsOneWidget,
    );

    await tapBalloonPreviewAction(tester);
    expect(
      PurchaseService.equippedProductId(
        StoreCategory.balloon.name,
        defaultProductId: 'balloon-default',
      ),
      'balloon-heart',
    );
    expect(
      find.descendant(of: heartCard, matching: find.text('사용 중')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('balloon-preview-close')));
    await tester.pumpAndSettle();
    PopSound.resetDebug();

    // Existing persisted IDs remain valid after the catalog migration.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    expect(PurchaseService.ownedProductIds, contains('balloon-heart'));
    expect(
      PurchaseService.equippedProductId(
        StoreCategory.balloon.name,
        defaultProductId: BalloonSkinCatalog.defaultId,
      ),
      'balloon-heart',
    );
    await tapSectionStart(tester, 1);

    final heartSprites = tester
        .widgetList<BalloonSkinRenderer>(find.byType(BalloonSkinRenderer))
        .where((renderer) => renderer.definition.id == 'balloon-heart');
    expect(heartSprites, hasLength(2));
    expect(heartSprites.first.color, isNot(heartSprites.last.color));
    for (final heartSprite in heartSprites) {
      final spriteFinder = find.byWidget(heartSprite);
      expect(
        find.descendant(
          of: spriteFinder,
          matching: find.byType(BalloonSkinArtwork),
        ),
        findsOneWidget,
      );
      final gameImage = tester.widget<Image>(
        find.descendant(of: spriteFinder, matching: find.byType(Image)),
      );
      expect(gameImage.color, isNull);
      expect(gameImage.colorBlendMode, isNull);
    }

    await tapGameTarget(tester, 0);
    final effectsPainter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<EffectsPainter>()
        .single;
    expect(effectsPainter.heartPieceCount, 5);
    expect(PopSound.heartPlayCount, 1);
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
      final settingsRect = tester.getRect(
        find.byKey(const ValueKey('home-settings-button')),
      );
      final navRect =
          tester.getRect(find.byKey(const ValueKey('home-nav-shop')));
      final navigationBarRect = tester.getRect(
        find.byKey(const ValueKey('main-bottom-navigation-bar')),
      );
      final filterRect =
          tester.getRect(find.byKey(const ValueKey('store-filter-all')));
      final firstProductRect = tester.getRect(
        find.byKey(const ValueKey('store-product-balloon-default')),
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
      expect(filterRect.top, greaterThanOrEqualTo(coinRect.bottom));
      expect(filterRect.top, greaterThanOrEqualTo(settingsRect.bottom));
      expect(navRect.bottom, lessThanOrEqualTo(size.height));
      expect(firstProductRect.width, greaterThan(0));
      expect(find.byType(StoreProductCard), findsNWidgets(4));
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
    final gameBackground = tester.widget<BalloonBackgroundRenderer>(
      find.byKey(const ValueKey('game-balloon-background')),
    );
    expect(gameBackground.background, BalloonBackgroundType.none);
    expect(gameBackground.fallback, isA<PlaySky>());
    expect(find.byKey(const ValueKey('game-header-boundary')), findsOneWidget);
    expect(find.byKey(const ValueKey('balloon-raster-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('balloon-raster-1')), findsOneWidget);
    final basicRenderers = tester
        .widgetList<BalloonSkinRenderer>(find.byType(BalloonSkinRenderer));
    expect(basicRenderers, hasLength(2));
    expect(
      basicRenderers.every(
        (renderer) =>
            renderer.definition.id == BalloonSkinCatalog.defaultId &&
            !renderer.isBoss,
      ),
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('balloon-raster-0')),
        matching: find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is BalloonPainter,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('only the tapped balloon is removed', (tester) async {
    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tapSectionStart(tester, 1);

    var hapticCount = 0;
    HapticService.setPerformerForTest(() async {
      hapticCount++;
    });
    await tapGameTarget(tester, 0);
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const ValueKey(0)), findsNothing);
    expect(find.byKey(const ValueKey(1)), findsOneWidget);
    expect(find.text('1 STAGE'), findsOneWidget);
    expect(find.text('점수  0'), findsOneWidget);
    expect(hapticCount, 1);
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
    expect(PopSound.basicPlayCount, 1);
    expect(PopSound.heartPlayCount, 0);
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
    expect(
      tester
          .widgetList<BalloonSkinRenderer>(find.byType(BalloonSkinRenderer))
          .where((renderer) => renderer.isBoss),
      hasLength(1),
    );
    final defaultBossPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byKey(const ValueKey('boss-raster-0')),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(defaultBossPaint.painter, isA<BossBalloonPainter>());
    expect((defaultBossPaint.painter! as BossBalloonPainter).hp, 10);

    var hapticCount = 0;
    HapticService.setPerformerForTest(() async {
      hapticCount++;
    });
    await tapGameTarget(tester, 'boss-balloon-0');
    final damagedBossPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byKey(const ValueKey('boss-raster-0')),
        matching: find.byType(CustomPaint),
      ),
    );
    expect((damagedBossPaint.painter! as BossBalloonPainter).hp, 9);
    expect(hapticCount, 1);

    for (var hit = 1; hit < 10; hit++) {
      await tapGameTarget(tester, 'boss-balloon-0');
    }
    expect(hapticCount, 10);
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

    var hapticCount = 0;
    HapticService.setPerformerForTest(() async {
      hapticCount++;
    });
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
    expect(hapticCount, 0);

    await tapGameTarget(tester, firstId);
    expect(find.byKey(ValueKey(firstId)), findsNothing);
    expect(find.byKey(ValueKey(secondId)), findsOneWidget);
    expect(find.text('11 STAGE'), findsOneWidget);
    expect(find.text('남은 풍선  1'), findsOneWidget);
    expect(hapticCount, 1);
  });

  testWidgets(
      'stage 21 uses the equipped skin, applies fake penalty, and clears on normal balloons',
      (tester) async {
    ProgressStorage.addCoins(100);
    expect(
      PurchaseService.purchase(
        productId: 'balloon-heart',
        price: 100,
        initiallyOwned: false,
      ),
      PurchaseResult.success,
    );
    expect(
      PurchaseService.equip(
        category: StoreCategory.balloon.name,
        productId: 'balloon-heart',
        initiallyOwned: false,
      ),
      EquipResult.success,
    );
    var hapticCount = 0;
    HapticService.setPerformerForTest(() async => hapticCount++);

    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pump(const Duration(milliseconds: 350));
    await tapSectionStart(tester, 3);

    expect(find.text('21 STAGE'), findsOneWidget);
    expect(find.text('시간  14'), findsOneWidget);
    expect(find.text('남은 풍선  2'), findsOneWidget);
    expect(find.byKey(const ValueKey(0)), findsOneWidget);
    expect(find.byKey(const ValueKey(1)), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-balloon-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-balloon-3')), findsOneWidget);

    final renderers = tester
        .widgetList<BalloonSkinRenderer>(find.byType(BalloonSkinRenderer))
        .toList(growable: false);
    expect(renderers, hasLength(4));
    expect(
      renderers.every((renderer) => renderer.definition.id == 'balloon-heart'),
      isTrue,
    );
    expect(renderers.where((renderer) => renderer.isFake), hasLength(2));
    for (final fake in renderers.where((renderer) => renderer.isFake)) {
      expect(fake.definition.colorPalette, contains(fake.color));
    }

    await tapGameTarget(tester, 'fake-balloon-2');
    expect(find.byKey(const ValueKey('fake-balloon-2')), findsNothing);
    expect(find.byKey(const ValueKey('fake-balloon-3')), findsOneWidget);
    expect(find.text('시간  12'), findsOneWidget);
    expect(find.text('점수  0'), findsOneWidget);
    expect(find.text('남은 풍선  2'), findsOneWidget);
    expect(PopSound.fakePlayCount, 1);
    expect(hapticCount, 1);
    final effects = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('effects-boundary')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter! as EffectsPainter;
    expect(effects.feedbackCount, 1);
    expect(effects.feedbacks.single.text, '-2초');
    expect(effects.pieceCount, 0);
    expect(effects.ringCount, 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('fake-balloon-2')), findsNothing);

    for (final id in const [0, 1]) {
      await tapGameTarget(tester, id);
    }
    expect(find.text('Stage Clear!'), findsOneWidget);
    expect(find.byKey(const ValueKey('fake-balloon-3')), findsNothing);
  });

  testWidgets('fake sound and haptic follow settings', (tester) async {
    SettingsService.setSoundEnabled(false);
    SettingsService.setHapticEnabled(false);
    var hapticCount = 0;
    HapticService.setPerformerForTest(() async => hapticCount++);

    await tester.pumpWidget(const BalloonPopApp());
    await tester.pump();
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pump(const Duration(milliseconds: 350));
    await tapSectionStart(tester, 3);
    await tapGameTarget(tester, 'fake-balloon-2');

    expect(PopSound.fakePlayCount, 0);
    expect(hapticCount, 0);
    expect(find.byKey(const ValueKey('fake-balloon-2')), findsNothing);
  });

  testWidgets('stage twenty has two independent bosses and scores once each',
      (tester) async {
    ProgressStorage.addCoins(100);
    expect(
      PurchaseService.purchase(
        productId: 'balloon-heart',
        price: 100,
        initiallyOwned: false,
      ),
      PurchaseResult.success,
    );
    expect(
      PurchaseService.equip(
        category: StoreCategory.balloon.name,
        productId: 'balloon-heart',
        initiallyOwned: false,
      ),
      EquipResult.success,
    );
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
        expect(
          tester
              .widgetList<BalloonSkinRenderer>(
                find.byType(BalloonSkinRenderer),
              )
              .where(
                (renderer) =>
                    renderer.isBoss &&
                    renderer.definition.id == 'balloon-heart',
              ),
          hasLength(1),
        );
        expect(
          find.byKey(const ValueKey('boss-skin-0')),
          findsOneWidget,
        );
        final stage10HealthFill = tester.widget<FractionallySizedBox>(
          find.descendant(
            of: find.byKey(const ValueKey('boss-skin-0')),
            matching: find.byKey(const ValueKey('boss-health-fill')),
          ),
        );
        expect(stage10HealthFill.widthFactor, 1);
        expect(stage10HealthFill.heightFactor, 1);
        expect(tester.getSize(find.byWidget(stage10HealthFill)).height, 11);
        await tapGameTarget(tester, 'boss-balloon-0');
        final damagedStage10HealthFill = tester.widget<FractionallySizedBox>(
          find.descendant(
            of: find.byKey(const ValueKey('boss-skin-0')),
            matching: find.byKey(const ValueKey('boss-health-fill')),
          ),
        );
        expect(damagedStage10HealthFill.widthFactor, closeTo(0.9, 0.0001));
        for (var hit = 1; hit < 10; hit++) {
          await tapGameTarget(tester, 'boss-balloon-0');
        }
        await tester.pump(const Duration(seconds: 1));
        continue;
      }
      final count = (stage - 1) % 10 + 2;
      final hitsPerBalloon = stage >= 11 ? 2 : 1;
      for (var i = 0; i < count; i++) {
        if (stage == 11 && i == 0) {
          final skinKey = ValueKey('balloon-skin-$nextBalloonId');
          final colorBeforeHit =
              tester.widget<BalloonSkinRenderer>(find.byKey(skinKey)).color;
          await tapGameTarget(tester, nextBalloonId);
          expect(
            tester.widget<BalloonSkinRenderer>(find.byKey(skinKey)).color,
            colorBeforeHit,
          );
          await tapGameTarget(tester, nextBalloonId);
          nextBalloonId++;
          continue;
        }
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
    expect(find.byType(BalloonSkinRenderer), findsNWidgets(2));
    final heartBosses = tester
        .widgetList<BalloonSkinRenderer>(
          find.byType(BalloonSkinRenderer),
        )
        .where(
          (renderer) =>
              renderer.isBoss && renderer.definition.id == 'balloon-heart',
        )
        .toList(growable: false);
    expect(heartBosses[0].color, isNot(heartBosses[1].color));
    for (final heartBoss in heartBosses) {
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byWidget(heartBoss),
          matching: find.byType(Image),
        ),
      );
      expect(image.color, isNull);
      expect(image.colorBlendMode, isNull);
      expect(
        find.descendant(
          of: find.byWidget(heartBoss),
          matching: find.byType(BalloonSkinArtwork),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('남은 풍선  2'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('boss-balloon-0'))) !=
          tester.getTopLeft(find.byKey(const ValueKey('boss-balloon-1'))),
      true,
    );

    final bossBSize = tester.getSize(
      find.byKey(const ValueKey('boss-balloon-1')),
    );
    final bossAColorBeforeHit = tester
        .widget<BalloonSkinRenderer>(
          find.byKey(const ValueKey('boss-skin-0')),
        )
        .color;
    final bossAHealthFill = find.descendant(
      of: find.byKey(const ValueKey('boss-skin-0')),
      matching: find.byKey(const ValueKey('boss-health-fill')),
    );
    expect(
      tester.widget<FractionallySizedBox>(bossAHealthFill).widthFactor,
      1,
    );
    expect(
      tester.getSize(bossAHealthFill).height,
      11,
    );

    var hapticCount = 0;
    HapticService.setPerformerForTest(() async {
      hapticCount++;
    });
    await tester.tap(find.byKey(const ValueKey('pause-button')));
    await tester.pump();
    await tapGameTarget(tester, 'boss-balloon-0');
    expect(
      tester.widget<FractionallySizedBox>(bossAHealthFill).widthFactor,
      1,
    );
    expect(hapticCount, 0);
    await tester.tap(find.byKey(const ValueKey('resume-button')));
    await tester.pump();
    expect(
      tester.widget<FractionallySizedBox>(bossAHealthFill).widthFactor,
      1,
    );

    await tapGameTarget(tester, 'boss-balloon-0');
    expect(hapticCount, 1);
    expect(find.byKey(const ValueKey('boss-balloon-0')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('boss-balloon-0'))).width <
          bossBSize.width,
      true,
    );
    expect(
      tester
          .widget<BalloonSkinRenderer>(
            find.byKey(const ValueKey('boss-skin-0')),
          )
          .color,
      bossAColorBeforeHit,
    );
    expect(
      tester.widget<FractionallySizedBox>(bossAHealthFill).widthFactor,
      closeTo(14 / 15, 0.0001),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('boss-balloon-1'))),
      bossBSize,
    );

    for (var hit = 1; hit < 14; hit++) {
      await tapGameTarget(tester, 'boss-balloon-0');
    }
    final heartPiecesBeforeFinalHit = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('effects-boundary')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter! as EffectsPainter;
    final heartPieceCountBeforeFinalHit =
        heartPiecesBeforeFinalHit.heartPieceCount;
    await tapGameTarget(tester, 'boss-balloon-0');
    final heartPiecesAfterFinalHit = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('effects-boundary')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter! as EffectsPainter;
    expect(
      heartPiecesAfterFinalHit.heartPieceCount,
      heartPieceCountBeforeFinalHit + 28,
    );
    expect(find.byKey(const ValueKey('boss-balloon-0')), findsNothing);
    expect(find.byKey(const ValueKey('boss-balloon-1')), findsOneWidget);
    expect(hapticCount, 15);
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
            find.byKey(const ValueKey('store-product-locked-balloon')),
          )
          .onTap,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
