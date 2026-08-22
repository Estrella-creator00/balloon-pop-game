import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../../balloon_skin_catalog.dart';
import '../legendary/legendary_sprite_cache.dart';
import '../rendering/flame_sprite_frame.dart';
import '../stages/flame_stage_definition.dart';
import 'catalog_skin_color.dart';

enum CatalogBodyProfile { normal, boss }

class CatalogSpriteCache {
  CatalogSpriteCache(this.definition, {LegendaryImageLoader? imageLoader})
      : _imageLoader = imageLoader;

  final BalloonSkinDefinition definition;
  final LegendaryImageLoader? _imageLoader;
  final Map<String, ui.Image> _sourceImages = <String, ui.Image>{};
  final Map<String, FlameSpriteFrame> _frames = <String, FlameSpriteFrame>{};
  CatalogBodyProfile? _profile;
  String? _profileSignature;
  bool _disposed = false;
  int _loadCount = 0;

  CatalogBodyProfile? get profile => _profile;
  bool get isDisposed => _disposed;
  int get imageCount => _uniqueImages.length;
  int get loadCount => _loadCount;
  int get estimatedRgbaBytes => _uniqueImages.fold(
        0,
        (sum, image) => sum + image.width * image.height * 4,
      );
  Set<ui.Image> get _uniqueImages => <ui.Image>{
        ..._sourceImages.values,
        ..._frames.values.map((frame) => frame.image),
      };

  Future<void> prepareForStage(FlameStageDefinition stage) async {
    _checkActive();
    final profile =
        stage.isBoss ? CatalogBodyProfile.boss : CatalogBodyProfile.normal;
    final includesFake = stage.isBoss
        ? stage.bossRule!.fakeBossCount > 0
        : stage.balloonRule.fakeCount > 0;
    final signature = stage.isBoss
        ? 'boss:${stage.stage}:$includesFake'
        : 'normal:${stage.balloonRule.requiredHits}:$includesFake';
    if (_profile == profile &&
        _profileSignature == signature &&
        _frames.isNotEmpty) {
      return;
    }
    _releaseProfile();
    _profile = profile;
    _profileSignature = signature;
    final width = stage.isBoss ? 512 : 320;
    final paths = definition.variantAssetPaths.isEmpty
        ? <String>[definition.assetPath!]
        : definition.variantAssetPaths;
    for (final path in paths) {
      _sourceImages[path] = await _load(path, width);
    }
    final colors = _profileColors(stage);
    if (definition.imageDetailMask == BalloonImageDetailMask.mochiFace) {
      await _prepareMochiFrames(colors, includesFake: includesFake);
    } else {
      _prepareFilteredFrames(paths, colors, includesFake: includesFake);
    }
  }

  Set<ui.Color> _profileColors(FlameStageDefinition stage) {
    if (stage.isBoss) {
      final rule = stage.bossRule!;
      return <ui.Color>{
        for (var hp = rule.maxHp; hp >= 1; hp--) rule.colorForHp(hp),
      };
    }
    final hits = stage.balloonRule.requiredHits;
    return <ui.Color>{
      for (final color in definition.colorPalette)
        for (var hp = hits; hp >= 1; hp--)
          definition.colorAtDamage(
            color,
            (hits - hp) / hits,
            isBoss: false,
          ),
    };
  }

  void _prepareFilteredFrames(
    List<String> paths,
    Set<ui.Color> colors, {
    required bool includesFake,
  }) {
    for (var variant = 0; variant < paths.length; variant++) {
      final image = _sourceImages[paths[variant]]!;
      for (final color in colors) {
        for (final fake
            in includesFake ? const <bool>[false, true] : const <bool>[false]) {
          final needsFilter = catalogSpriteNeedsColorFilter(
            definition,
            color,
            fake: fake,
          );
          _frames[_key(color, fake, variant)] = FlameSpriteFrame(
            image,
            colorFilter: needsFilter
                ? ui.ColorFilter.matrix(catalogSpriteColorMatrix(
                    definition,
                    color,
                    fake: fake,
                  ))
                : null,
          );
        }
      }
    }
  }

  Future<void> _prepareMochiFrames(
    Set<ui.Color> colors, {
    required bool includesFake,
  }) async {
    final source = _sourceImages.values.single;
    for (final color in colors) {
      for (final fake
          in includesFake ? const <bool>[false, true] : const <bool>[false]) {
        final isRawReference =
            !fake && definition.previewColor.toARGB32() == color.toARGB32();
        final image = isRawReference
            ? source
            : await _composeMochi(source, color, fake: fake);
        _frames[_key(color, fake, 0)] = FlameSpriteFrame(image);
      }
    }
  }

  Future<ui.Image> _composeMochi(
    ui.Image source,
    ui.Color color, {
    required bool fake,
  }) async {
    final width = source.width;
    final height = source.height;
    final rect = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      source,
      rect,
      rect,
      ui.Paint()
        ..filterQuality = ui.FilterQuality.medium
        ..colorFilter = ui.ColorFilter.matrix(
          catalogSpriteColorMatrix(definition, color, fake: fake),
        ),
    );
    canvas
      ..save()
      ..clipPath(_mochiDetailPath(rect))
      ..drawImageRect(
        source,
        rect,
        rect,
        ui.Paint()
          ..filterQuality = ui.FilterQuality.medium
          ..colorFilter =
              fake ? ui.ColorFilter.matrix(fakeSpriteToneMatrix) : null,
      )
      ..restore();
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    if (_disposed) {
      image.dispose();
      throw StateError('Catalog sprite cache was disposed during compose.');
    }
    return image;
  }

  FlameSpriteFrame frame(
    ui.Color color, {
    required bool fake,
    required int variant,
  }) {
    _checkActive();
    final variantCount = definition.visualVariantCount;
    final resolvedVariant = variantCount <= 1 ? 0 : variant % variantCount;
    final frame = _frames[_key(color, fake, resolvedVariant)];
    if (frame == null) {
      throw StateError('Catalog sprite profile must be prepared before spawn.');
    }
    return frame;
  }

  Future<ui.Image> _load(String path, int targetWidth) async {
    _checkActive();
    _loadCount++;
    final loader = _imageLoader;
    final image = loader == null
        ? await _loadAsset(path, targetWidth)
        : await loader(path, targetWidth, false);
    if (_disposed) {
      image.dispose();
      throw StateError('Catalog sprite cache was disposed during load.');
    }
    return image;
  }

  Future<ui.Image> _loadAsset(String path, int targetWidth) async {
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

  void _releaseProfile() {
    for (final image in _uniqueImages) {
      image.dispose();
    }
    _sourceImages.clear();
    _frames.clear();
    _profile = null;
    _profileSignature = null;
  }

  String _key(ui.Color color, bool fake, int variant) =>
      '${color.toARGB32()}:$fake:$variant';

  void _checkActive() {
    if (_disposed) throw StateError('Catalog sprite cache is disposed.');
  }

  void dispose() {
    if (_disposed) return;
    _releaseProfile();
    _disposed = true;
  }
}

ui.Path _mochiDetailPath(ui.Rect rect) {
  ui.Rect relative(double left, double top, double width, double height) =>
      ui.Rect.fromLTWH(
        rect.left + rect.width * left,
        rect.top + rect.height * top,
        rect.width * width,
        rect.height * height,
      );
  return ui.Path()
    ..addOval(relative(0.33, 0.52, 0.08, 0.09))
    ..addOval(relative(0.59, 0.52, 0.08, 0.09))
    ..addPolygon(<ui.Offset>[
      ui.Offset(rect.left + rect.width * 0.47, rect.top + rect.height * 0.59),
      ui.Offset(rect.left + rect.width * 0.53, rect.top + rect.height * 0.59),
      ui.Offset(rect.left + rect.width * 0.50, rect.top + rect.height * 0.63),
    ], true);
}
