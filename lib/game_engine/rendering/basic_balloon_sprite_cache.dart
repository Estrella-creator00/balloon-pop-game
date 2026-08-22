import 'dart:ui' as ui;

import 'package:flutter/material.dart' show HSLColor;

import '../../balloon_skin_catalog.dart';
import '../../gameplay/game_draw_geometry.dart';
import '../stages/flame_stage_definition.dart';

class BasicBalloonSpriteCache {
  static const double logicalWidth = 102;
  static const double logicalHeight = 128;
  static const double rasterScale = 3;
  static const int bossRasterWidth = 512;
  static const int maxNormalSpriteCount = 21;
  static const int maxBossSpriteCount = 24;

  final Map<String, ui.Image> _images = <String, ui.Image>{};
  final Map<String, ui.Image> _bossImages = <String, ui.Image>{};
  Future<void>? _preloadFuture;
  Future<void>? _bossPreloadFuture;
  double? _bossInitialSize;
  int? _bossStage;
  bool _disposed = false;
  int _preloadCount = 0;
  int _bossPreloadCount = 0;

  bool get isReady => _images.isNotEmpty && !_disposed;
  int get imageCount => _images.length;
  int get preloadCount => _preloadCount;
  int get bossImageCount => _bossImages.length;
  int get bossPreloadCount => _bossPreloadCount;
  double? get bossInitialSize => _bossInitialSize;
  int? get bossStage => _bossStage;

  Future<void> preload() => _preloadFuture ??= _preloadImages();

  Future<void> _preloadImages() async {
    if (_disposed) return;
    _preloadCount++;
    for (final color in BalloonSkinCatalog.defaultSkin.colorPalette) {
      await _createNormal(color, hp: 1, maxHp: 1, fake: false);
      await _createNormal(color, hp: 1, maxHp: 2, fake: false);
      await _createNormal(color, hp: 1, maxHp: 1, fake: true);
    }
  }

  Future<void> _createNormal(
    ui.Color color, {
    required int hp,
    required int maxHp,
    required bool fake,
  }) async {
    var display = BalloonSkinCatalog.defaultSkin
        .colorAtDamage(color, (maxHp - hp) / maxHp, isBoss: false);
    if (fake) display = _fakeColor(display);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(rasterScale, rasterScale);
    BasicBalloonDrawing.forBalloon(
            const ui.Size(logicalWidth, logicalHeight), display)
        .draw(canvas);
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
    _images[_normalKey(color, hp, maxHp, fake)] = image;
  }

  ui.Image imageFor(ui.Color color) => imageForBalloon(color, 1, 1, false);

  ui.Image imageForBalloon(ui.Color color, int hp, int maxHp, bool fake) {
    final image = _images[_normalKey(color, hp, maxHp, fake)];
    if (image == null || _disposed) {
      throw StateError('Balloon sprites must be preloaded before spawn.');
    }
    return image;
  }

  Future<void> prepareBoss({
    required int stage,
    required double initialSize,
    required FlameBossRule rule,
  }) {
    if (_disposed) return Future<void>.value();
    final expected = rule.maxHp * (rule.fakeBossCount > 0 ? 2 : 1);
    if (_bossStage == stage &&
        _bossInitialSize == initialSize &&
        _bossImages.length == expected) {
      return Future<void>.value();
    }
    final inFlight = _bossPreloadFuture;
    if (inFlight != null) return inFlight;
    final future = _preloadBossImages(stage, initialSize, rule);
    _bossPreloadFuture = future;
    return future.whenComplete(() {
      if (identical(_bossPreloadFuture, future)) _bossPreloadFuture = null;
    });
  }

  Future<void> prepareStage10Boss({
    required double initialSize,
    required FlameBossRule rule,
  }) =>
      prepareBoss(stage: 10, initialSize: initialSize, rule: rule);

  Future<void> _preloadBossImages(
      int stage, double initialSize, FlameBossRule rule) async {
    _bossPreloadCount++;
    for (final image in _bossImages.values) {
      image.dispose();
    }
    _bossImages.clear();
    _bossInitialSize = initialSize;
    _bossStage = stage;
    for (var hp = rule.maxHp; hp >= 1; hp--) {
      await _createBoss(initialSize, rule, hp: hp, fake: false);
      if (rule.fakeBossCount > 0) {
        await _createBoss(initialSize, rule, hp: hp, fake: true);
      }
    }
  }

  Future<void> _createBoss(
    double initialSize,
    FlameBossRule rule, {
    required int hp,
    required bool fake,
  }) async {
    final diameter = rule.sizeForHp(initialSize, hp);
    final logicalSize = ui.Size(diameter, diameter + 32);
    final scale = bossRasterWidth / diameter;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(scale, scale);
    final color = fake ? _fakeColor(rule.colorForHp(hp)) : rule.colorForHp(hp);
    BossBalloonDrawing(
      logicalSize,
      color,
      hp: hp,
      maxHp: rule.maxHp,
      showHealthBar: !fake,
    ).draw(canvas);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
        bossRasterWidth, (logicalSize.height * scale).round());
    picture.dispose();
    if (_disposed) {
      image.dispose();
      return;
    }
    _bossImages[_bossKey(hp, fake)] = image;
  }

  ui.Image bossImageForHp(int hp, {bool fake = false}) {
    final image = _bossImages[_bossKey(hp, fake)];
    if (image == null || _disposed) {
      throw StateError('Boss sprites must be prepared before spawn.');
    }
    return image;
  }

  /// Releases the active profile while keeping this cache reusable when the
  /// preview switches back from a legendary skin.
  void releaseImages() {
    if (_disposed) return;
    for (final image in <ui.Image>{..._images.values, ..._bossImages.values}) {
      image.dispose();
    }
    _images.clear();
    _bossImages.clear();
    _preloadFuture = null;
    _bossPreloadFuture = null;
    _bossInitialSize = null;
    _bossStage = null;
  }

  static String _normalKey(ui.Color color, int hp, int maxHp, bool fake) =>
      hp == maxHp && !fake
          ? '${color.toARGB32()}:1:1:false'
          : '${color.toARGB32()}:$hp:$maxHp:$fake';
  static String _bossKey(int hp, bool fake) => '$hp:$fake';

  static ui.Color _fakeColor(ui.Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation * 0.78).clamp(0, 1))
        .withLightness((hsl.lightness * 0.97).clamp(0, 1))
        .toColor();
  }

  void dispose() {
    if (_disposed) return;
    releaseImages();
    _disposed = true;
  }
}
