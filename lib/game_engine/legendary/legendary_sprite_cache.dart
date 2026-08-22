import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'flame_preview_skin.dart';
import 'legendary_skin_definition.dart';

enum LegendaryBodyProfile { normal, boss }

typedef LegendaryImageLoader = Future<ui.Image> Function(
  String path,
  int targetWidth,
  bool cleanTransparentMatte,
);

class LegendarySpriteCache {
  LegendarySpriteCache(this.definition, {LegendaryImageLoader? imageLoader})
      : _imageLoader = imageLoader;

  final LegendarySkinDefinition definition;
  final LegendaryImageLoader? _imageLoader;
  final Map<String, ui.Image> _staticImages = <String, ui.Image>{};
  final Map<String, ui.Image> _bodyImages = <String, ui.Image>{};
  LegendaryBodyProfile? _bodyProfile;
  bool _disposed = false;
  int _loadCount = 0;
  int _matteCleanupCount = 0;
  final Set<String> _loadedAssetPaths = <String>{};

  LegendaryBodyProfile? get bodyProfile => _bodyProfile;
  int get imageCount => _uniqueImages.length;
  int get bodyImageCount => _bodyImages.values.toSet().length;
  int get staticImageCount => _staticImages.values.toSet().length;
  int get loadCount => _loadCount;
  int get matteCleanupCount => _matteCleanupCount;
  Set<String> get loadedAssetPaths =>
      Set<String>.unmodifiable(_loadedAssetPaths);
  int get estimatedRgbaBytes => _uniqueImages.fold(
        0,
        (sum, image) => sum + image.width * image.height * 4,
      );
  bool get isDisposed => _disposed;
  Set<ui.Image> get _uniqueImages => <ui.Image>{
        ..._staticImages.values,
        ..._bodyImages.values,
      };

  Future<void> prepareForStage({required bool boss}) async {
    _checkActive();
    await _prepareStaticImages();
    final profile =
        boss ? LegendaryBodyProfile.boss : LegendaryBodyProfile.normal;
    if (_bodyProfile == profile && _bodyImages.isNotEmpty) return;
    _disposeImages(_bodyImages.values);
    _bodyImages.clear();
    _bodyProfile = profile;
    final targetWidth =
        boss ? definition.bossBodyWidth : definition.normalBodyWidth;
    if (definition.skin == FlamePreviewSkin.gemi) {
      for (final color in definition.palette) {
        final key = color.toARGB32();
        final normalPath = definition.catalog.runtimeColorAssetPaths[key]!;
        final fakePath = definition.catalog.runtimeFakeColorAssetPaths[key]!;
        _bodyImages[_bodyKey(key, false)] =
            await _load(normalPath, targetWidth);
        _bodyImages[_bodyKey(key, true)] = await _load(fakePath, targetWidth);
      }
      return;
    }
    final image = await _load(
      definition.catalog.assetPath!,
      targetWidth,
      cleanTransparentMatte: definition.cleansTransparentMatte,
    );
    for (final color in definition.palette) {
      _bodyImages[_bodyKey(color.toARGB32(), false)] = image;
      _bodyImages[_bodyKey(color.toARGB32(), true)] = image;
    }
  }

  Future<void> _prepareStaticImages() async {
    if (_staticImages.isNotEmpty) return;
    _staticImages[definition.backgroundAsset] =
        await _load(definition.backgroundAsset, 720);
    for (final entry in definition.effectAssets.entries) {
      _staticImages[entry.key] = await _load(entry.key, entry.value);
    }
  }

  ui.Image bodyImage(ui.Color color, {required bool fake}) {
    _checkActive();
    final image = _bodyImages[_bodyKey(color.toARGB32(), fake)];
    if (image == null) {
      throw StateError('Legendary body profile must be prepared before spawn.');
    }
    return image;
  }

  ui.Image imageForAsset(String path) {
    _checkActive();
    final image = _staticImages[path];
    if (image == null) {
      throw StateError('Legendary asset was not preloaded: $path');
    }
    return image;
  }

  ui.Image get backgroundImage => imageForAsset(definition.backgroundAsset);

  Future<ui.Image> _load(
    String path,
    int targetWidth, {
    bool cleanTransparentMatte = false,
  }) async {
    _checkActive();
    _loadCount++;
    _loadedAssetPaths.add(path);
    if (cleanTransparentMatte) _matteCleanupCount++;
    final injected = _imageLoader;
    if (injected != null) {
      final image = await injected(path, targetWidth, cleanTransparentMatte);
      if (_disposed) {
        image.dispose();
        throw StateError('Legendary sprite cache was disposed during load.');
      }
      return image;
    }
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      targetWidth: targetWidth,
      allowUpscaling: false,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (_disposed) {
      frame.image.dispose();
      throw StateError('Legendary sprite cache was disposed during load.');
    }
    if (!cleanTransparentMatte) return frame.image;
    return _cleanTransparentRgb(frame.image);
  }

  Future<ui.Image> _cleanTransparentRgb(ui.Image source) async {
    final data = await source.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return source;
    final pixels = Uint8List.fromList(data.buffer.asUint8List());
    for (var offset = 0; offset < pixels.length; offset += 4) {
      final alpha = pixels[offset + 3];
      if (alpha == 0) {
        pixels[offset] = 0;
        pixels[offset + 1] = 0;
        pixels[offset + 2] = 0;
      } else if (alpha < 32) {
        // Preserve source alpha while suppressing RGB matte that can leak into
        // CanvasKit's downscaled edge sampling.
        pixels[offset] = pixels[offset] * alpha ~/ 32;
        pixels[offset + 1] = pixels[offset + 1] * alpha ~/ 32;
        pixels[offset + 2] = pixels[offset + 2] * alpha ~/ 32;
      }
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: source.width,
      height: source.height,
      rowBytes: source.width * 4,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    source.dispose();
    if (_disposed) {
      frame.image.dispose();
      throw StateError('Legendary sprite cache was disposed during cleanup.');
    }
    return frame.image;
  }

  void releaseBodyProfile() {
    _disposeImages(_bodyImages.values);
    _bodyImages.clear();
    _bodyProfile = null;
  }

  void _disposeImages(Iterable<ui.Image> images) {
    for (final image in images.toSet()) {
      image.dispose();
    }
  }

  String _bodyKey(int color, bool fake) => '$color:$fake';

  void _checkActive() {
    if (_disposed) throw StateError('Legendary sprite cache is disposed.');
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _disposeImages(_uniqueImages);
    _bodyImages.clear();
    _staticImages.clear();
  }
}
