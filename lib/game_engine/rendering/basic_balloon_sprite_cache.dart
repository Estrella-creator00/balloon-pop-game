import 'dart:ui' as ui;

import '../../balloon_skin_catalog.dart';
import '../../gameplay/game_draw_geometry.dart';
import '../stages/flame_stage_definition.dart';

/// Pre-rasterizes the production default balloon painter once per palette
/// color. The production default skin has no PNG asset, so this preserves its
/// exact shared artwork without adding or modifying an asset file.
class BasicBalloonSpriteCache {
  static const double logicalWidth = 102;
  static const double logicalHeight = 128;
  static const double rasterScale = 3;
  static const int maxBossSpriteCount = 10;
  static const int bossRasterWidth = 512;

  final Map<int, ui.Image> _images = <int, ui.Image>{};
  final Map<int, ui.Image> _bossImages = <int, ui.Image>{};
  Future<void>? _preloadFuture;
  Future<void>? _bossPreloadFuture;
  double? _bossInitialSize;
  bool _disposed = false;
  int _preloadCount = 0;
  int _bossPreloadCount = 0;

  bool get isReady => _images.isNotEmpty && !_disposed;
  int get imageCount => _images.length;
  int get preloadCount => _preloadCount;
  int get bossImageCount => _bossImages.length;
  int get bossPreloadCount => _bossPreloadCount;
  double? get bossInitialSize => _bossInitialSize;

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

  Future<void> prepareStage10Boss({
    required double initialSize,
    required FlameBossRule rule,
  }) {
    if (_disposed) return Future<void>.value();
    if (_bossInitialSize == initialSize && _bossImages.length == rule.maxHp) {
      return Future<void>.value();
    }
    final inFlight = _bossPreloadFuture;
    if (inFlight != null) return inFlight;
    final future = _preloadBossImages(initialSize, rule);
    _bossPreloadFuture = future;
    return future.whenComplete(() {
      if (identical(_bossPreloadFuture, future)) _bossPreloadFuture = null;
    });
  }

  Future<void> _preloadBossImages(
    double initialSize,
    FlameBossRule rule,
  ) async {
    _bossPreloadCount++;
    for (final image in _bossImages.values) {
      image.dispose();
    }
    _bossImages.clear();
    _bossInitialSize = initialSize;

    for (var hp = rule.maxHp; hp >= 1; hp--) {
      final diameter = rule.sizeForHp(initialSize, hp);
      final logicalSize = ui.Size(diameter, diameter + 32);
      final scale = bossRasterWidth / diameter;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(scale, scale);
      BossBalloonDrawing(
        logicalSize,
        rule.colorForHp(hp),
        hp: hp,
        maxHp: rule.maxHp,
        showHealthBar: true,
      ).draw(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        bossRasterWidth,
        (logicalSize.height * scale).round(),
      );
      picture.dispose();
      if (_disposed) {
        image.dispose();
        return;
      }
      _bossImages[hp] = image;
    }
  }

  ui.Image bossImageForHp(int hp) {
    final image = _bossImages[hp];
    if (image == null || _disposed) {
      throw StateError('Stage 10 boss sprites must be prepared before spawn.');
    }
    return image;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final image in _images.values) {
      image.dispose();
    }
    for (final image in _bossImages.values) {
      image.dispose();
    }
    _images.clear();
    _bossImages.clear();
  }
}
