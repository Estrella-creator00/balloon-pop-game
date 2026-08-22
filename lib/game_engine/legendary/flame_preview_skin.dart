import '../../balloon_skin_catalog.dart';

enum FlamePreviewSkin { basic, gemi, shushu }

const String gemiSkinId = 'balloon-lumen';
const String shushuSkinId = 'balloon-chouchou';

extension FlamePreviewSkinDefinition on FlamePreviewSkin {
  String get queryValue => switch (this) {
        FlamePreviewSkin.basic => 'basic',
        FlamePreviewSkin.gemi => gemiSkinId,
        FlamePreviewSkin.shushu => shushuSkinId,
      };

  String get label => switch (this) {
        FlamePreviewSkin.basic => 'BASIC',
        FlamePreviewSkin.gemi => 'GEMI',
        FlamePreviewSkin.shushu => 'SHUSHU',
      };

  BalloonSkinDefinition get catalogDefinition => switch (this) {
        FlamePreviewSkin.basic => BalloonSkinCatalog.defaultSkin,
        FlamePreviewSkin.gemi => BalloonSkinCatalog.byIdOrDefault(gemiSkinId),
        FlamePreviewSkin.shushu =>
          BalloonSkinCatalog.byIdOrDefault(shushuSkinId),
      };

  bool get isLegendary => this != FlamePreviewSkin.basic;
}

FlamePreviewSkin flamePreviewSkinFromValue(String? value) => switch (value) {
      'gemi' || gemiSkinId => FlamePreviewSkin.gemi,
      'shushu' || shushuSkinId => FlamePreviewSkin.shushu,
      _ => FlamePreviewSkin.basic,
    };

FlamePreviewSkin flamePreviewSkinFromUri(Uri uri) =>
    flamePreviewSkinFromValue(uri.queryParameters['skin']);
