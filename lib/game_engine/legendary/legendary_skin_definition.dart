import 'dart:ui';

import '../../balloon_background.dart';
import '../../balloon_skin_catalog.dart';
import 'flame_preview_skin.dart';

enum LegendaryIdleStyle { none, breathe }

class LegendarySkinDefinition {
  const LegendarySkinDefinition({
    required this.skin,
    required this.catalog,
    required this.idleStyle,
    required this.backgroundAsset,
    required this.effectAssets,
    required this.normalBodyWidth,
    required this.bossBodyWidth,
    required this.precomposedFake,
    this.bodyAssetPathOverride,
  });

  final FlamePreviewSkin skin;
  final BalloonSkinDefinition catalog;
  final LegendaryIdleStyle idleStyle;
  final String backgroundAsset;
  final Map<String, int> effectAssets;
  final int normalBodyWidth;
  final int bossBodyWidth;
  final bool precomposedFake;
  final String? bodyAssetPathOverride;

  List<Color> get palette => catalog.colorPalette;
  String get bodyAssetPath => bodyAssetPathOverride ?? catalog.assetPath!;
  bool get cleansTransparentMatte =>
      skin == FlamePreviewSkin.shushu && bodyAssetPathOverride == null;
}

LegendarySkinDefinition legendaryDefinitionFor(FlamePreviewSkin skin) {
  final catalog = skin.catalogDefinition;
  return switch (skin) {
    FlamePreviewSkin.gemi => LegendarySkinDefinition(
        skin: skin,
        catalog: catalog,
        idleStyle: LegendaryIdleStyle.none,
        backgroundAsset:
            BalloonBackgroundRegistry.gameplayAssetPathFor(catalog.background)!,
        normalBodyWidth: 320,
        bossBodyWidth: 512,
        precomposedFake: true,
        effectAssets: <String, int>{
          catalog.hitToolAssetPath!: 256,
          ...catalog.runtimeShardAssetPaths.map(
            (key, value) => MapEntry(value, 128),
          ),
          catalog.screenCrackAssetPath!: 320,
          BalloonBackgroundRegistry.crystalImpactGlowAssetPath: 423,
        },
      ),
    FlamePreviewSkin.shushu => LegendarySkinDefinition(
        skin: skin,
        catalog: catalog,
        idleStyle: LegendaryIdleStyle.breathe,
        backgroundAsset:
            BalloonBackgroundRegistry.gameplayAssetPathFor(catalog.background)!,
        normalBodyWidth: 320,
        bossBodyWidth: 512,
        precomposedFake: false,
        bodyAssetPathOverride:
            'assets/images/balloon_shushu_canvas_runtime.png',
        effectAssets: <String, int>{
          catalog.hitToolAssetPath!: 256,
          catalog.burstAssetPath!: 320,
          catalog.wallSplatAssetPath!: 320,
          catalog.screenSplatAssetPath!: 320,
        },
      ),
    _ => throw ArgumentError.value(skin, 'skin'),
  };
}
