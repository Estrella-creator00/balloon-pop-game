import '../../balloon_skin_catalog.dart';

enum FlamePreviewSkin {
  basic,
  heart,
  star,
  flower,
  mochi,
  wari,
  kicks,
  boo,
  mugi,
  gemi,
  shushu,
}

const String gemiSkinId = 'balloon-lumen';
const String shushuSkinId = 'balloon-chouchou';

extension FlamePreviewSkinDefinition on FlamePreviewSkin {
  String get queryValue => catalogDefinition.id;

  String get label => switch (this) {
        FlamePreviewSkin.basic => 'BASIC',
        FlamePreviewSkin.heart => 'HEART',
        FlamePreviewSkin.star => 'STAR',
        FlamePreviewSkin.flower => 'FLOWER',
        FlamePreviewSkin.mochi => 'MOCHI',
        FlamePreviewSkin.wari => 'WARI',
        FlamePreviewSkin.kicks => 'KICKS',
        FlamePreviewSkin.boo => 'BOO',
        FlamePreviewSkin.mugi => 'MUGI',
        FlamePreviewSkin.gemi => 'GEMI',
        FlamePreviewSkin.shushu => 'SHUSHU',
      };

  BalloonSkinDefinition get catalogDefinition =>
      BalloonSkinCatalog.byIdOrDefault(_catalogIds[this]);

  bool get isLegendary =>
      this == FlamePreviewSkin.gemi || this == FlamePreviewSkin.shushu;

  bool get usesCatalogImage => this != FlamePreviewSkin.basic && !isLegendary;
}

const Map<FlamePreviewSkin, String> _catalogIds = <FlamePreviewSkin, String>{
  FlamePreviewSkin.basic: BalloonSkinCatalog.defaultId,
  FlamePreviewSkin.heart: 'balloon-heart',
  FlamePreviewSkin.star: 'balloon-star',
  FlamePreviewSkin.flower: 'balloon-flower',
  FlamePreviewSkin.mochi: 'balloon-rabbit',
  FlamePreviewSkin.wari: 'balloon-wari',
  FlamePreviewSkin.kicks: 'balloon-kicks',
  FlamePreviewSkin.boo: 'balloon-boo',
  FlamePreviewSkin.mugi: 'balloon-jello',
  FlamePreviewSkin.gemi: gemiSkinId,
  FlamePreviewSkin.shushu: shushuSkinId,
};

final Map<String, FlamePreviewSkin> _skinsByValue = <String, FlamePreviewSkin>{
  for (final skin in FlamePreviewSkin.values) skin.queryValue: skin,
  'basic': FlamePreviewSkin.basic,
  'heart': FlamePreviewSkin.heart,
  'star': FlamePreviewSkin.star,
  'flower': FlamePreviewSkin.flower,
  'mochi': FlamePreviewSkin.mochi,
  'wari': FlamePreviewSkin.wari,
  'kicks': FlamePreviewSkin.kicks,
  'boo': FlamePreviewSkin.boo,
  'mugi': FlamePreviewSkin.mugi,
  'gemi': FlamePreviewSkin.gemi,
  'shushu': FlamePreviewSkin.shushu,
};

FlamePreviewSkin flamePreviewSkinFromValue(String? value) =>
    _skinsByValue[value] ?? FlamePreviewSkin.basic;

FlamePreviewSkin flamePreviewSkinFromUri(Uri uri) =>
    flamePreviewSkinFromValue(uri.queryParameters['skin']);
