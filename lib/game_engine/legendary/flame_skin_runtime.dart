import 'dart:ui';

import '../rendering/basic_balloon_sprite_cache.dart';
import '../stages/flame_stage_definition.dart';
import 'flame_preview_skin.dart';
import 'legendary_skin_definition.dart';
import 'legendary_sprite_cache.dart';

class FlameSkinRuntime {
  FlameSkinRuntime({
    required this.basicCache,
    required FlamePreviewSkin initialSkin,
    this.legendaryImageLoader,
  }) : _skin = initialSkin;

  final BasicBalloonSpriteCache basicCache;
  final LegendaryImageLoader? legendaryImageLoader;
  FlamePreviewSkin _skin;
  LegendarySpriteCache? _legendaryCache;

  FlamePreviewSkin get skin => _skin;
  LegendarySkinDefinition? get legendaryDefinition =>
      _skin.isLegendary ? legendaryDefinitionFor(_skin) : null;
  LegendarySpriteCache? get legendaryCache => _legendaryCache;
  List<Color> get palette => _skin.catalogDefinition.colorPalette;
  bool get isLegendary => _skin.isLegendary;
  int get imageCount => isLegendary
      ? (_legendaryCache?.imageCount ?? 0)
      : basicCache.imageCount + basicCache.bossImageCount;
  int get estimatedRgbaBytes =>
      isLegendary ? (_legendaryCache?.estimatedRgbaBytes ?? 0) : 0;
  double get fakeOpacity =>
      legendaryDefinition?.precomposedFake == true ? 1 : 0.35;
  bool get usesSeparateBossHealthBar => isLegendary;
  LegendaryIdleStyle get idleStyle =>
      legendaryDefinition?.idleStyle ?? LegendaryIdleStyle.none;
  bool get breathes => idleStyle == LegendaryIdleStyle.breathe;

  Future<void> prepareForStage(
    FlameStageDefinition stage, {
    required double bossInitialSize,
  }) async {
    if (!isLegendary) {
      _legendaryCache?.dispose();
      _legendaryCache = null;
      await basicCache.preload();
      if (stage.isBoss) {
        await basicCache.prepareBoss(
          stage: stage.stage,
          initialSize: bossInitialSize,
          rule: stage.bossRule!,
        );
      }
      return;
    }
    basicCache.releaseImages();
    final cache = _legendaryCache ??= LegendarySpriteCache(
      legendaryDefinition!,
      imageLoader: legendaryImageLoader,
    );
    await cache.prepareForStage(boss: stage.isBoss);
  }

  Image balloonImage(Color color, int hp, int maxHp, bool fake) => isLegendary
      ? _legendaryCache!.bodyImage(color, fake: fake)
      : basicCache.imageForBalloon(color, hp, maxHp, fake);

  Image bossImage(Color color, int hp, {bool fake = false}) => isLegendary
      ? _legendaryCache!.bodyImage(color, fake: fake)
      : basicCache.bossImageForHp(hp, fake: fake);

  Future<void> switchSkin(FlamePreviewSkin skin) async {
    if (_skin == skin) return;
    _legendaryCache?.dispose();
    _legendaryCache = null;
    basicCache.releaseImages();
    _skin = skin;
  }

  void dispose() {
    _legendaryCache?.dispose();
    _legendaryCache = null;
    basicCache.dispose();
  }
}
