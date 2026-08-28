import 'dart:ui';

import '../../balloon_skin_catalog.dart';
import '../rendering/basic_balloon_sprite_cache.dart';
import '../rendering/flame_sprite_frame.dart';
import '../skins/catalog_sprite_cache.dart';
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
  CatalogSpriteCache? _catalogCache;
  FlameStageDefinition? _activeStage;

  FlamePreviewSkin get skin => _skin;
  LegendarySkinDefinition? get legendaryDefinition =>
      _skin.isLegendary ? legendaryDefinitionFor(_skin) : null;
  LegendarySpriteCache? get legendaryCache => _legendaryCache;
  CatalogSpriteCache? get catalogCache => _catalogCache;
  BalloonSkinDefinition get catalogDefinition => _skin.catalogDefinition;
  List<Color> get palette => _skin.catalogDefinition.colorPalette;
  bool get isLegendary => _skin.isLegendary;
  int get imageCount => isLegendary
      ? (_legendaryCache?.imageCount ?? 0)
      : _skin.usesCatalogImage
          ? (_catalogCache?.imageCount ?? 0)
          : basicCache.imageCount + basicCache.bossImageCount;
  int get estimatedRgbaBytes => isLegendary
      ? (_legendaryCache?.estimatedRgbaBytes ?? 0)
      : (_catalogCache?.estimatedRgbaBytes ?? 0);
  double get fakeOpacity => isLegendary
      ? (legendaryDefinition?.precomposedFake == true ? 1 : 0.35)
      : 0.35;
  bool get usesSeparateBossHealthBar => isLegendary || _skin.usesCatalogImage;
  bool get preserveSpriteAspectRatio => isLegendary || _skin.usesCatalogImage;
  bool get usesSourceAspectGeometry => _skin == FlamePreviewSkin.shushu;
  LegendaryIdleStyle get idleStyle =>
      legendaryDefinition?.idleStyle ?? LegendaryIdleStyle.none;
  bool get breathes => idleStyle == LegendaryIdleStyle.breathe;
  bool get ghostIdle =>
      catalogDefinition.idleAnimation == BalloonIdleAnimationType.ghostTail;
  double get baseSpriteOpacity => ghostIdle ? 0.86 : 1;
  int get visualVariantCount => catalogDefinition.visualVariantCount;
  BalloonExitAnimationType get exitAnimation => catalogDefinition.exitAnimation;

  Future<void> prepareForStage(
    FlameStageDefinition stage, {
    required double bossInitialSize,
  }) async {
    _activeStage = stage;
    if (_skin == FlamePreviewSkin.basic) {
      _legendaryCache?.dispose();
      _legendaryCache = null;
      _catalogCache?.dispose();
      _catalogCache = null;
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
    if (_skin.usesCatalogImage) {
      basicCache.releaseImages();
      _legendaryCache?.dispose();
      _legendaryCache = null;
      final cache = _catalogCache ??= CatalogSpriteCache(
        catalogDefinition,
        imageLoader: legendaryImageLoader,
      );
      await cache.prepareForStage(stage);
      return;
    }
    basicCache.releaseImages();
    _catalogCache?.dispose();
    _catalogCache = null;
    final cache = _legendaryCache ??= LegendarySpriteCache(
      legendaryDefinition!,
      imageLoader: legendaryImageLoader,
    );
    await cache.prepareForStage(boss: stage.isBoss);
  }

  FlameSpriteFrame balloonFrame(
    Color color,
    int hp,
    int maxHp,
    bool fake,
    int visualVariant,
  ) =>
      isLegendary
          ? _legendaryFrame(color, fake: fake)
          : _skin.usesCatalogImage
              ? _catalogCache!.frame(
                  catalogDefinition.colorAtDamage(
                    color,
                    (maxHp - hp) / maxHp,
                    isBoss: false,
                  ),
                  fake: fake,
                  variant: visualVariant,
                )
              : FlameSpriteFrame(
                  basicCache.imageForBalloon(color, hp, maxHp, fake),
                );

  FlameSpriteFrame bossFrame(
    Color color,
    int hp, {
    required bool fake,
    required int visualVariant,
  }) =>
      isLegendary
          ? _legendaryFrame(color, fake: fake)
          : _skin.usesCatalogImage
              ? _catalogCache!.frame(
                  _activeStage!.bossRule!.colorForHp(hp),
                  fake: fake,
                  variant: visualVariant,
                )
              : FlameSpriteFrame(basicCache.bossImageForHp(hp, fake: fake));

  FlameSpriteFrame _legendaryFrame(Color color, {required bool fake}) =>
      FlameSpriteFrame(
        _legendaryCache!.bodyImage(color, fake: fake),
        normalizedVisibleBounds: _skin == FlamePreviewSkin.shushu
            ? _shushuNormalizedVisibleBounds
            : const Rect.fromLTWH(0, 0, 1, 1),
      );

  Future<void> switchSkin(FlamePreviewSkin skin) async {
    if (_skin == skin) return;
    _legendaryCache?.dispose();
    _legendaryCache = null;
    _catalogCache?.dispose();
    _catalogCache = null;
    basicCache.releaseImages();
    _skin = skin;
    _activeStage = null;
  }

  void dispose() {
    _legendaryCache?.dispose();
    _legendaryCache = null;
    _catalogCache?.dispose();
    _catalogCache = null;
    _activeStage = null;
    basicCache.dispose();
  }
}

// Alpha >= 32 bounds measured from the untouched 361x512 production PNG.
// Low-alpha antialiasing remains rendered, while gameplay geometry follows the
// visible cream-puff body rather than transparent edge pixels.
const Rect _shushuNormalizedVisibleBounds = Rect.fromLTRB(
  16 / 361,
  1 / 512,
  344 / 361,
  507 / 512,
);
