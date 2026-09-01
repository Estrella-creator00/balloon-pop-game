import 'dart:ui' as ui;

import 'package:balloon_pop_game/balloon_skin_catalog.dart';
import 'package:balloon_pop_game/audio/pop_sound.dart';
import 'package:balloon_pop_game/balloon_background.dart';
import 'package:balloon_pop_game/game_engine/components/balloon_component.dart';
import 'package:balloon_pop_game/game_engine/components/basic_pop_effect.dart';
import 'package:balloon_pop_game/game_engine/components/game_diagnostics_component.dart';
import 'package:balloon_pop_game/game_engine/endless/endless_mode.dart';
import 'package:balloon_pop_game/game_engine/flame_game_page.dart';
import 'package:balloon_pop_game/game_engine/game_session_state.dart';
import 'package:balloon_pop_game/game_engine/integration/flame_integration_contract.dart';
import 'package:balloon_pop_game/game_engine/integration/flame_integration_debug.dart';
import 'package:balloon_pop_game/game_engine/integration/flame_integration_game_page.dart';
import 'package:balloon_pop_game/game_engine/legendary/flame_preview_skin.dart';
import 'package:balloon_pop_game/game_engine/legendary/flame_skin_runtime.dart';
import 'package:balloon_pop_game/game_engine/legendary/legendary_skin_definition.dart';
import 'package:balloon_pop_game/game_engine/legendary/legendary_sprite_cache.dart';
import 'package:balloon_pop_game/game_engine/poppop_engine_mode.dart';
import 'package:balloon_pop_game/game_engine/poppop_game.dart';
import 'package:balloon_pop_game/game_engine/rendering/basic_balloon_sprite_cache.dart';
import 'package:balloon_pop_game/game_engine/rendering/flame_sprite_frame.dart';
import 'package:balloon_pop_game/game_engine/session/game_session_snapshot.dart';
import 'package:balloon_pop_game/game_engine/skins/catalog_sprite_cache.dart';
import 'package:balloon_pop_game/game_engine/stages/flame_stage_definition.dart';
import 'package:balloon_pop_game/game_engine/stages/stage_balloon_spawner.dart';
import 'package:balloon_pop_game/gameplay/game_canvas.dart';
import 'package:balloon_pop_game/main.dart';
import 'package:balloon_pop_game/services/coin_service.dart';
import 'package:balloon_pop_game/services/haptic_service.dart';
import 'package:balloon_pop_game/services/settings_service.dart';
import 'package:balloon_pop_game/storage/progress_storage.dart';
import 'package:balloon_pop_game/widgets/poppop_logo.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    ProgressStorage.clear();
    ProgressStorage.setNicknameOnboardingCompleted(true);
    SettingsService.applyStoredPreferences();
  });

  test('engine and preview stage query use safe fallbacks', () {
    expect(defaultPoppopEngineMode, PoppopEngineMode.flameIntegration);
    expect(poppopEngineModeFromUri(Uri.parse('https://x.test/')),
        PoppopEngineMode.flameIntegration);
    expect(
        poppopEngineModeFromUri(
            Uri.parse('https://x.test/?engine=canvas-phase4a')),
        PoppopEngineMode.canvasPhase4A);
    expect(
        poppopEngineModeFromUri(
            Uri.parse('https://x.test/?engine=flame-preview&stage=20')),
        PoppopEngineMode.flamePreview);
    expect(
        poppopEngineModeFromUri(
            Uri.parse('https://x.test/?engine=flame-integration')),
        PoppopEngineMode.flameIntegration);
    expect(poppopEngineModeFromUri(Uri.parse('https://x.test/?engine=unknown')),
        PoppopEngineMode.flameIntegration);
    for (final stage in <int>[1, 9, 10, 11, 19, 20, 21, 29, 30]) {
      expect(
          flamePreviewStageFromUri(
              Uri.parse('https://x.test/?engine=flame-preview&stage=$stage')),
          stage);
    }
    expect(flamePreviewStageFromUri(Uri.parse('https://x.test/?stage=0')), 1);
    expect(flamePreviewStageFromUri(Uri.parse('https://x.test/?stage=31')), 1);
    expect(
        flamePreviewStageFromUri(Uri.parse('https://x.test/?stage=nope')), 1);
    expect(flamePreviewSkinFromUri(Uri.parse('https://x.test/')),
        FlamePreviewSkin.basic);
    expect(
        flamePreviewSkinFromUri(
            Uri.parse('https://x.test/?skin=balloon-lumen')),
        FlamePreviewSkin.gemi);
    expect(flamePreviewSkinFromUri(Uri.parse('https://x.test/?skin=gemi')),
        FlamePreviewSkin.gemi);
    expect(flamePreviewSkinFromUri(Uri.parse('https://x.test/?skin=shushu')),
        FlamePreviewSkin.shushu);
    expect(flamePreviewSkinFromUri(Uri.parse('https://x.test/?skin=unknown')),
        FlamePreviewSkin.basic);

    final integrationDebug = FlameIntegrationDebugConfig.fromUri(Uri.parse(
      'https://x.test/?engine=flame-integration&debug=1&stage=30&skin=gemi',
    ));
    expect(integrationDebug.enabled, isTrue);
    expect(integrationDebug.stage, 30);
    expect(integrationDebug.skin, FlamePreviewSkin.gemi);
    final invalidDebug = FlameIntegrationDebugConfig.fromUri(Uri.parse(
      'https://x.test/?engine=flame-integration&debug=1&stage=31&skin=nope',
    ));
    expect(invalidDebug.stage, 1);
    expect(invalidDebug.skin, FlamePreviewSkin.basic);
    expect(
      FlameIntegrationDebugConfig.fromUri(Uri.parse(
        'https://x.test/?engine=flame-preview&debug=1&stage=30&skin=gemi',
      )).enabled,
      isFalse,
    );
    expect(
      FlameIntegrationDebugConfig.fromUri(Uri.parse(
        'https://x.test/?debug=1&stage=30&skin=gemi',
      )).enabled,
      isFalse,
    );
    expect(
      FlameIntegrationDebugConfig.fromUri(Uri.parse(
        'https://x.test/?engine=unknown&debug=1&stage=30&skin=gemi',
      )).enabled,
      isFalse,
    );
  });

  test('home and gameplay POPPOP typography share the production source', () {
    final home = PoppopLogoStyle.base(
      fontSize: 114,
      letterSpacing: -3,
      height: .88,
    );
    final gameplay = PoppopLogoStyle.base(
      fontSize: 11,
      letterSpacing: -.6,
      height: .9,
    );

    expect(home.fontFamily, PoppopLogoStyle.fontFamily);
    expect(gameplay.fontFamily, home.fontFamily);
    expect(gameplay.fontFamilyFallback, home.fontFamilyFallback);
    expect(gameplay.fontWeight, home.fontWeight);
    expect(PoppopLogoStyle.goldColors, hasLength(3));
    expect(PoppopLogoStyle.pinkColors, hasLength(3));
  });

  for (final skin in FlamePreviewSkin.values) {
    testWidgets('${skin.label} background follows catalog rarity',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SizedBox.expand(child: FlameIntegrationBackground(skin: skin)),
      ));

      final legendary =
          skin.catalogDefinition.rarity == BalloonRarity.legendary;
      expect(
        find.byType(GameplaySkyBackground),
        legendary ? findsNothing : findsOneWidget,
      );
      expect(
        find.byType(BalloonBackgroundRenderer),
        legendary ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const ValueKey('gameplay-sky-background-image')),
        legendary ? findsNothing : findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('flame-integration-legendary-background')),
        legendary ? findsOneWidget : findsNothing,
      );
      if (!legendary) {
        final image = tester.widget<Image>(
          find.byKey(const ValueKey('gameplay-sky-background-image')),
        );
        expect(
          (image.image as AssetImage).assetName,
          BalloonBackgroundRegistry.gameplaySkyAssetPath,
        );
        expect(image.fit, BoxFit.cover);
        expect(image.alignment, Alignment.center);
      }
    });
  }

  test('every production catalog skin has an exact Flame preview mapping', () {
    expect(FlamePreviewSkin.values,
        hasLength(BalloonSkinCatalog.definitions.length));
    expect(
      FlamePreviewSkin.values.map((skin) => skin.catalogDefinition.id).toSet(),
      BalloonSkinCatalog.definitions.map((skin) => skin.id).toSet(),
    );
    for (final skin in FlamePreviewSkin.values) {
      expect(flamePreviewSkinFromValue(skin.queryValue), skin);
      expect(
        flamePreviewSkinFromUri(
          Uri.parse(
              'https://x.test/?engine=flame-preview&skin=${skin.queryValue}'),
        ),
        skin,
      );
    }
  });

  test('legendary definitions reuse production catalog assets', () {
    final gemi = legendaryDefinitionFor(FlamePreviewSkin.gemi);
    final shushu = legendaryDefinitionFor(FlamePreviewSkin.shushu);
    expect(gemi.catalog.id, 'balloon-lumen');
    expect(gemi.catalog.rarity, BalloonRarity.legendary);
    expect(gemi.catalog.runtimeColorAssetPaths, hasLength(4));
    expect(gemi.catalog.runtimeFakeColorAssetPaths, hasLength(4));
    expect(gemi.catalog.runtimeShardAssetPaths, hasLength(4));
    expect(gemi.backgroundAsset, 'assets/images/gemi_background_mobile.png');
    expect(shushu.catalog.id, 'balloon-chouchou');
    expect(shushu.catalog.rarity, BalloonRarity.legendary);
    expect(shushu.catalog.assetPath, 'assets/images/balloon_shushu_asset.png');
    expect(
      shushu.bodyAssetPath,
      'assets/images/balloon_shushu_canvas_runtime.png',
    );
    expect(shushu.cleansTransparentMatte, isFalse);
    expect(shushu.idleStyle, LegendaryIdleStyle.breathe);
  });

  testWidgets('SHUSHU Flame body decodes directly with transparent alpha',
      (tester) async {
    final cache = LegendarySpriteCache(
      legendaryDefinitionFor(FlamePreviewSkin.shushu),
    );
    addTearDown(cache.dispose);
    await tester.runAsync(() => cache.prepareForStage(boss: false));
    final image = cache.bodyImage(const Color(0xFFD99542), fake: false);
    expect(image.width, 320);
    expect(image.height, 453);
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    expect(data, isNotNull);
    final pixels = data!.buffer.asUint8List();
    var transparentRgbViolations = 0;
    for (var offset = 0; offset < pixels.length; offset += 4) {
      if (pixels[offset + 3] == 0 &&
          (pixels[offset] != 0 ||
              pixels[offset + 1] != 0 ||
              pixels[offset + 2] != 0)) {
        transparentRgbViolations++;
      }
    }
    expect(transparentRgbViolations, 0);
    expect(cache.matteCleanupCount, 0);
    expect(
      cache.loadedAssetPaths,
      contains('assets/images/balloon_shushu_canvas_runtime.png'),
    );
    expect(
      cache.loadedAssetPaths,
      isNot(contains('assets/images/balloon_shushu_asset.png')),
    );
    expect(cache.imageCount, 6);
    expect(cache.estimatedRgbaBytes, lessThan(8 * 1024 * 1024));

    await tester.runAsync(() => cache.prepareForStage(boss: true));
    final bossImage = cache.bodyImage(const Color(0xFFD99542), fake: false);
    expect(bossImage.width, 361);
    expect(bossImage.height, 512);
  });

  testWidgets('GEMI production assets stay inside the selected profile budget',
      (tester) async {
    final cache = LegendarySpriteCache(
      legendaryDefinitionFor(FlamePreviewSkin.gemi),
    );
    addTearDown(cache.dispose);
    await tester.runAsync(() => cache.prepareForStage(boss: false));
    expect(cache.bodyImageCount, 8);
    expect(cache.staticImageCount, 8);
    expect(cache.imageCount, 16);
    expect(cache.estimatedRgbaBytes, lessThan(20 * 1024 * 1024));
    final normalBytes = cache.estimatedRgbaBytes;
    await tester.runAsync(() => cache.prepareForStage(boss: true));
    expect(cache.bodyImageCount, 8);
    expect(cache.imageCount, 16);
    expect(cache.estimatedRgbaBytes, lessThan(24 * 1024 * 1024));
    expect(cache.estimatedRgbaBytes, greaterThanOrEqualTo(normalBytes));
  });

  testWidgets(
      'integration legendary cache omits the duplicate Flame background image',
      (tester) async {
    final definition = legendaryDefinitionFor(FlamePreviewSkin.shushu);
    final cache = LegendarySpriteCache(
      definition,
      imageLoader: _testLegendaryImageLoader,
      includeBackground: false,
    );
    addTearDown(cache.dispose);
    await tester.runAsync(() => cache.prepareForStage(boss: false));
    expect(cache.loadedAssetPaths, isNot(contains(definition.backgroundAsset)));
    expect(
      cache.loadedAssetPaths,
      containsAll(definition.effectAssets.keys),
    );
    expect(cache.bodyImageCount, 1);
    final normalLoadCount = cache.loadCount;

    await tester.runAsync(() => cache.prepareForStage(boss: true));
    expect(cache.loadedAssetPaths, isNot(contains(definition.backgroundAsset)));
    expect(cache.loadCount, normalLoadCount + 1);
  });

  testWidgets(
      'every catalog image asset decodes into a reusable normal profile',
      (tester) async {
    for (final skin in FlamePreviewSkin.values.where(
      (skin) => skin.usesCatalogImage,
    )) {
      final definition = skin.catalogDefinition;
      final cache = CatalogSpriteCache(definition);
      await tester.runAsync(() => cache.prepareForStage(flamePreviewStage(1)));
      expect(cache.profile, CatalogBodyProfile.normal);
      expect(
          cache.loadCount,
          definition.variantAssetPaths.isEmpty
              ? 1
              : definition.variantAssetPaths.length);
      expect(cache.imageCount, greaterThan(0));
      expect(
        cache
            .frame(definition.colorPalette.first, fake: false, variant: 0)
            .image,
        isNotNull,
      );
      cache.dispose();
      expect(cache.isDisposed, isTrue);
    }
  });

  test('Flame Stage 1-30 definitions match production', () {
    expect(flamePreviewStages, hasLength(30));
    for (final definition in flamePreviewStages) {
      final production = StageConfig.forStage(definition.stage);
      expect(definition.timeLimitSeconds, production.duration.inSeconds,
          reason: 'stage ${definition.stage} time');
      expect(definition.balloonCount, production.balloonCount);
      expect(definition.balloonRule.requiredHits, production.requiredHits);
      expect(definition.balloonRule.fakeCount, production.fakeBalloonCount);
      expect(definition.balloonRule.fakePenaltySeconds, 2);
      expect(
          definition.speedRange.minimum,
          production.isBoss
              ? production.bossSpeed
              : 48 + definition.stage * 4.2);
      expect(definition.sizeRange.minimum,
          production.isBoss ? (definition.stage >= 20 ? 225 : 210) : 78);
      expect(definition.sizeRange.maximum,
          production.isBoss ? (definition.stage >= 20 ? 300 : 270) : 102);
      expect(definition.scoreRule.pointsPerBalloon, 0);
      expect(definition.scoreRule.remainingSecondMultiplier, 1);
      expect(
          definition.completion,
          definition.stage == 30
              ? StageCompletion.coreClear
              : StageCompletion.nextStage);
      if (production.isBoss) {
        expect(definition.bossRule!.bossCount, production.bossCount);
        expect(definition.bossRule!.maxHp, production.bossHp);
      }
    }
    expect(flamePreviewStage(11).type, FlameStageType.multiHit);
    expect(flamePreviewStage(21).type, FlameStageType.fake);
    expect(flamePreviewStage(30).type, FlameStageType.stage30Boss);
  });

  test('production boss definitions preserve Stage 10 20 and 30 differences',
      () {
    expect(stage10BossRule.bossCount, 1);
    expect(stage10BossRule.maxHp, 10);
    expect(stage10BossRule.initialSpeed, 105);
    expect(stage20BossRule.bossCount, 2);
    expect(stage20BossRule.maxHp, 15);
    expect(stage20BossRule.initialSpeed, 126);
    expect(stage20BossRule.sharedHp, isFalse);
    expect(stage30BossRule.bossCount, 2);
    expect(stage30BossRule.maxHp, 12);
    expect(stage30BossRule.sharedHp, isTrue);
    expect(stage30BossRule.fakeBossCount, 1);
    expect(stage30BossRule.swapChance, .5);
    expect(stage30BossRule.maximumSpeed, 220);
  });

  test('session handles 2-hit remaining and rejects duplicate final hits', () {
    final session = GameSessionState();
    session.startNewGame(flamePreviewStage(11), <int, int>{1: 2, 2: 2},
        generation: 7);
    expect(session.hitBalloon(1), BalloonHitResult.hit);
    expect(session.balloonHpFor(1), 1);
    expect(session.remainingBalloons, 2);
    expect(session.hitBalloon(1), BalloonHitResult.popped);
    expect(session.remainingBalloons, 1);
    expect(session.hitBalloon(1), BalloonHitResult.ignored);
    expect(session.hitBalloon(2), BalloonHitResult.hit);
    expect(session.hitBalloon(2), BalloonHitResult.stageCleared);
    expect(session.hitBalloon(2), BalloonHitResult.ignored);
    expect(session.stageClearCount, 1);
    expect(session.score, 12);
  });

  test('fake balloons are not remaining targets and apply one penalty', () {
    final session = GameSessionState();
    session.startNewGame(
      flamePreviewStage(21),
      <int, int>{1: 1, 2: 1},
      fakeIds: <int>{3, 4},
      generation: 3,
    );
    expect(session.remainingBalloons, 2);
    expect(session.fakeCount, 2);
    expect(session.hitBalloon(3), BalloonHitResult.fakeHit);
    expect(session.secondsLeft, 12);
    expect(session.fakeCount, 1);
    expect(session.hitBalloon(3), BalloonHitResult.ignored);
    expect(session.hitBalloon(1), BalloonHitResult.popped);
    expect(session.hitBalloon(2), BalloonHitResult.stageCleared);
    expect(session.fakeCount, 0);
    expect(session.score, 12);
  });

  test('endless difficulty reuses bounded production mechanics', () {
    final early = EndlessModeRules.profileFor(
      record: 19,
      spawnOrdinal: 3,
      activeFakeCount: 0,
    );
    final middle = EndlessModeRules.profileFor(
      record: 20,
      spawnOrdinal: 4,
      activeFakeCount: 0,
    );
    final late = EndlessModeRules.profileFor(
      record: 40,
      spawnOrdinal: 8,
      activeFakeCount: 0,
    );
    final capped = EndlessModeRules.profileFor(
      record: 10000,
      spawnOrdinal: 12,
      activeFakeCount: EndlessModeRules.activeFakeLimit,
    );

    expect(early.requiredHits, 1);
    expect(early.isFake, isFalse);
    expect(middle.requiredHits, 2);
    expect(late.isFake, isTrue);
    expect(capped.isFake, isFalse);
    expect(capped.speed, EndlessModeRules.maximumSpeed);
    expect(EndlessModeRules.activeBalloonLimit, 6);
  });

  test('endless session counts final real pops and ends on third fake', () {
    final session = GameSessionState();
    session.startEndless(
      <int, int>{1: 1, 2: 2},
      fakeIds: <int>{3, 4, 5},
      generation: 9,
    );

    expect(session.hitBalloon(2), BalloonHitResult.hit);
    expect(session.score, 0);
    expect(session.hitBalloon(2), BalloonHitResult.popped);
    expect(session.score, 1);
    session.addEndlessBalloon(6, hp: 1, isFake: false);
    expect(session.hitBalloon(3), BalloonHitResult.fakeHit);
    expect(session.endlessMistakes, 1);
    expect(session.phase, GameSessionPhase.playing);
    expect(session.hitBalloon(4), BalloonHitResult.fakeHit);
    expect(session.endlessMistakes, 2);
    expect(session.phase, GameSessionPhase.playing);
    expect(session.hitBalloon(5), BalloonHitResult.fakeHit);
    expect(session.endlessMistakes, EndlessModeRules.mistakeLimit);
    expect(session.phase, GameSessionPhase.endlessComplete);
    expect(session.hitBalloon(6), BalloonHitResult.ignored);
  });

  test('endless best last and intro storage are isolated', () {
    ProgressStorage.addCoins(321);
    ProgressStorage.advanceNextPlayableStage(31);
    expect(ProgressStorage.endlessBestScore(), 0);
    expect(ProgressStorage.endlessLastScore(), 0);
    expect(ProgressStorage.endlessIntroSeen(), isFalse);
    expect(ProgressStorage.saveEndlessBestScore(128), isTrue);
    expect(ProgressStorage.saveEndlessBestScore(64), isFalse);
    expect(ProgressStorage.saveEndlessLastScore(72), isTrue);
    expect(ProgressStorage.saveEndlessLastScore(12), isTrue);
    ProgressStorage.setEndlessIntroSeen(true);

    expect(ProgressStorage.endlessBestScore(), 128);
    expect(ProgressStorage.endlessLastScore(), 12);
    expect(ProgressStorage.endlessIntroSeen(), isTrue);
    expect(ProgressStorage.coinBalance(), 321);
    expect(ProgressStorage.nextPlayableStage(), 31);
  });

  test('Stage 20 bosses own independent HP and score exactly once', () {
    final session = GameSessionState();
    session.startNewGame(flamePreviewStage(20), const <int, int>{},
        bossHpById: <int, int>{10: 15, 11: 15}, generation: 2);
    expect(session.phase, GameSessionPhase.bossReady);
    expect(session.startBoss(), isTrue);
    for (var hit = 0; hit < 15; hit++) {
      session.hitBoss(10, swapRoll: 1);
    }
    expect(session.activeBossCount, 1);
    expect(session.score, 10);
    expect(session.bossHp, 15);
    for (var hit = 0; hit < 15; hit++) {
      session.hitBoss(11, swapRoll: 1);
    }
    expect(session.phase, GameSessionPhase.bossClear);
    expect(session.score, 30);
    expect(session.hitBoss(11, swapRoll: 1), BossHitResult.ignored);
  });

  test('Stage 30 shared HP swaps real role and fake hit penalizes once', () {
    final session = GameSessionState();
    session.startNewGame(flamePreviewStage(30), const <int, int>{},
        bossHpById: <int, int>{20: 12, 21: 12}, generation: 8);
    expect(session.startBoss(), isTrue);
    expect(session.stage30RealBossId, 20);
    expect(session.hitBoss(21, swapRoll: 1), BossHitResult.fakeHit);
    expect(session.secondsLeft, 16);
    expect(session.bossHp, 12);
    expect(session.hitBoss(20, swapRoll: 0), BossHitResult.hit);
    expect(session.bossHp, 11);
    expect(session.stage30RealBossId, 21);
    expect(session.hitBoss(20, swapRoll: 1), BossHitResult.fakeHit);
    for (var hp = 11; hp > 0; hp--) {
      final real = session.stage30RealBossId!;
      session.hitBoss(real, swapRoll: 1);
    }
    expect(session.phase, GameSessionPhase.bossClear);
    expect(session.bossHp, 0);
    expect(session.score, 24);
    session.completeCoreClear();
    expect(session.phase, GameSessionPhase.coreClear);
  });

  test('session can advance all production stages and finish CORE CLEAR', () {
    final session = GameSessionState();
    var generation = 1;
    var targetId = 100;
    for (final definition in flamePreviewStages) {
      final targets = <int, int>{
        for (var i = 0; i < definition.balloonCount; i++)
          targetId + i: definition.balloonRule.requiredHits,
      };
      final fakeIds = <int>{
        for (var i = 0; i < definition.balloonRule.fakeCount; i++)
          targetId + definition.balloonCount + i,
      };
      final bosses = <int, int>{
        for (var i = 0; i < (definition.bossRule?.bossCount ?? 0); i++)
          targetId + i: definition.bossRule!.maxHp,
      };
      if (definition.stage == 1) {
        session.startNewGame(definition, targets,
            fakeIds: fakeIds, bossHpById: bosses, generation: generation);
      } else {
        session.beginNextStage(definition, targets,
            fakeIds: fakeIds, bossHpById: bosses, generation: generation);
      }
      if (definition.isBoss) {
        expect(session.phase, GameSessionPhase.bossReady);
        session.startBoss();
        if (definition.bossRule!.sharedHp) {
          for (var hp = definition.bossRule!.maxHp; hp > 0; hp--) {
            session.hitBoss(session.stage30RealBossId!, swapRoll: 1);
          }
        } else {
          for (final id in bosses.keys) {
            for (var hp = definition.bossRule!.maxHp; hp > 0; hp--) {
              session.hitBoss(id, swapRoll: 1);
            }
          }
        }
      } else {
        for (final id in targets.keys) {
          for (var hp = definition.balloonRule.requiredHits; hp > 0; hp--) {
            session.hitBalloon(id);
          }
        }
      }
      expect(session.stage, definition.stage);
      expect(session.stageClearCount, definition.stage);
      targetId += 100;
      generation++;
    }
    expect(session.phase, GameSessionPhase.bossClear);
    session.completeCoreClear();
    expect(session.phase, GameSessionPhase.coreClear);
    expect(session.remainingBalloons, 0);
    expect(session.activeBossCount, 0);
    expect(session.score, 535);
  });

  test('Stage 29 uses bounded placement for ten targets and two fakes',
      () async {
    final cache = BasicBalloonSpriteCache();
    await cache.preload();
    addTearDown(cache.dispose);
    final hp = <int, int>{};
    final balloons = const StageBalloonSpawner(seed: 77).create(
      definition: flamePreviewStage(29),
      playfieldSize: () => Vector2(288, 320),
      generation: 1,
      idBase: 1000,
      onHitRequested: (_) => true,
      readHp: (id) => hp[id] ?? 1,
      spriteResolver: (color, hp, maxHp, fake, _) => FlameSpriteFrame(
        cache.imageForBalloon(color, hp, maxHp, fake),
      ),
    );
    expect(balloons, hasLength(12));
    expect(balloons.where((b) => !b.isFake), hasLength(10));
    expect(balloons.where((b) => b.isFake), hasLength(2));
    expect(StageBalloonSpawner.maxPlacementAttemptsPerBalloon, 20);
    for (final balloon in balloons) {
      expect(balloon.position.x, greaterThanOrEqualTo(0));
      expect(balloon.position.y, greaterThanOrEqualTo(0));
      expect(balloon.position.x + balloon.size.x, lessThanOrEqualTo(288.001));
      expect(balloon.position.y + balloon.size.y, lessThanOrEqualTo(320.001));
    }
  });

  test('sprite cache has bounded normal and active boss profiles', () async {
    final cache = BasicBalloonSpriteCache();
    await cache.preload();
    addTearDown(cache.dispose);
    expect(cache.imageCount, BasicBalloonSpriteCache.maxNormalSpriteCount);
    final normal = cache.imageForBalloon(const Color(0xFFFF5C8A), 1, 2, false);
    expect(cache.imageForBalloon(const Color(0xFFFF5C8A), 1, 2, false),
        same(normal));
    await cache.prepareBoss(stage: 30, initialSize: 240, rule: stage30BossRule);
    expect(cache.bossImageCount, 24);
    expect(cache.bossImageCount,
        lessThanOrEqualTo(BasicBalloonSpriteCache.maxBossSpriteCount));
    final fake = cache.bossImageForHp(12, fake: true);
    expect(cache.bossImageForHp(12, fake: true), same(fake));
    final preloadCount = cache.bossPreloadCount;
    await cache.prepareBoss(stage: 30, initialSize: 240, rule: stage30BossRule);
    expect(cache.bossPreloadCount, preloadCount);
  });

  test('single Flame update clamps movement dt and keeps objects in bounds',
      () async {
    final session = GameSessionState();
    final game = PoppopGame(session);
    game.onGameResize(Vector2(320, 480));
    await game.onLoad();
    final balloon = game.balloonComponents.first;
    balloon
      ..position.setValues(-2, -2)
      ..velocity.setValues(-100, -100);
    game.update(1);
    expect(game.lastAppliedDelta, BalloonComponent.maxUpdateDelta);
    expect(balloon.lastAppliedDelta, BalloonComponent.maxUpdateDelta);
    expect(balloon.position.x, greaterThanOrEqualTo(0));
    expect(balloon.position.y, greaterThanOrEqualTo(0));
    expect(balloon.velocity.x, greaterThan(0));
    expect(balloon.velocity.y, greaterThan(0));
    game.shutdown();
  });

  test('basic effect keeps its particle cap and removes after its lifetime',
      () {
    var finished = 0;
    final effect = BasicPopEffect(
      center: Vector2.zero(),
      color: const Color(0xFFFF5C8A),
      onFinished: (_) => finished++,
    );
    expect(BasicPopEffect.particleCount, 6);
    for (var frame = 0; frame < 8; frame++) {
      effect.update(BalloonComponent.maxUpdateDelta);
    }
    expect(finished, 1);
  });

  testWidgets('default entry keeps production shell and selects Flame gameplay',
      (tester) async {
    expect(defaultGameplayRendererMode, GameplayRendererMode.canvasPhase4A);
    await tester.pumpWidget(const PoppopAppEntry());
    await tester.pump();
    expect(find.byType(BalloonGamePage), findsOneWidget);
    expect(find.byType(GameWidget<PoppopGame>), findsNothing);
    expect(
      tester
          .widget<BalloonGamePage>(find.byType(BalloonGamePage))
          .useFlameGameplay,
      isTrue,
    );
  });

  testWidgets('canvas-phase4a query keeps the legacy production gameplay path',
      (tester) async {
    await tester.pumpWidget(const PoppopAppEntry(
      engineMode: PoppopEngineMode.canvasPhase4A,
    ));
    await tester.pump();

    expect(find.byType(BalloonGamePage), findsOneWidget);
    expect(
      tester
          .widget<BalloonGamePage>(find.byType(BalloonGamePage))
          .useFlameGameplay,
      isFalse,
    );
    expect(find.byType(GameWidget<PoppopGame>), findsNothing);
  });

  test('session does not repeat notifications inside one displayed second', () {
    final session = GameSessionState();
    var notifications = 0;
    session.addListener(() => notifications++);
    session.startNewGame(flamePreviewStage(1), <int, int>{1: 1, 2: 1});
    notifications = 0;
    session.recordUpdate(.01);
    session.recordUpdate(.01);
    expect(notifications, 0);
    session.recordUpdate(1);
    expect(notifications, 1);
    session.dispose();
  });

  testWidgets(
      'integration mode reuses production home and starts one Flame game',
      (tester) async {
    late PoppopGame game;
    late GameSessionState session;
    FlamePreviewSkin? selectedSkin;
    var createCount = 0;
    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationGameFactory: (created, skin, initialStage, onFeedback) {
        createCount++;
        session = created;
        selectedSkin = skin;
        return game = PoppopGame(
          created,
          initialStage: initialStage,
          initialSkin: skin,
          onGameplayFeedback: onFeedback,
          showDiagnostics: false,
        );
      },
    ));
    await tester.pump();
    expect(find.byType(BalloonGamePage), findsOneWidget);
    expect(find.byType(GameWidget<PoppopGame>), findsNothing);
    expect(find.byKey(const ValueKey('flame-preview-skin-selector')),
        findsNothing);
    final dynamic productionState = tester.state(find.byType(BalloonGamePage));
    expect(productionState.debugProductionGameplaySpriteCount, 0);

    await tester.tap(find.byKey(const ValueKey('start-section-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await game.loaded;
    await tester.pump();
    expect(createCount, 1);
    expect(selectedSkin, FlamePreviewSkin.basic);
    expect(session.stage, 1);
    expect(game.showDiagnostics, isFalse);
    expect(find.byKey(const ValueKey('flame-integration-game-widget')),
        findsOneWidget);
    expect(find.byType(GameWidget<PoppopGame>), findsOneWidget);
    expect(find.byKey(const ValueKey('flame-preview-skin-selector')),
        findsNothing);
    expect(find.byKey(const ValueKey('pause-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('end-button')), findsOneWidget);
    final headerBefore = tester.widget<GameHeader>(find.byType(GameHeader));
    final skyBackground = tester
        .widget<GameplaySkyBackground>(find.byType(GameplaySkyBackground));
    expect(game.hasLegendaryBackground, isFalse);
    expect(
      find.byKey(const ValueKey('flame-integration-fullscreen-background')),
      findsOneWidget,
    );
    expect(find.byType(BalloonBackgroundRenderer), findsNothing);
    expect(
      tester.getRect(
        find.byKey(const ValueKey('flame-integration-fullscreen-background')),
      ),
      tester.getRect(
        find.byKey(const ValueKey('flame-integration-gameplay')),
      ),
    );
    final positionBefore = game.balloonComponents.first.position.clone();
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.balloonComponents.first.position, isNot(positionBefore));
    expect(
        tester.widget<GameHeader>(find.byType(GameHeader)), same(headerBefore));
    expect(
      tester.widget<GameplaySkyBackground>(find.byType(GameplaySkyBackground)),
      same(skyBackground),
    );

    await tester.tap(find.byKey(const ValueKey('end-button')));
    await tester.pump();
    await tester.tap(find.text('끝내기').last);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(game.isShutdown, isTrue);
    expect(find.byType(GameWidget<PoppopGame>), findsNothing);
    expect(find.byType(BalloonGamePage), findsOneWidget);
  });

  testWidgets(
      'integration movement stays inside Flame and shutdown leaves no host work',
      (tester) async {
    final metrics = FlameIntegrationMetrics();
    late PoppopGame game;
    late GameSessionState session;
    var createCount = 0;
    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationMetrics: metrics,
      integrationGameFactory: (created, skin, stage, onFeedback) {
        createCount++;
        session = created;
        return game = PoppopGame(
          created,
          initialStage: stage,
          initialSkin: skin,
          onGameplayFeedback: onFeedback,
          showDiagnostics: false,
        );
      },
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start-section-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await game.loaded;
    await tester.pump();

    expect(createCount, 1);
    expect(metrics.activeGameInstances, 1);
    expect(metrics.activeGameWidgetInstances, 1);
    expect(metrics.lifecycleObserverCount, 1);
    final gameWidget = tester.widget<GameWidget<PoppopGame>>(
      find.byKey(const ValueKey('flame-integration-game-widget')),
    );
    final hudBuilds = metrics.hudRebuildCount;
    final sessionNotifications = metrics.sessionNotificationCount;
    final shellBuilds = metrics.shellRebuildCount;
    final position = game.balloonComponents.first.position.clone();

    await tester.pump(const Duration(milliseconds: 100));
    expect(game.balloonComponents.first.position, isNot(position));
    expect(metrics.hudRebuildCount, hudBuilds);
    expect(metrics.sessionNotificationCount, sessionNotifications);
    expect(metrics.shellRebuildCount, shellBuilds);
    expect(
      tester.widget<GameWidget<PoppopGame>>(
        find.byKey(const ValueKey('flame-integration-game-widget')),
      ),
      same(gameWidget),
    );

    expect(game.balloonComponents.first.requestHit(), isTrue);
    await tester.pump();
    expect(metrics.sessionNotificationCount, greaterThan(sessionNotifications));
    expect(metrics.hudRebuildCount, greaterThan(hudBuilds));

    await tester.tap(find.byKey(const ValueKey('end-button')));
    await tester.pump();
    await tester.tap(find.text('끝내기').last);
    await tester.pump();
    final updatesAtShutdown = game.updateCallCount;
    expect(game.isShutdown, isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(game.updateCallCount, updatesAtShutdown);
    expect(game.updateCallsAfterShutdown, 0);
    expect(metrics.updateAdvancedAfterShutdown, isFalse);
    expect(metrics.activeGameInstances, 0);
    expect(metrics.activeGameWidgetInstances, 0);
    expect(metrics.lifecycleObserverCount, 0);
    expect(find.byType(GameWidget<PoppopGame>), findsNothing);
    expect(find.byType(HomeFloatingBalloons), findsOneWidget);
    expect(session.isDisposed, isTrue);
  });

  testWidgets(
      'integration debug query uses isolated stage and skin diagnostics',
      (tester) async {
    final definition = FlamePreviewSkin.heart.catalogDefinition;
    ProgressStorage.addCoins(definition.price);
    expect(
      ProgressStorage.tryPurchaseProduct(definition.id, definition.price),
      isTrue,
    );
    ProgressStorage.setEquippedProductId('balloon', definition.id);
    final progressBefore = ProgressStorage.nextPlayableStage();
    final metrics = FlameIntegrationMetrics();
    const debugConfig = FlameIntegrationDebugConfig(
      enabled: true,
      stage: 30,
      skin: FlamePreviewSkin.basic,
    );

    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationDebugConfig: debugConfig,
      integrationMetrics: metrics,
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start-section-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final gameWidget = tester.widget<GameWidget<PoppopGame>>(
      find.byKey(const ValueKey('flame-integration-game-widget')),
    );
    final game = gameWidget.game!;
    await game.loaded;
    await tester.pump();

    expect(game.initialStage, 30);
    expect(game.selectedSkin, FlamePreviewSkin.basic);
    expect(game.showDiagnostics, isTrue);
    expect(game.diagnosticsTextProvider, isNotNull);
    expect(
      game.camera.viewport.children.whereType<GameDiagnosticsComponent>(),
      hasLength(1),
    );
    final text = game.diagnosticsTextProvider!(60, 16.7);
    expect(text, contains('INTEGRATION DEBUG'));
    expect(text, contains('GAME 1'));
    expect(text, contains('WIDGET 1'));
    expect(text, contains('HUD'));
    expect(text, contains('SESSION'));
    expect(text, contains('SHELL'));
    expect(text, contains('AUDIO'));
    expect(text, contains('CACHE'));
    expect(text, contains('BG 1'));
    expect(
      find.byKey(const ValueKey('flame-integration-fullscreen-background')),
      findsOneWidget,
    );
    expect(find.byType(GameplaySkyBackground), findsOneWidget);
    expect(find.byType(BalloonBackgroundRenderer), findsNothing);
    expect(ProgressStorage.nextPlayableStage(), progressBefore);
    expect(ProgressStorage.equippedProductId('balloon'), definition.id);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(game.isShutdown, isTrue);
    expect(metrics.activeGameInstances, 0);
    expect(metrics.activeGameWidgetInstances, 0);
  });

  testWidgets('integration uses the production equipped skin', (tester) async {
    final definition = BalloonSkinCatalog.byIdOrDefault('balloon-heart');
    ProgressStorage.addCoins(definition.price);
    expect(
      ProgressStorage.tryPurchaseProduct(definition.id, definition.price),
      isTrue,
    );
    ProgressStorage.setEquippedProductId('balloon', definition.id);
    FlamePreviewSkin? selectedSkin;
    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationGameFactory: (session, skin, initialStage, onFeedback) {
        selectedSkin = skin;
        return PoppopGame(
          session,
          initialStage: initialStage,
          initialSkin: skin,
          onGameplayFeedback: onFeedback,
        );
      },
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start-section-1')));
    await tester.pump();
    expect(selectedSkin, FlamePreviewSkin.heart);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('equipped store preview starts one current-skin Integration game',
      (tester) async {
    ProgressStorage.advanceNextPlayableStage(21);
    late PoppopGame game;
    var createCount = 0;
    FlamePreviewSkin? selectedSkin;
    int? initialStage;
    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationGameFactory: (session, skin, stage, onFeedback) {
        createCount++;
        selectedSkin = skin;
        initialStage = stage;
        return game = PoppopGame(
          session,
          initialStage: stage,
          initialSkin: skin,
          onGameplayFeedback: onFeedback,
        );
      },
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('store-product-balloon-default')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('착용 완료!'), findsOneWidget);
    expect(find.byKey(const ValueKey('balloon-preview-action')), findsNothing);
    final play = tester.widget<FilledButton>(
      find.byKey(const ValueKey('balloon-preview-play')),
    );
    play.onPressed!.call();
    play.onPressed!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await game.loaded;
    await tester.pump();

    expect(createCount, 1);
    expect(selectedSkin, FlamePreviewSkin.basic);
    expect(initialStage, 21);
    expect(find.byType(GameWidget<PoppopGame>), findsOneWidget);
    expect(
      find.byKey(const ValueKey('balloon-preview-dialog')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('store-product-grid')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(game.isShutdown, isTrue);
  });

  testWidgets('store preview home action creates no gameplay and keeps equip',
      (tester) async {
    var createCount = 0;
    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationGameFactory: (session, skin, stage, onFeedback) {
        createCount++;
        return PoppopGame(
          session,
          initialStage: stage,
          initialSkin: skin,
          onGameplayFeedback: onFeedback,
        );
      },
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('home-nav-shop')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('store-product-balloon-default')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('balloon-preview-home')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(createCount, 0);
    expect(find.byType(GameWidget<PoppopGame>), findsNothing);
    expect(find.byType(HomeFloatingBalloons), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-nav-selected-home')),
      findsOneWidget,
    );
    expect(
      ProgressStorage.equippedProductId('balloon'),
      anyOf(isNull, 'balloon-default'),
    );
  });

  for (final viewport in <Size>[
    const Size(360, 640),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1365, 932),
  ]) {
    testWidgets(
        'compact HUD is stable at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = ValueNotifier(const GameHeaderData(
        stage: 1,
        score: 123456,
        remaining: 99,
        secondsLeft: 10,
        controlsEnabled: true,
      ));
      addTearDown(data.dispose);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: GameHeader(data: data, onPause: () {}, onEnd: () {}),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('STAGE 01'), findsOneWidget);
      expect(find.byType(PoppopCompactLogo), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('game-poppop-logo'))).height,
        lessThan(20),
      );
      expect(find.byKey(const ValueKey('game-hud-panel')), findsOneWidget);
      expect(find.byKey(const ValueKey('hud-score')), findsOneWidget);
      expect(find.byKey(const ValueKey('hud-remaining')), findsOneWidget);
      expect(find.byKey(const ValueKey('hud-time')), findsOneWidget);
      expect(find.bySemanticsLabel('일시정지'), findsOneWidget);
      expect(find.bySemanticsLabel('끝내기'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('pause-button'))),
        const Size(44, 44),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('end-button'))),
        const Size(44, 44),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('game-hud-panel'))).width,
        lessThanOrEqualTo(460),
      );

      data.value = const GameHeaderData(
        stage: 30,
        score: 123456,
        remaining: 99,
        secondsLeft: 4,
        controlsEnabled: true,
      );
      await tester.pump();
      expect(find.text('STAGE 30'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final skin in <FlamePreviewSkin>[
    FlamePreviewSkin.gemi,
    FlamePreviewSkin.shushu,
  ]) {
    testWidgets(
        '${skin.label} integration keeps HUD above one persistent GameWidget',
        (tester) async {
      final definition = skin.catalogDefinition;
      ProgressStorage.addCoins(definition.price);
      expect(
        ProgressStorage.tryPurchaseProduct(definition.id, definition.price),
        isTrue,
      );
      ProgressStorage.setEquippedProductId('balloon', definition.id);
      late PoppopGame game;
      late GameSessionState session;
      var createCount = 0;
      await tester.pumpWidget(PoppopAppEntry(
        engineMode: PoppopEngineMode.flameIntegration,
        integrationGameFactory: (created, selected, stage, onFeedback) {
          createCount++;
          session = created;
          return game = PoppopGame(
            created,
            initialStage: stage,
            initialSkin: selected,
            legendaryImageLoader: _testLegendaryImageLoader,
            onGameplayFeedback: onFeedback,
            renderLegendaryBackground: false,
            showDiagnostics: false,
          );
        },
      ));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('start-section-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await game.loaded;
      await tester.pump();

      if (skin == FlamePreviewSkin.shushu) {
        final body = game.balloonComponents.first;
        expect(body.useSourceAspectGeometry, isTrue);
        expect(body.destinationRect.width, lessThan(body.size.x));
        expect(body.destinationRect.height, closeTo(body.size.x, .0001));
        expect(
          body.destinationRect.width / body.destinationRect.height,
          closeTo(shushuSourceAspectRatio, .0001),
        );
        expect(
          body.containsLocalPoint(Vector2(
            body.bodyRect.center.dx,
            body.bodyRect.center.dy,
          )),
          isTrue,
        );
      }

      expect(createCount, 1);
      expect(game.hasLegendaryBackground, isFalse);
      expect(
        find.byKey(
          const ValueKey('flame-integration-fullscreen-background'),
        ),
        findsOneWidget,
      );
      expect(find.byType(BalloonBackgroundRenderer), findsOneWidget);
      expect(find.byType(GameplaySkyBackground), findsNothing);
      expect(find.byKey(const ValueKey('pause-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('end-button')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('flame-integration-playfield-clip')),
        findsOneWidget,
      );
      final gameWidget = tester.widget<GameWidget<PoppopGame>>(
        find.byKey(const ValueKey('flame-integration-game-widget')),
      );
      final routeRect = tester.getRect(
        find.byKey(const ValueKey('flame-integration-gameplay')),
      );
      final backgroundRect = tester.getRect(
        find.byKey(
          const ValueKey('flame-integration-fullscreen-background'),
        ),
      );
      final headerRect = tester.getRect(
        find.byKey(const ValueKey('flame-integration-hud-layer')),
      );
      final playfieldRect = tester.getRect(
        find.byKey(const ValueKey('flame-integration-playfield-clip')),
      );
      expect(backgroundRect, routeRect);
      expect(backgroundRect.contains(headerRect.center), isTrue);
      expect(backgroundRect.contains(playfieldRect.center), isTrue);
      expect(playfieldRect.top, headerRect.bottom);
      final header = tester.widget<GameHeader>(find.byType(GameHeader));
      final hiddenHome = find.byType(
        HomeFloatingBalloons,
        skipOffstage: false,
      );
      expect(hiddenHome, findsNothing);
      expect(
        find.byKey(
          const ValueKey('flame-integration-production-suspended'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );

      expect(game.balloonComponents.first.requestHit(), isTrue);
      if (skin == FlamePreviewSkin.gemi) {
        expect(game.isBackgroundEffectActive, isTrue);
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<GameWidget<PoppopGame>>(
          find.byKey(const ValueKey('flame-integration-game-widget')),
        ),
        same(gameWidget),
      );
      expect(tester.widget<GameHeader>(find.byType(GameHeader)), same(header));
      expect(createCount, 1);

      final remaining = session.remainingBalloons;
      await tester.tap(find.byKey(const ValueKey('pause-button')));
      await tester.pump();
      expect(session.phase, GameSessionPhase.paused);
      expect(session.remainingBalloons, remaining);
      await tester.tap(find.byKey(const ValueKey('flame-integration-resume')));
      await tester.pump();
      expect(session.phase, GameSessionPhase.playing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(game.isShutdown, isTrue);
    });
  }

  testWidgets('WARI integration prepares sound before the first accepted pop',
      (tester) async {
    final definition = FlamePreviewSkin.wari.catalogDefinition;
    ProgressStorage.addCoins(definition.price);
    expect(
      ProgressStorage.tryPurchaseProduct(definition.id, definition.price),
      isTrue,
    );
    ProgressStorage.setEquippedProductId('balloon', definition.id);
    PopSound.resetDebug();
    late PoppopGame game;
    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationDebugConfig: const FlameIntegrationDebugConfig(
        enabled: true,
        stage: 2,
        skin: FlamePreviewSkin.wari,
      ),
      integrationGameFactory: (session, skin, stage, onFeedback) {
        return game = PoppopGame(
          session,
          initialStage: stage,
          initialSkin: skin,
          legendaryImageLoader: _testLegendaryImageLoader,
          onGameplayFeedback: onFeedback,
          showDiagnostics: false,
        );
      },
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start-section-1')));
    await tester.pump();
    expect(PopSound.gameplayAssetPrepareCount, 1);
    expect(PopSound.preparedGameplayAssetCount, 1);
    expect(
      PopSound.activeGameplayVoiceCount,
      PopSound.rapidGameplayVoiceCount,
    );
    expect(PopSound.playingGameplayVoiceCount, 0);
    expect(PopSound.readyGameplayAssetCount, 1);
    expect(PopSound.gameplayPendingPrepareCount, 0);
    expect(PopSound.gameplayListenerCount, 0);
    expect(PopSound.lastPreparedAssetPath, definition.popSoundAssetPath);
    await tester.pump(const Duration(milliseconds: 100));
    await game.loaded;
    await tester.tap(find.byKey(const ValueKey('pause-button')));
    await tester.pump();
    expect(PopSound.gameplayAssetPauseCount, 1);
    expect(PopSound.playingGameplayVoiceCount, 0);
    await tester.tap(find.byKey(const ValueKey('flame-integration-resume')));
    await tester.pump();
    final prepared = PopSound.gameplayAssetPrepareCount;
    final playsBeforePop = PopSound.gameplayAssetPlayCount;
    final singlePlaysBeforePop = PopSound.assetPlayCount;
    final balloons = game.balloonComponents.toList();
    expect(balloons[0].requestHit(), isTrue);
    expect(balloons[1].requestHit(), isTrue);
    expect(PopSound.gameplayAssetPlayCount, playsBeforePop + 2);
    expect(PopSound.assetPlayCount, singlePlaysBeforePop);
    expect(PopSound.lastAssetPath, definition.popSoundAssetPath);
    expect(PopSound.gameplayAssetPrepareCount, prepared);
    expect(balloons[0].requestHit(), isFalse);
    expect(PopSound.gameplayAssetPlayCount, playsBeforePop + 2);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('end-button')));
    await tester.pump();
    await tester.tap(find.text('끝내기').last);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(game.isShutdown, isTrue);
    expect(PopSound.activeGameplayVoiceCount, 0);
    expect(PopSound.playingGameplayVoiceCount, 0);
    expect(PopSound.readyGameplayAssetCount, 0);
    expect(PopSound.gameplayListenerCount, 0);
    final playsAfterExit = PopSound.gameplayAssetPlayCount;
    expect(balloons[0].requestHit(), isFalse);
    expect(PopSound.gameplayAssetPlayCount, playsAfterExit);
  });

  test('Flame gameplay audio uses bounded reusable voices', () async {
    const path = 'assets/sounds/test.mp3';
    PopSound.resetDebug();
    await PopSound.prepareGameplayAsset(path);
    await PopSound.prepareGameplayAsset(path);
    expect(PopSound.gameplayAssetPrepareCount, 1);
    expect(PopSound.activeGameplayVoiceCount, PopSound.gameplayVoiceCount);
    expect(PopSound.playingGameplayVoiceCount, 0);
    expect(PopSound.readyGameplayAssetCount, 1);
    expect(PopSound.gameplayPendingPrepareCount, 0);
    expect(PopSound.gameplayListenerCount, 0);
    for (var hit = 0; hit < PopSound.gameplayVoiceCount * 3; hit++) {
      PopSound.playGameplayAsset(path);
    }
    expect(PopSound.gameplayAssetPlayCount, PopSound.gameplayVoiceCount * 3);
    expect(PopSound.activeGameplayVoiceCount, PopSound.gameplayVoiceCount);
    PopSound.setEnabled(false);
    PopSound.playGameplayAsset(path);
    expect(PopSound.gameplayAssetPlayCount, PopSound.gameplayVoiceCount * 3);
    PopSound.setEnabled(true);
    PopSound.releaseGameplayAsset(path);
    expect(PopSound.activeGameplayVoiceCount, 0);
    expect(PopSound.playingGameplayVoiceCount, 0);
    expect(PopSound.readyGameplayAssetCount, 0);
    await PopSound.prepareGameplayAsset(path);
    expect(PopSound.activeGameplayVoiceCount, PopSound.gameplayVoiceCount);
    PopSound.releaseGameplayAsset(path);
    expect(PopSound.activeGameplayVoiceCount, 0);
    expect(PopSound.playingGameplayVoiceCount, 0);
    expect(PopSound.readyGameplayAssetCount, 0);
  });

  test('disabled sound does not prepare gameplay players', () async {
    const path = 'assets/sounds/test-disabled.mp3';
    PopSound.resetDebug();
    PopSound.setEnabled(false);
    await PopSound.prepareGameplayAsset(path);
    expect(PopSound.gameplayAssetPrepareCount, 0);
    expect(PopSound.preparedGameplayAssetCount, 0);
    expect(PopSound.activeGameplayVoiceCount, 0);
    expect(PopSound.playingGameplayVoiceCount, 0);
    expect(PopSound.readyGameplayAssetCount, 0);
    expect(PopSound.gameplayPendingPrepareCount, 0);
    PopSound.setEnabled(true);
  });

  testWidgets('SHUSHU integration prepares hit and pop voice pools',
      (tester) async {
    final definition = FlamePreviewSkin.shushu.catalogDefinition;
    ProgressStorage.addCoins(definition.price);
    expect(
      ProgressStorage.tryPurchaseProduct(definition.id, definition.price),
      isTrue,
    );
    ProgressStorage.setEquippedProductId('balloon', definition.id);
    PopSound.resetDebug();
    late PoppopGame game;
    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationGameFactory: (session, skin, stage, onFeedback) {
        return game = PoppopGame(
          session,
          initialStage: stage,
          initialSkin: skin,
          legendaryImageLoader: _testLegendaryImageLoader,
          onGameplayFeedback: onFeedback,
          showDiagnostics: false,
        );
      },
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start-section-1')));
    await tester.pump();
    expect(PopSound.preparedGameplayAssetCount, 2);
    expect(
      PopSound.activeGameplayVoiceCount,
      PopSound.gameplayVoiceCount * 2,
    );
    expect(PopSound.playingGameplayVoiceCount, 0);
    expect(PopSound.readyGameplayAssetCount, 2);
    expect(PopSound.gameplayPendingPrepareCount, 0);
    expect(PopSound.gameplayListenerCount, 0);
    await tester.pump(const Duration(milliseconds: 100));
    await game.loaded;
    final singlePlaysBeforePop = PopSound.assetPlayCount;
    expect(game.balloonComponents.first.requestHit(), isTrue);
    expect(PopSound.gameplayAssetPlayCount, 2);
    expect(PopSound.assetPlayCount, singlePlaysBeforePop);
    await tester.tap(find.byKey(const ValueKey('end-button')));
    await tester.pump();
    await tester.tap(find.text('끝내기').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(PopSound.activeGameplayVoiceCount, 0);
    expect(PopSound.playingGameplayVoiceCount, 0);
    expect(PopSound.readyGameplayAssetCount, 0);
    expect(PopSound.gameplayListenerCount, 0);
  });

  testWidgets('integration persists each stage clear once', (tester) async {
    late PoppopGame game;
    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationGameFactory: (session, skin, initialStage, onFeedback) {
        return game = PoppopGame(
          session,
          initialStage: initialStage,
          initialSkin: skin,
          onGameplayFeedback: onFeedback,
        );
      },
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start-section-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await game.loaded;
    await tester.pump();
    await _hitEveryBalloon(game);
    await tester.pump();
    expect(ProgressStorage.nextPlayableStage(), 2);
    final stale = game.balloonComponents.toList();
    expect(stale, isEmpty);
    await tester.pump(const Duration(milliseconds: 100));
    expect(ProgressStorage.nextPlayableStage(), 2);
    await game.jumpToStage(10);
    expect(game.startBossStage(), isTrue);
    final boss = game.bossComponents.single;
    for (var hit = 0; hit < 10; hit++) {
      expect(boss.requestHit(), isTrue);
    }
    await tester.pump();
    expect(ProgressStorage.isSecondSectionUnlocked(), isTrue);
    expect(ProgressStorage.nextPlayableStage(), 11);
    await game.jumpToStage(30);
    expect(game.startBossStage(), isTrue);
    for (var hit = 0; hit < stage30BossRule.maxHp; hit++) {
      final realId = game.sessionState.stage30RealBossId!;
      expect(
        game.bossComponents
            .singleWhere((candidate) => candidate.bossId == realId)
            .requestHit(),
        isTrue,
      );
    }
    await tester.pump();
    expect(ProgressStorage.nextPlayableStage(), 31);
  });

  testWidgets('integration section intro pauses time until acknowledged',
      (tester) async {
    ProgressStorage.unlockSecondSection();
    late PoppopGame game;
    late GameSessionState session;
    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationGameFactory: (created, skin, initialStage, onFeedback) {
        session = created;
        return game = PoppopGame(
          created,
          initialStage: initialStage,
          initialSkin: skin,
          onGameplayFeedback: onFeedback,
          showDiagnostics: false,
        );
      },
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start-section-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await game.loaded;
    await tester.pump();
    expect(find.byKey(const ValueKey('flame-integration-stage-intro')),
        findsOneWidget);
    expect(session.phase, GameSessionPhase.paused);
    final seconds = session.secondsLeft;
    await tester.pump(const Duration(milliseconds: 300));
    expect(session.secondsLeft, seconds);
    await tester
        .tap(find.byKey(const ValueKey('flame-integration-stage-intro-next')));
    await tester.pump();
    expect(session.phase, GameSessionPhase.playing);
  });

  testWidgets('endless integration saves result once and restarts one game',
      (tester) async {
    ProgressStorage.advanceNextPlayableStage(31);
    ProgressStorage.addCoins(500);
    final metrics = FlameIntegrationMetrics();
    late PoppopGame game;
    late GameSessionState session;
    var saveCalls = 0;
    await tester.pumpWidget(MaterialApp(
      home: FlameIntegrationGamePage(
        initialStage: 1,
        skin: FlamePreviewSkin.basic,
        sessionId: 77,
        endlessMode: true,
        metrics: metrics,
        onFeedback: (_) {},
        onStageCompleted: (_) {},
        onEndlessFinished: (score) {
          saveCalls++;
          ProgressStorage.saveEndlessLastScore(score);
          final isNew = ProgressStorage.saveEndlessBestScore(score);
          return EndlessRecordResult(
            score: score,
            bestScore: ProgressStorage.endlessBestScore(),
            isNewBest: isNew,
          );
        },
        gameFactory: (created, skin, stage, onFeedback) {
          session = created;
          return game = PoppopGame(
            created,
            initialSkin: skin,
            endlessMode: true,
            showDiagnostics: false,
            onGameplayFeedback: onFeedback,
          );
        },
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await game.loaded;
    await tester.pump();

    final notificationsBeforeMovement = metrics.sessionNotificationCount;
    await tester.pump(const Duration(milliseconds: 200));
    expect(metrics.sessionNotificationCount, notificationsBeforeMovement);

    while (session.endlessMistakes < EndlessModeRules.mistakeLimit) {
      var fakes = game.balloonComponents.where((item) => item.isFake).toList();
      while (fakes.isEmpty) {
        final target =
            game.balloonComponents.firstWhere((item) => !item.isFake);
        while (session.balloonHpFor(target.balloonId) > 0) {
          target.requestHit();
        }
        await tester.pump();
        fakes = game.balloonComponents.where((item) => item.isFake).toList();
      }
      fakes.first.requestHit();
      await tester.pump();
    }

    expect(find.byKey(const ValueKey('endless-current-score')), findsOneWidget);
    expect(find.byKey(const ValueKey('endless-best-score')), findsOneWidget);
    expect(saveCalls, 1);
    expect(ProgressStorage.endlessLastScore(), session.score);
    expect(ProgressStorage.coinBalance(), 500);
    expect(ProgressStorage.nextPlayableStage(), 31);
    await tester.tap(find.byKey(const ValueKey('endless-restart')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('endless-current-score')), findsNothing);
    expect(session.score, 0);
    expect(session.endlessMistakes, 0);
    expect(game.activeBalloonCount, EndlessModeRules.activeBalloonLimit);
    expect(metrics.activeGameInstances, 1);
    expect(metrics.activeGameWidgetInstances, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(saveCalls, 1);

    final exitTarget = game.balloonComponents.firstWhere(
      (item) => !item.isFake,
    );
    while (session.balloonHpFor(exitTarget.balloonId) > 0) {
      exitTarget.requestHit();
    }
    await tester.pump();
    final exitScore = session.score;
    await tester.tap(find.byKey(const ValueKey('end-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '끝내기'));
    await tester.pump();
    expect(saveCalls, 2);
    expect(ProgressStorage.endlessLastScore(), exitScore);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(game.isShutdown, isTrue);
    expect(metrics.activeGameInstances, 0);
    expect(metrics.activeGameWidgetInstances, 0);
    expect(metrics.lifecycleObserverCount, 0);
  });

  testWidgets(
      'integration feedback is accepted-hit only and stops after dispose',
      (tester) async {
    final events = <FlameGameplayFeedbackEvent>[];
    final session = GameSessionState();
    final game = PoppopGame(
      session,
      onGameplayFeedback: events.add,
    );
    game.onGameResize(Vector2(320, 480));
    await game.onLoad();
    final balloon = game.balloonComponents.first;
    expect(balloon.requestHit(), isTrue);
    expect(events.single.kind, FlameGameplayFeedbackKind.balloonPop);
    expect(balloon.requestHit(), isFalse);
    expect(events, hasLength(1));
    game.shutdown();
    expect(balloon.requestHit(), isFalse);
    expect(events, hasLength(1));
    session.dispose();
  });

  testWidgets('integration emits semantic feedback for multi-hit fake and boss',
      (tester) async {
    final events = <FlameGameplayFeedbackEvent>[];
    final session = GameSessionState();
    final game = PoppopGame(
      session,
      initialStage: 11,
      stage30SwapRoll: () => 1,
      onGameplayFeedback: events.add,
    );
    game.onGameResize(Vector2(320, 520));
    await game.onLoad();
    final balloon = game.balloonComponents.first;
    expect(balloon.requestHit(), isTrue);
    expect(events.last.kind, FlameGameplayFeedbackKind.balloonFirstHit);
    expect(balloon.requestHit(), isTrue);
    expect(events.last.kind, FlameGameplayFeedbackKind.balloonPop);

    await game.jumpToStage(21);
    final fake = game.balloonComponents.firstWhere((item) => item.isFake);
    expect(fake.requestHit(), isTrue);
    expect(events.last.kind, FlameGameplayFeedbackKind.fakeHit);

    await game.jumpToStage(20);
    expect(events.last.kind, FlameGameplayFeedbackKind.bossReady);
    expect(game.startBossStage(), isTrue);
    expect(game.bossComponents.first.requestHit(), isTrue);
    expect(events.last.kind, FlameGameplayFeedbackKind.bossHit);
    game.shutdown();
    session.dispose();
  });

  testWidgets('KICKS feedback fires at exit start without delayed duplicate',
      (tester) async {
    final events = <FlameGameplayFeedbackEvent>[];
    late PoppopGame game;
    await tester.pumpWidget(MaterialApp(
      home: FlameGamePage(
        initialSkin: FlamePreviewSkin.kicks,
        onExit: () {},
        gameFactory: (session) => game = PoppopGame(
          session,
          initialSkin: FlamePreviewSkin.kicks,
          legendaryImageLoader: _testLegendaryImageLoader,
          onGameplayFeedback: events.add,
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await game.loaded;
    final balloon = game.balloonComponents.first;
    expect(balloon.requestHit(), isTrue);
    expect(events.single.kind, FlameGameplayFeedbackKind.kickExitStarted);
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(events, hasLength(1));
  });

  testWidgets('integration terminal result saves score and coins exactly once',
      (tester) async {
    late PoppopGame game;
    var createCount = 0;
    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationGameFactory: (session, skin, initialStage, onFeedback) {
        createCount++;
        return game = PoppopGame(
          session,
          initialStage: initialStage,
          initialSkin: skin,
          stage30SwapRoll: () => 1,
          onGameplayFeedback: onFeedback,
        );
      },
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start-section-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await game.loaded;
    await game.jumpToStage(30);
    expect(game.startBossStage(), isTrue);
    final real = game.bossComponents.firstWhere((boss) => !boss.isFake);
    for (var hit = 0; hit < 12; hit++) {
      expect(real.requestHit(), isTrue);
    }
    final terminalScore = game.sessionState.score;
    expect(terminalScore, greaterThan(0));
    await _pumpTransition(tester, 1.1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byKey(const ValueKey('result-earned-coins')), findsOneWidget);
    expect(ProgressStorage.lastScore(), terminalScore);
    expect(ProgressStorage.bestScore(), terminalScore);
    expect(CoinService.balance, CoinService.rewardForScore(terminalScore));
    final savedCoins = CoinService.balance;
    final completedGame = game;
    expect(real.requestHit(), isFalse);
    await tester.pump(const Duration(milliseconds: 100));
    expect(CoinService.balance, savedCoins);
    await tester.tap(find.byKey(const ValueKey('result-retry-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(createCount, 2);
    expect(completedGame.isShutdown, isTrue);
    expect(game, isNot(same(completedGame)));
    expect(find.byType(GameWidget<PoppopGame>), findsOneWidget);
    expect(CoinService.balance, savedCoins);
  });

  test('integration feedback obeys production sound and haptic settings', () {
    var haptics = 0;
    HapticService.setPerformerForTest(() async => haptics++);
    addTearDown(HapticService.resetPerformerForTest);
    PopSound.resetDebug();
    playFlameGameplayFeedback(const FlameGameplayFeedbackEvent(
      kind: FlameGameplayFeedbackKind.balloonPop,
      skinId: BalloonSkinCatalog.defaultId,
    ));
    expect(PopSound.basicPlayCount, 1);
    expect(haptics, 1);

    SettingsService.setSoundEnabled(false);
    SettingsService.setHapticEnabled(false);
    playFlameGameplayFeedback(const FlameGameplayFeedbackEvent(
      kind: FlameGameplayFeedbackKind.fakeHit,
      skinId: BalloonSkinCatalog.defaultId,
    ));
    expect(PopSound.fakePlayCount, 0);
    expect(haptics, 1);
  });

  testWidgets('preview stage shortcut starts selected stage without production',
      (tester) async {
    final harness = await _pumpPreview(tester, initialStage: 21);
    expect(harness.session.stage, 21);
    expect(harness.game.activeBalloonCount, 4);
    expect(harness.session.remainingBalloons, 2);
    expect(harness.session.fakeCount, 2);
    expect(find.byType(BalloonGamePage), findsNothing);
    await harness.game.jumpToStage(999);
    await tester.pump();
    expect(harness.session.stage, 1);
    expect(harness.session.score, 0);
  });

  testWidgets('preview stage menu jumps to a requested production stage',
      (tester) async {
    final harness = await _pumpPreview(tester);
    await tester.tap(find.byKey(const ValueKey('flame-preview-stage-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('STAGE 30'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.session.stage, 30);
    expect(harness.session.phase, GameSessionPhase.bossReady);
    expect(harness.session.score, 0);
  });

  testWidgets('GEMI Stage 1 has two bodies background and synchronized ids',
      (tester) async {
    final harness = await _pumpPreview(
      tester,
      skin: FlamePreviewSkin.gemi,
    );
    expect(harness.game.selectedSkin, FlamePreviewSkin.gemi);
    expect(harness.game.activeBalloonCount, 2);
    expect(harness.session.remainingBalloons, 2);
    expect(harness.game.isComponentStateSynchronized, isTrue);
    expect(harness.game.hasLegendaryBackground, isTrue);
    expect(harness.game.skinRuntime.legendaryCache!.bodyImageCount, 8);
    expect(harness.game.activeCacheImageCount, lessThanOrEqualTo(16));
  });

  testWidgets(
      'GEMI Canvas and Flame cache reuse the precomposed Fake source alpha',
      (tester) async {
    final definition = legendaryDefinitionFor(FlamePreviewSkin.gemi);
    final color = definition.catalog.colorPalette.first;
    final canvasReal = Balloon(
      id: 1,
      position: Offset.zero,
      velocity: Offset.zero,
      color: color,
      size: 100,
      floatPhase: 0,
      floatPower: 0,
      hp: 1,
      maxHp: 1,
      skinId: definition.catalog.id,
    );
    final canvasFake = Balloon(
      id: 2,
      position: Offset.zero,
      velocity: Offset.zero,
      color: color,
      size: 100,
      floatPhase: 0,
      floatPower: 0,
      hp: 1,
      maxHp: 1,
      skinId: definition.catalog.id,
      isFake: true,
    );
    expect(canvasReal.spriteAssetPath,
        definition.catalog.runtimeColorAssetPaths[color.toARGB32()]);
    expect(canvasFake.spriteAssetPath,
        definition.catalog.runtimeFakeColorAssetPaths[color.toARGB32()]);
    expect(canvasReal.spriteOpacity, 1);
    expect(canvasFake.spriteOpacity, 1);
    expect(canvasReal.spriteColorMatrix, isNull);
    expect(canvasFake.spriteColorMatrix, isNull);

    final cache = LegendarySpriteCache(definition);
    addTearDown(cache.dispose);
    await tester.runAsync(() => cache.prepareForStage(boss: false));
    final realImage = cache.bodyImage(color, fake: false);
    final fakeImage = cache.bodyImage(color, fake: true);
    final alphas = await tester.runAsync(() async => <int>[
          await _maxImageAlpha(realImage),
          await _maxImageAlpha(fakeImage),
        ]);
    expect(alphas, <int>[255, 89]);
    expect(fakeImage.width, realImage.width);
    expect(fakeImage.height, realImage.height);
    expect(cache.bodyImageCount, 8);
    expect(cache.imageCount, 16);
    await tester.runAsync(() => cache.prepareForStage(boss: false));
    expect(cache.bodyImage(color, fake: false), same(realImage));
    expect(cache.bodyImage(color, fake: true), same(fakeImage));
  });

  testWidgets('GEMI Fake render opacity', (tester) async {
    final basicCache = BasicBalloonSpriteCache();
    addTearDown(basicCache.dispose);
    for (final skin in FlamePreviewSkin.values) {
      final runtime = FlameSkinRuntime(
        basicCache: basicCache,
        initialSkin: skin,
      );
      expect(
        runtime.fakeRenderOpacity,
        skin == FlamePreviewSkin.gemi ? 0.40 : 1,
      );
    }

    final stage21 = await _pumpPreview(
      tester,
      initialStage: 21,
      skin: FlamePreviewSkin.gemi,
    );
    expect(stage21.game.skinRuntime.baseSpriteOpacity, 1);
    expect(stage21.game.skinRuntime.fakeRenderOpacity, 0.40);
    expect(stage21.game.skinRuntime.fakeOpacity, 0.40);
    expect(stage21.game.balloonComponents.where((body) => body.isFake),
        hasLength(2));
    for (final body
        in stage21.game.balloonComponents.where((body) => body.isFake)) {
      final destination = body.destinationRect;
      expect(
        body.containsLocalPoint(
            Vector2(destination.center.dx, destination.center.dy)),
        isTrue,
      );
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final stage30 = await _pumpPreview(
      tester,
      initialStage: 30,
      skin: FlamePreviewSkin.gemi,
      swapRoll: () => 0,
    );
    expect(stage30.game.startBossStage(), isTrue);
    final originalReal =
        stage30.game.bossComponents.singleWhere((boss) => !boss.isFake);
    final originalFake =
        stage30.game.bossComponents.singleWhere((boss) => boss.isFake);
    expect(originalReal.baseSpriteOpacity, 1);
    expect(originalReal.fakeSpriteOpacity, 0.40);
    expect(originalFake.baseSpriteOpacity, 1);
    expect(originalFake.fakeSpriteOpacity, 0.40);
    final realGeometry = originalReal.destinationRect;
    final fakeGeometry = originalFake.destinationRect;
    expect(
        originalReal.containsLocalPoint(Vector2(
          realGeometry.center.dx,
          realGeometry.center.dy,
        )),
        isTrue);
    expect(
        originalFake.containsLocalPoint(Vector2(
          fakeGeometry.center.dx,
          fakeGeometry.center.dy,
        )),
        isTrue);
    expect(originalReal.requestHit(), isTrue);
    expect(originalReal.isFake, isTrue);
    expect(originalFake.isFake, isFalse);
    expect(originalReal.fakeSpriteOpacity, 0.40);
    expect(originalFake.fakeSpriteOpacity, 0.40);
    expect(
        originalReal.containsLocalPoint(Vector2(
          originalReal.destinationRect.center.dx,
          originalReal.destinationRect.center.dy,
        )),
        isTrue);
    expect(
        originalFake.containsLocalPoint(Vector2(
          originalFake.destinationRect.center.dx,
          originalFake.destinationRect.center.dy,
        )),
        isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final shushu = await _pumpPreview(
      tester,
      initialStage: 21,
      skin: FlamePreviewSkin.shushu,
    );
    expect(shushu.game.skinRuntime.fakeRenderOpacity, 1);
    expect(shushu.game.skinRuntime.fakeOpacity, 0.35);
  });

  testWidgets('GEMI Fake asset path is identical in Integration',
      (tester) async {
    late PoppopGame game;
    await tester.pumpWidget(PoppopAppEntry(
      engineMode: PoppopEngineMode.flameIntegration,
      integrationDebugConfig: const FlameIntegrationDebugConfig(
        enabled: true,
        stage: 21,
        skin: FlamePreviewSkin.gemi,
      ),
      integrationGameFactory: (session, skin, stage, onFeedback) {
        return game = PoppopGame(
          session,
          initialStage: stage,
          initialSkin: skin,
          legendaryImageLoader: _testLegendaryImageLoader,
          onGameplayFeedback: onFeedback,
          renderLegendaryBackground: false,
          showDiagnostics: false,
        );
      },
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('start-section-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await game.loaded;
    await tester.pump();
    expect(game.selectedSkin, FlamePreviewSkin.gemi);
    expect(game.balloonComponents.where((body) => body.isFake), hasLength(2));
    expect(game.skinRuntime.fakeOpacity, 0.40);
    expect(game.skinRuntime.legendaryCache!.bodyImageCount, 8);
  });

  testWidgets('GEMI two-hit shards are bounded and become fully idle',
      (tester) async {
    final harness = await _pumpPreview(
      tester,
      initialStage: 11,
      skin: FlamePreviewSkin.gemi,
    );
    final balloon = harness.game.balloonComponents.first;
    expect(balloon.requestHit(), isTrue);
    expect(balloon.visualHp, 1);
    expect(harness.session.remainingBalloons, 2);
    expect(harness.game.activeEffectCount, 1);
    expect(harness.game.activeParticleCount, lessThanOrEqualTo(16));
    expect(harness.game.isBackgroundEffectActive, isTrue);
    for (var frame = 0; frame < 28; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(harness.game.activeEffectCount, 0);
    expect(harness.game.activeParticleCount, 0);
    expect(harness.game.isBackgroundEffectActive, isFalse);
  });

  testWidgets(
      'SHUSHU uses precomposed cached body and breathe for normal and fake',
      (tester) async {
    final harness = await _pumpPreview(
      tester,
      initialStage: 21,
      skin: FlamePreviewSkin.shushu,
    );
    expect(harness.game.selectedSkin, FlamePreviewSkin.shushu);
    expect(harness.game.activeBalloonCount, 4);
    expect(harness.session.remainingBalloons, 2);
    expect(harness.session.fakeCount, 2);
    expect(harness.game.balloonComponents.every((b) => b.breatheIdle), isTrue);
    final body = harness.game.balloonComponents.first;
    expect(body.containsLocalPoint(body.size / 2), isTrue);
    expect(body.containsLocalPoint(Vector2.zero()), isFalse);
    expect(harness.game.skinRuntime.legendaryCache!.bodyImageCount, 1);
    final cache = harness.game.skinRuntime.legendaryCache!;
    expect(cache.matteCleanupCount, 0);
    expect(cache.loadedAssetPaths,
        contains('assets/images/balloon_shushu_canvas_runtime.png'));
  });

  testWidgets(
      'SHUSHU source aspect geometry drives body hit bounds and effect origin',
      (tester) async {
    final harness = await _pumpPreview(
      tester,
      initialStage: 11,
      skin: FlamePreviewSkin.shushu,
    );
    final balloon = harness.game.balloonComponents.first;
    expect(balloon.useSourceAspectGeometry, isTrue);
    expect(
      balloon.destinationRect.width / balloon.destinationRect.height,
      closeTo(shushuSourceAspectRatio, .0001),
    );
    expect(
      balloon.visualBoundsInParent.width / balloon.visualBoundsInParent.height,
      closeTo(balloon.bodyRect.width / balloon.bodyRect.height, .0001),
    );
    expect(balloon.destinationRect.width, lessThanOrEqualTo(balloon.size.x));
    expect(balloon.destinationRect.height, lessThanOrEqualTo(balloon.size.x));
    expect(balloon.bodyRect.left, greaterThan(balloon.destinationRect.left));
    expect(balloon.bodyRect.right, lessThan(balloon.destinationRect.right));
    expect(balloon.currentVisualScale, inInclusiveRange(.982, 1.018));
    expect(
      balloon.containsLocalPoint(Vector2(
        balloon.bodyRect.center.dx,
        balloon.bodyRect.center.dy,
      )),
      isTrue,
    );
    expect(
      balloon.containsLocalPoint(
        Vector2(
          (balloon.destinationRect.left + balloon.bodyRect.left) / 2,
          balloon.bodyRect.center.dy,
        ),
      ),
      isFalse,
    );
    final firstOrigin = balloon.visualCenterInParent;
    expect(balloon.requestHit(), isTrue);
    expect(
      harness.game.lastEffectOrigin,
      isNotNull,
    );
    expect(harness.game.lastEffectOrigin!.x, closeTo(firstOrigin.dx, .0001));
    expect(harness.game.lastEffectOrigin!.y, closeTo(firstOrigin.dy, .0001));
    expect(
      balloon.destinationRect.width / balloon.destinationRect.height,
      closeTo(shushuSourceAspectRatio, .0001),
    );
    expect(
      balloon.containsLocalPoint(Vector2(
        balloon.bodyRect.center.dx,
        balloon.bodyRect.center.dy,
      )),
      isTrue,
    );
  });

  testWidgets(
      'SHUSHU Boss and Stage 30 share source aspect body and touch geometry',
      (tester) async {
    for (final stage in <int>[20, 30]) {
      final harness = await _pumpPreview(
        tester,
        initialStage: stage,
        skin: FlamePreviewSkin.shushu,
        swapRoll: () => 1,
      );
      expect(harness.game.startBossStage(), isTrue);
      final boss =
          harness.game.bossComponents.firstWhere((item) => !item.isFake);
      expect(boss.useSourceAspectGeometry, isTrue);
      expect(
        boss.destinationRect.width / boss.destinationRect.height,
        closeTo(shushuSourceAspectRatio, .0001),
      );
      expect(
        boss.visualBoundsInParent.width / boss.visualBoundsInParent.height,
        closeTo(boss.bodyRect.width / boss.bodyRect.height, .0001),
      );
      expect(boss.destinationRect.width, lessThanOrEqualTo(boss.size.x));
      expect(boss.destinationRect.height, lessThanOrEqualTo(boss.size.x));
      final localCenter = boss.bodyRect.center;
      expect(
        boss.containsLocalPoint(Vector2(localCenter.dx, localCenter.dy)),
        isTrue,
      );
      expect(
        boss.containsLocalPoint(Vector2(
          (boss.destinationRect.left + boss.bodyRect.left) / 2,
          boss.bodyRect.center.dy,
        )),
        isFalse,
      );
      expect(boss.healthTrackRect.center.dx,
          closeTo(boss.bodyRect.center.dx, .0001));
      expect(
          boss.healthTrackRect.top, closeTo(boss.bodyRect.bottom + 8, .0001));
      final effectCenter = boss.visualCenterInParent;
      expect(
        boss.requestHit(
          worldPoint: Vector2(effectCenter.dx, effectCenter.dy),
        ),
        isTrue,
      );
      expect(harness.game.lastEffectOrigin!.x, closeTo(effectCenter.dx, .0001));
      expect(harness.game.lastEffectOrigin!.y, closeTo(effectCenter.dy, .0001));
      expect(
        boss.destinationRect.width / boss.destinationRect.height,
        closeTo(shushuSourceAspectRatio, .0001),
      );
      expect(
        harness.game.activeCacheImageCount,
        lessThanOrEqualTo(6),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets(
      'SHUSHU Integration normal and two-hit components use the real runtime body',
      (tester) async {
    for (final stage in <int>[1, 11, 21]) {
      final harness = await _pumpShushuIntegration(tester, stage: stage);
      final balloons = harness.game.balloonComponents;
      expect(balloons, isNotEmpty);
      for (final balloon in balloons) {
        _expectShushuComponentGeometry(
          destination: balloon.destinationRect,
          body: balloon.bodyRect,
          componentPosition: balloon.position,
          componentScaleX: balloon.scale.x,
          componentScaleY: balloon.scale.y,
          visualScale: balloon.currentVisualScale,
          containsLocalPoint: balloon.containsLocalPoint,
        );
      }
      if (stage == 11) {
        final balloon = balloons.first;
        expect(balloon.requestHit(), isTrue);
        expect(balloon.visualHp, 1);
        _expectShushuComponentGeometry(
          destination: balloon.destinationRect,
          body: balloon.bodyRect,
          componentPosition: balloon.position,
          componentScaleX: balloon.scale.x,
          componentScaleY: balloon.scale.y,
          visualScale: balloon.currentVisualScale,
          containsLocalPoint: balloon.containsLocalPoint,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(harness.game.isShutdown, isTrue);
    }
  });

  testWidgets(
      'SHUSHU Integration Stage 20 and 30 bosses share real render and hit geometry',
      (tester) async {
    for (final stage in <int>[20, 30]) {
      final harness = await _pumpShushuIntegration(tester, stage: stage);
      expect(harness.game.startBossStage(), isTrue);
      final bosses = harness.game.bossComponents;
      expect(bosses, isNotEmpty);
      if (stage == 30) {
        expect(bosses.any((boss) => boss.isFake), isTrue);
        expect(bosses.any((boss) => !boss.isFake), isTrue);
      }
      for (final boss in bosses) {
        _expectShushuComponentGeometry(
          destination: boss.destinationRect,
          body: boss.bodyRect,
          componentPosition: boss.position,
          componentScaleX: boss.scale.x,
          componentScaleY: boss.scale.y,
          visualScale: boss.currentVisualScale,
          containsLocalPoint: boss.containsLocalPoint,
        );
        expect(
          boss.healthTrackRect.center.dx,
          closeTo(boss.bodyRect.center.dx, .0001),
        );
      }
      final real = bosses.firstWhere((boss) => !boss.isFake);
      final oldHp = real.visualHp;
      expect(
        real.requestHit(
            worldPoint: Vector2(
          real.visualCenterInParent.dx,
          real.visualCenterInParent.dy,
        )),
        isTrue,
      );
      expect(real.visualHp, oldHp - 1);
      _expectShushuComponentGeometry(
        destination: real.destinationRect,
        body: real.bodyRect,
        componentPosition: real.position,
        componentScaleX: real.scale.x,
        componentScaleY: real.scale.y,
        visualScale: real.currentVisualScale,
        containsLocalPoint: real.containsLocalPoint,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(harness.game.isShutdown, isTrue);
    }
  });

  testWidgets('GEMI keeps its existing non-source-aspect geometry',
      (tester) async {
    final harness = await _pumpPreview(
      tester,
      initialStage: 30,
      skin: FlamePreviewSkin.gemi,
    );
    expect(
      harness.game.bossComponents.every(
        (boss) => !boss.useSourceAspectGeometry,
      ),
      isTrue,
    );
  });

  test('SHUSHU is the only skin using visible-body source geometry', () {
    final basicCache = BasicBalloonSpriteCache();
    addTearDown(basicCache.dispose);
    for (final skin in FlamePreviewSkin.values) {
      final runtime = FlameSkinRuntime(
        basicCache: basicCache,
        initialSkin: skin,
      );
      expect(
        runtime.usesSourceAspectGeometry,
        skin == FlamePreviewSkin.shushu,
        reason: skin.queryValue,
      );
    }
  });

  testWidgets('legendary Boss and Stage 30 retain shared gameplay rules',
      (tester) async {
    final gemi = await _pumpPreview(
      tester,
      initialStage: 20,
      skin: FlamePreviewSkin.gemi,
    );
    expect(gemi.game.activeBossCount, 2);
    expect(gemi.game.bossComponents.every((b) => b.drawHealthBarSeparately),
        isTrue);
    gemi.game.startBossStage();
    expect(gemi.game.bossComponents.first.requestHit(), isTrue);
    expect(gemi.session.bossHp, 29);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final shushu = await _pumpPreview(
      tester,
      initialStage: 30,
      skin: FlamePreviewSkin.shushu,
      swapRoll: () => 0,
    );
    shushu.game.startBossStage();
    final real = shushu.game.bossComponents.singleWhere((b) => !b.isFake);
    expect(real.breatheIdle, isTrue);
    expect(real.containsLocalPoint(real.size / 2), isTrue);
    expect(real.containsLocalPoint(Vector2.zero()), isFalse);
    expect(real.requestHit(), isTrue);
    expect(shushu.session.bossHp, 11);
    expect(shushu.game.activeBossCount, 2);
  });

  testWidgets(
      'preview skin selector releases old cache and restarts same stage',
      (tester) async {
    ProgressStorage.setEquippedProductId('balloon', 'balloon-wari');
    final harness = await _pumpPreview(
      tester,
      initialStage: 11,
      skin: FlamePreviewSkin.gemi,
    );
    final stale = harness.game.balloonComponents.first;
    final oldCache = harness.game.skinRuntime.legendaryCache!;
    await tester.tap(find.byKey(const ValueKey('flame-preview-skin-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SHUSHU').last);
    await tester.pump();
    for (var frame = 0;
        frame < 10 &&
            (harness.game.selectedSkin != FlamePreviewSkin.shushu ||
                harness.session.phase == GameSessionPhase.loading);
        frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(oldCache.isDisposed, isTrue);
    expect(harness.game.selectedSkin, FlamePreviewSkin.shushu);
    expect(harness.session.stage, 11);
    expect(harness.session.score, 0);
    expect(harness.session.remainingBalloons, 2);
    expect(harness.game.activeBalloonCount, 2);
    expect(harness.game.isComponentStateSynchronized, isTrue);
    expect(stale.requestHit(), isFalse);
    expect(ProgressStorage.equippedProductId('balloon'), 'balloon-wari');
    expect(find.byKey(const ValueKey('flame-preview-skin-selector')),
        findsOneWidget);
  });

  testWidgets('legendary body profiles replace rather than accumulate',
      (tester) async {
    final harness = await _pumpPreview(
      tester,
      initialStage: 19,
      skin: FlamePreviewSkin.gemi,
    );
    final cache = harness.game.skinRuntime.legendaryCache!;
    expect(cache.bodyProfile, LegendaryBodyProfile.normal);
    expect(cache.imageCount, 16);
    await harness.game.jumpToStage(20);
    await tester.pump();
    expect(identical(cache, harness.game.skinRuntime.legendaryCache), isTrue);
    expect(cache.bodyProfile, LegendaryBodyProfile.boss);
    expect(cache.bodyImageCount, 8);
    expect(cache.imageCount, 16);
    await harness.game.jumpToStage(21);
    await tester.pump();
    expect(cache.bodyProfile, LegendaryBodyProfile.normal);
    expect(cache.imageCount, 16);
  });

  testWidgets('legendary effects stay globally bounded under rapid Boss hits',
      (tester) async {
    final harness = await _pumpPreview(
      tester,
      initialStage: 20,
      skin: FlamePreviewSkin.shushu,
    );
    harness.game.startBossStage();
    final bosses = harness.game.bossComponents.toList();
    for (var hit = 0; hit < 14; hit++) {
      expect(bosses[0].requestHit(), isTrue);
      expect(bosses[1].requestHit(), isTrue);
    }
    expect(harness.game.activeEffectCount, lessThanOrEqualTo(12));
    expect(harness.game.activeParticleCount, lessThanOrEqualTo(192));
    expect(harness.session.bossHp, 2);
  });

  testWidgets('GEMI Stage Clear preserves background and advances exactly once',
      (tester) async {
    final harness = await _pumpPreview(
      tester,
      skin: FlamePreviewSkin.gemi,
    );
    await _hitEveryBalloon(harness.game);
    expect(harness.session.phase, GameSessionPhase.stageClear);
    expect(harness.session.remainingBalloons, 0);
    await _pumpTransition(tester, .5);
    expect(harness.session.stage, 2);
    expect(harness.session.remainingBalloons, 3);
    expect(harness.game.activeBalloonCount, 3);
    expect(harness.game.hasLegendaryBackground, isTrue);
    expect(harness.game.isComponentStateSynchronized, isTrue);
  });

  for (final skin in FlamePreviewSkin.values.where(
    (skin) => skin.usesCatalogImage,
  )) {
    testWidgets('${skin.label} uses common runtime across every stage type',
        (tester) async {
      final harness = await _pumpPreview(tester, skin: skin);
      expect(harness.game.selectedSkin, skin);
      expect(harness.game.activeBalloonCount, 2);
      expect(harness.game.isComponentStateSynchronized, isTrue);
      expect(harness.game.hasLegendaryBackground, isFalse);
      expect(harness.game.skinRuntime.catalogCache, isNotNull);
      expect(harness.game.activeCacheImageCount, greaterThan(0));

      await harness.game.jumpToStage(11);
      await tester.pump();
      final twoHit = harness.game.balloonComponents.first;
      expect(twoHit.requestHit(), isTrue);
      expect(twoHit.visualHp, 1);
      expect(harness.session.remainingBalloons, 2);
      expect(harness.game.isComponentStateSynchronized, isTrue);

      await harness.game.jumpToStage(20);
      await tester.pump();
      expect(harness.game.activeBossCount, 2);
      expect(
        harness.game.bossComponents
            .every((boss) => boss.drawHealthBarSeparately),
        isTrue,
      );

      await harness.game.jumpToStage(21);
      await tester.pump();
      expect(harness.game.activeBalloonCount, 4);
      expect(harness.game.balloonComponents.where((body) => body.isFake),
          hasLength(2));

      await harness.game.jumpToStage(30);
      await tester.pump();
      expect(harness.game.activeBossCount, 2);
      expect(harness.game.bossComponents.where((boss) => boss.isFake),
          hasLength(1));
      expect(harness.game.isComponentStateSynchronized, isTrue);
      final expectedImageCap = switch (skin) {
        FlamePreviewSkin.mochi => 25,
        FlamePreviewSkin.wari => 3,
        _ => 1,
      };
      expect(harness.game.activeCacheImageCount,
          lessThanOrEqualTo(expectedImageCap));
      expect(harness.game.activeCacheRgbaBytes, lessThan(40 * 1024 * 1024));
    });
  }

  testWidgets('catalog effects are bounded and return to idle', (tester) async {
    final harness = await _pumpPreview(
      tester,
      initialStage: 21,
      skin: FlamePreviewSkin.heart,
    );
    for (final balloon in harness.game.balloonComponents.toList()) {
      balloon.requestHit();
    }
    expect(
      harness.game.basicPopEffects.every(
        (effect) => effect.effectType == BalloonPopEffectType.hearts,
      ),
      isTrue,
    );
    expect(harness.game.activeEffectCount, lessThanOrEqualTo(12));
    expect(harness.game.activeParticleCount, lessThanOrEqualTo(84));
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(harness.game.activeEffectCount, 0);
    expect(harness.game.activeParticleCount, 0);
  });

  testWidgets('WARI variants and BOO mist remain catalog-defined',
      (tester) async {
    final wari = await _pumpPreview(
      tester,
      initialStage: 29,
      skin: FlamePreviewSkin.wari,
    );
    expect(
      wari.game.balloonComponents.map((body) => body.visualVariant).toSet(),
      containsAll(<int>[0, 1, 2]),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final boo = await _pumpPreview(tester, skin: FlamePreviewSkin.boo);
    expect(boo.game.balloonComponents.first.requestHit(), isTrue);
    expect(
        boo.game.basicPopEffects.single.effectType, BalloonPopEffectType.mist);
  });

  testWidgets('KICKS exit completes once through the shared session',
      (tester) async {
    final harness = await _pumpPreview(tester, skin: FlamePreviewSkin.kicks);
    final balloon = harness.game.balloonComponents.first;
    expect(balloon.requestHit(), isTrue);
    expect(balloon.isExiting, isTrue);
    expect(harness.session.remainingBalloons, 2);
    expect(balloon.requestHit(), isFalse);
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(balloon.isRemovedFromGame, isTrue);
    expect(harness.session.remainingBalloons, 1);
    expect(harness.game.activeBalloonCount, 1);
    expect(harness.game.isComponentStateSynchronized, isTrue);
  });

  testWidgets('BOO retains ghost idle while static skins stay on fast path',
      (tester) async {
    final boo = await _pumpPreview(tester, skin: FlamePreviewSkin.boo);
    expect(boo.game.balloonComponents.every((body) => body.ghostIdle), isTrue);
    expect(
        boo.game.balloonComponents
            .every((body) => body.baseSpriteOpacity == .86),
        isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final mugi = await _pumpPreview(tester, skin: FlamePreviewSkin.mugi);
    expect(
        mugi.game.balloonComponents.every((body) => !body.ghostIdle), isTrue);
    expect(
        mugi.game.balloonComponents
            .every((body) => body.baseSpriteOpacity == 1),
        isTrue);
  });

  testWidgets('skin switch disposes catalog profile and rejects stale input',
      (tester) async {
    final harness = await _pumpPreview(tester, skin: FlamePreviewSkin.mochi);
    final oldCache = harness.game.skinRuntime.catalogCache!;
    final stale = harness.game.balloonComponents.first;
    await harness.game.switchSkin(FlamePreviewSkin.wari);
    await tester.pump();
    expect(oldCache.isDisposed, isTrue);
    expect(stale.requestHit(), isFalse);
    expect(harness.game.selectedSkin, FlamePreviewSkin.wari);
    expect(
        harness.game.skinRuntime.catalogCache!.definition.id, 'balloon-wari');
    expect(harness.game.isComponentStateSynchronized, isTrue);
  });

  testWidgets('Boss Ready freezes time movement and input until START',
      (tester) async {
    final harness = await _pumpPreview(tester, initialStage: 10);
    final boss = harness.game.bossComponents.single;
    final position = boss.position.clone();
    final seconds = harness.session.secondsLeft;
    expect(harness.session.phase, GameSessionPhase.bossReady);
    expect(boss.requestHit(), isFalse);
    await tester.pump(const Duration(milliseconds: 500));
    expect(boss.position, position);
    expect(harness.session.secondsLeft, seconds);
    await tester
        .tap(find.byKey(const ValueKey('flame-preview-boss-start-button')));
    await tester.pump();
    expect(harness.session.phase, GameSessionPhase.playing);
    expect(harness.game.startBossStage(), isFalse);
    await tester.pump(const Duration(milliseconds: 100));
    expect(boss.position, isNot(position));
  });

  testWidgets('background round trip preserves Boss Ready', (tester) async {
    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    final harness = await _pumpPreview(tester, initialStage: 20);
    final positions = harness.game.bossComponents
        .map((boss) => boss.position.clone())
        .toList();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(milliseconds: 200));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 200));
    expect(harness.session.phase, GameSessionPhase.bossReady);
    expect(harness.game.paused, isTrue);
    expect(harness.game.bossComponents.map((boss) => boss.position), positions);
  });

  testWidgets('manual pause and resume preserve the single preview loop',
      (tester) async {
    final harness = await _pumpPreview(tester);
    await tester.tap(find.byKey(const ValueKey('flame-preview-pause-button')));
    await tester.pump();
    final updates = harness.session.updateCount;
    final position = harness.game.balloonComponents.first.position.clone();
    await tester.pump(const Duration(milliseconds: 200));
    expect(harness.session.updateCount, updates);
    expect(harness.game.balloonComponents.first.position, position);
    await tester.tap(find.byKey(const ValueKey('flame-preview-pause-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(harness.session.updateCount, greaterThan(updates));
  });

  testWidgets('Stage 11 component survives first hit and clears on second',
      (tester) async {
    final harness = await _pumpPreview(tester, initialStage: 11);
    final balloon = harness.game.balloonComponents.first;
    final originalSize = balloon.size.x;
    expect(balloon.requestHit(), isTrue);
    expect(balloon.visualHp, 1);
    expect(balloon.size.x, closeTo(originalSize * .88, .0001));
    expect(harness.session.remainingBalloons, 2);
    expect(balloon.requestHit(), isTrue);
    expect(harness.session.remainingBalloons, 1);
    expect(balloon.requestHit(), isFalse);
  });

  testWidgets('Stage 20 multitouch keeps independent boss state',
      (tester) async {
    final harness = await _pumpPreview(tester, initialStage: 20);
    harness.game.startBossStage();
    await tester.pump();
    final bosses = harness.game.bossComponents.toList();
    final origin = tester
        .getTopLeft(find.byKey(const ValueKey('flame-preview-game-widget')));
    final first =
        await tester.startGesture(origin + _center(bosses[0]), pointer: 71);
    final second =
        await tester.startGesture(origin + _center(bosses[1]), pointer: 72);
    await tester.pump();
    expect(bosses[0].visualHp, 14);
    expect(bosses[1].visualHp, 14);
    expect(harness.session.bossHp, 28);
    await first.up();
    await second.up();
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('Stage 30 shared HP swaps roles without replacing components',
      (tester) async {
    final harness =
        await _pumpPreview(tester, initialStage: 30, swapRoll: () => 0);
    harness.game.startBossStage();
    final bosses = harness.game.bossComponents.toList();
    final generation = harness.game.componentGeneration;
    final real = bosses.firstWhere((boss) => !boss.isFake);
    final fake = bosses.firstWhere((boss) => boss.isFake);
    expect(fake.requestHit(), isTrue);
    expect(harness.session.secondsLeft, 16);
    expect(harness.session.bossHp, 12);
    expect(real.requestHit(), isTrue);
    expect(harness.session.bossHp, 11);
    expect(harness.session.stage30RealBossId, fake.bossId);
    expect(harness.game.componentGeneration, generation);
    expect(harness.game.activeBossCount, 2);
    expect(harness.game.isComponentStateSynchronized, isTrue);
  });

  testWidgets('key stage boundaries advance once through CORE CLEAR',
      (tester) async {
    final harness =
        await _pumpPreview(tester, initialStage: 9, swapRoll: () => 1);

    await _hitEveryBalloon(harness.game);
    await _pumpTransition(tester, .5);
    expect(harness.session.stage, 10);
    expect(harness.session.phase, GameSessionPhase.bossReady);
    harness.game.startBossStage();
    final stale10 = harness.game.bossComponents.single;
    for (var hit = 0; hit < 10; hit++) {
      expect(stale10.requestHit(), isTrue);
    }
    await _pumpTransition(tester, 1.1);
    expect(harness.session.stage, 11);
    expect(harness.session.remainingBalloons, 2);
    expect(stale10.requestHit(), isFalse);

    await harness.game.jumpToStage(19);
    await _hitEveryBalloon(harness.game);
    await _pumpTransition(tester, .5);
    expect(harness.session.stage, 20);
    expect(harness.session.phase, GameSessionPhase.bossReady);
    harness.game.startBossStage();
    for (final boss in harness.game.bossComponents.toList()) {
      for (var hit = 0; hit < 15; hit++) {
        expect(boss.requestHit(), isTrue);
      }
    }
    await _pumpTransition(tester, 1.1);
    expect(harness.session.stage, 21);
    expect(harness.session.remainingBalloons, 2);
    expect(harness.session.fakeCount, 2);

    await harness.game.jumpToStage(29);
    await _hitEveryBalloon(harness.game);
    await _pumpTransition(tester, .5);
    expect(harness.session.stage, 30);
    expect(harness.session.phase, GameSessionPhase.bossReady);
    harness.game.startBossStage();
    for (var hit = 0; hit < 12; hit++) {
      final realId = harness.session.stage30RealBossId!;
      final real = harness.game.bossComponents
          .singleWhere((boss) => boss.bossId == realId);
      expect(real.requestHit(), isTrue);
    }
    await _pumpTransition(tester, 1.1);
    expect(harness.session.phase, GameSessionPhase.coreClear);
    expect(harness.game.activeBossCount, 0);
    final generation = harness.game.componentGeneration;
    await _pumpTransition(tester, .5);
    expect(harness.game.componentGeneration, generation);
  });

  testWidgets('movement does not rebuild HUD and lifecycle pauses the loop',
      (tester) async {
    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    var builds = 0;
    final harness = await _pumpPreview(tester, onHudBuild: () => builds++);
    final balloon = harness.game.balloonComponents.first;
    final beforeBuilds = builds;
    final beforePosition = balloon.position.clone();
    await tester.pump(const Duration(milliseconds: 200));
    expect(balloon.position, isNot(beforePosition));
    expect(builds, beforeBuilds);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final pausedPosition = balloon.position.clone();
    final pausedTime = harness.session.secondsLeft;
    await tester.pump(const Duration(milliseconds: 300));
    expect(balloon.position, pausedPosition);
    expect(harness.session.secondsLeft, pausedTime);
  });

  testWidgets('TIME UP restart and stale input are safe', (tester) async {
    final harness = await _pumpPreview(tester, initialStage: 21);
    final stale = harness.game.balloonComponents.first;
    for (var i = 0; i < 400; i++) {
      harness.game.update(BalloonComponent.maxUpdateDelta);
      if (harness.session.phase == GameSessionPhase.failed) break;
    }
    expect(harness.session.phase, GameSessionPhase.failed);
    expect(harness.game.activeBalloonCount, 0);
    await harness.game.restartGame();
    await tester.pump();
    expect(harness.session.stage, 1);
    expect(harness.session.score, 0);
    expect(stale.requestHit(), isFalse);
    expect(harness.game.isComponentStateSynchronized, isTrue);
  });

  testWidgets(
      'endless game keeps bounded slots and cleans restart and terminal state',
      (tester) async {
    final harness = await _pumpEndless(tester);
    expect(
        harness.game.activeBalloonCount, EndlessModeRules.activeBalloonLimit);
    expect(harness.game.isComponentStateSynchronized, isTrue);

    for (var pop = 0; pop < 65; pop++) {
      final target = harness.game.balloonComponents.firstWhere(
        (balloon) => !balloon.isFake,
      );
      while (harness.session.balloonHpFor(target.balloonId) > 0) {
        expect(target.requestHit(), isTrue);
      }
      await tester.pump();
      expect(
          harness.game.activeBalloonCount, EndlessModeRules.activeBalloonLimit);
      expect(harness.session.fakeCount,
          lessThanOrEqualTo(EndlessModeRules.activeFakeLimit));
      expect(harness.game.activeEffectCount, lessThanOrEqualTo(12));
      expect(harness.game.isComponentStateSynchronized, isTrue);
    }
    expect(harness.session.score, 65);

    while (harness.session.endlessMistakes < EndlessModeRules.mistakeLimit) {
      var fakes = harness.game.balloonComponents
          .where((balloon) => balloon.isFake)
          .toList();
      while (fakes.isEmpty) {
        final target = harness.game.balloonComponents.firstWhere(
          (balloon) => !balloon.isFake,
        );
        while (harness.session.balloonHpFor(target.balloonId) > 0) {
          target.requestHit();
        }
        await tester.pump();
        fakes = harness.game.balloonComponents
            .where((balloon) => balloon.isFake)
            .toList();
      }
      expect(fakes.first.requestHit(), isTrue);
      await tester.pump();
    }

    expect(harness.session.phase, GameSessionPhase.endlessComplete);
    expect(harness.game.activeBalloonCount, 0);
    expect(harness.game.activeEffectCount, 0);
    await harness.game.restartEndless();
    await tester.pump();
    expect(harness.session.score, 0);
    expect(harness.session.endlessMistakes, 0);
    expect(
        harness.game.activeBalloonCount, EndlessModeRules.activeBalloonLimit);
    expect(harness.game.isComponentStateSynchronized, isTrue);
  });

  testWidgets('dispose stops Flame and removes every component',
      (tester) async {
    final harness = await _pumpPreview(tester, initialStage: 30);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(harness.game.isShutdown, isTrue);
    expect(harness.game.activeBalloonCount, 0);
    expect(harness.game.activeBossCount, 0);
    expect(harness.game.activeEffectCount, 0);
    expect(harness.session.isDisposed, isTrue);
  });
}

class _Harness {
  const _Harness(this.game, this.session);
  final PoppopGame game;
  final GameSessionState session;
}

Future<_Harness> _pumpPreview(
  WidgetTester tester, {
  int initialStage = 1,
  VoidCallback? onHudBuild,
  double Function()? swapRoll,
  FlamePreviewSkin skin = FlamePreviewSkin.basic,
}) async {
  late PoppopGame game;
  late GameSessionState session;
  await tester.pumpWidget(MaterialApp(
    home: FlameGamePage(
      initialStage: initialStage,
      initialSkin: skin,
      onExit: () {},
      onHudBuild: onHudBuild,
      gameFactory: (created) {
        session = created;
        return game = PoppopGame(created,
            initialStage: initialStage,
            initialSkin: skin,
            legendaryImageLoader: _testLegendaryImageLoader,
            stage30SwapRoll: swapRoll);
      },
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await game.loaded;
  await tester.pump();
  return _Harness(game, session);
}

Future<_Harness> _pumpEndless(WidgetTester tester) async {
  final session = GameSessionState();
  final game = PoppopGame(
    session,
    endlessMode: true,
    showDiagnostics: false,
  );
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: GameWidget<PoppopGame>(game: game),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await game.loaded;
  await tester.pump();
  return _Harness(game, session);
}

Future<_Harness> _pumpShushuIntegration(
  WidgetTester tester, {
  required int stage,
}) async {
  final body = await tester.runAsync(
    () => _decodeAssetImage(
      'assets/images/balloon_shushu_canvas_runtime.png',
      stage == 10 || stage == 20 || stage == 30 ? 512 : 320,
    ),
  );
  expect(body, isNotNull);
  late PoppopGame game;
  late GameSessionState session;
  await tester.pumpWidget(PoppopAppEntry(
    engineMode: PoppopEngineMode.flameIntegration,
    integrationDebugConfig: FlameIntegrationDebugConfig(
      enabled: true,
      stage: stage,
      skin: FlamePreviewSkin.shushu,
    ),
    integrationGameFactory: (created, skin, initialStage, onFeedback) {
      session = created;
      return game = PoppopGame(
        created,
        initialStage: initialStage,
        initialSkin: skin,
        stage30SwapRoll: () => 1,
        legendaryImageLoader: (path, targetWidth, cleanTransparentMatte) {
          if (path == 'assets/images/balloon_shushu_canvas_runtime.png') {
            return Future<ui.Image>.value(body!);
          }
          return _testLegendaryImageLoader(
            path,
            targetWidth,
            cleanTransparentMatte,
          );
        },
        onGameplayFeedback: onFeedback,
        showDiagnostics: false,
      );
    },
  ));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('start-section-1')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await game.loaded;
  await tester.pump();
  final intro = find.byKey(
    const ValueKey('flame-integration-stage-intro-next'),
  );
  if (intro.evaluate().isNotEmpty) {
    await tester.tap(intro);
    await tester.pump();
  }
  expect(game.selectedSkin, FlamePreviewSkin.shushu);
  expect(game.skinRuntime.legendaryCache!.loadedAssetPaths,
      contains('assets/images/balloon_shushu_canvas_runtime.png'));
  return _Harness(game, session);
}

Future<ui.Image> _decodeAssetImage(String path, int targetWidth) async {
  final data = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    targetWidth: targetWidth,
    allowUpscaling: false,
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

void _expectShushuComponentGeometry({
  required Rect destination,
  required Rect body,
  required Vector2 componentPosition,
  required double componentScaleX,
  required double componentScaleY,
  required double visualScale,
  required bool Function(Vector2) containsLocalPoint,
}) {
  expect(
    destination.width / destination.height,
    closeTo(361 / 512, .0001),
  );
  expect(componentScaleX, closeTo(componentScaleY, .0001));

  final scaledBody = Rect.fromCenter(
    center: body.center,
    width: body.width * visualScale,
    height: body.height * visualScale,
  );
  final visualCenter = Offset(
    componentPosition.x + scaledBody.center.dx,
    componentPosition.y + scaledBody.center.dy,
  );
  final hitCenter = Offset(
    componentPosition.x + body.center.dx,
    componentPosition.y + body.center.dy,
  );
  expect(visualCenter.dx, closeTo(hitCenter.dx, .0001));
  expect(visualCenter.dy, closeTo(hitCenter.dy, .0001));

  for (final point in <Offset>[
    Offset(scaledBody.center.dx, scaledBody.top + 1),
    scaledBody.center,
    Offset(scaledBody.center.dx, scaledBody.bottom - 1),
  ]) {
    expect(containsLocalPoint(Vector2(point.dx, point.dy)), isTrue);
  }
  expect(
    containsLocalPoint(Vector2(destination.left + 1, body.center.dy)),
    isFalse,
  );
  expect(
    containsLocalPoint(Vector2(destination.right - 1, body.center.dy)),
    isFalse,
  );
}

Offset _center(PositionComponent component) => Offset(
    component.position.x + component.size.x / 2,
    component.position.y + component.size.y / 2);

Future<void> _hitEveryBalloon(PoppopGame game) async {
  for (final balloon in game.balloonComponents.toList()) {
    if (balloon.isFake) continue;
    for (var hp = balloon.maxHp; hp > 0; hp--) {
      expect(balloon.requestHit(), isTrue);
    }
  }
}

Future<void> _pumpTransition(WidgetTester tester, double seconds) async {
  final frames = (seconds / .05).ceil() + 1;
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<int> _maxImageAlpha(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  var maxAlpha = 0;
  for (var offset = 3; offset < data!.lengthInBytes; offset += 4) {
    final alpha = data.getUint8(offset);
    if (alpha > maxAlpha) maxAlpha = alpha;
  }
  return maxAlpha;
}

Future<ui.Image> _testLegendaryImageLoader(
  String path,
  int targetWidth,
  bool cleanTransparentMatte,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final height = path.contains('balloon_shushu_asset')
      ? (targetWidth * 512 / 361).round()
      : (targetWidth * 1.4).round();
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(targetWidth, height);
  picture.dispose();
  return image;
}
