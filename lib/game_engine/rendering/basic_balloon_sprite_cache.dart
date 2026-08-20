import 'dart:ui' as ui;

import '../../balloon_skin_catalog.dart';
import '../../gameplay/game_draw_geometry.dart';

/// Pre-rasterizes the production default balloon painter once per palette
/// color. The production default skin has no PNG asset, so this preserves its
/// exact shared artwork without adding or modifying an asset file.
class BasicBalloonSpriteCache {
  static const double logicalWidth = 102;
  static const double logicalHeight = 128;
  static const double rasterScale = 3;

  final Map<int, ui.Image> _images = <int, ui.Image>{};
  Future<void>? _preloadFuture;
  bool _disposed = false;
  int _preloadCount = 0;

  bool get isReady => _images.isNotEmpty && !_disposed;
  int get imageCount => _images.length;
  int get preloadCount => _preloadCount;

  Future<void> preload() => _preloadFuture ??= _preloadImages();

  Future<void> _preloadImages() async {
    if (_disposed) return;
    _preloadCount++;
    for (final color in BalloonSkinCatalog.defaultSkin.colorPalette) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(rasterScale, rasterScale);
      BasicBalloonDrawing.forBalloon(
        const ui.Size(logicalWidth, logicalHeight),
        color,
      ).draw(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (logicalWidth * rasterScale).round(),
        (logicalHeight * rasterScale).round(),
      );
      picture.dispose();
      if (_disposed) {
        image.dispose();
        return;
      }
      _images[color.toARGB32()] = image;
    }
  }

  ui.Image imageFor(ui.Color color) {
    if (!isReady) {
      throw StateError('Basic balloon sprites must be preloaded before spawn.');
    }
    return _images[color.toARGB32()] ?? _images.values.first;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
  }
}
