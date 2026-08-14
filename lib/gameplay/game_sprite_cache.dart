import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

class CachedGameSprite {
  CachedGameSprite(this.image)
      : sourceRect = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );

  final ui.Image image;
  final Rect sourceRect;
}

enum GameSpriteResolution {
  normal(320),
  boss(512);

  const GameSpriteResolution(this.cacheWidth);

  final int cacheWidth;
}

@immutable
class GameSpriteCacheKey {
  const GameSpriteCacheKey(this.path, this.resolution);

  final String path;
  final GameSpriteResolution resolution;

  @override
  bool operator ==(Object other) =>
      other is GameSpriteCacheKey &&
      other.path == path &&
      other.resolution == resolution;

  @override
  int get hashCode => Object.hash(path, resolution);
}

class GameSpriteCache extends ChangeNotifier {
  final Map<GameSpriteCacheKey, CachedGameSprite> _images =
      <GameSpriteCacheKey, CachedGameSprite>{};
  final Map<GameSpriteCacheKey, ImageStream> _streams =
      <GameSpriteCacheKey, ImageStream>{};
  final Map<GameSpriteCacheKey, ImageStreamListener> _listeners =
      <GameSpriteCacheKey, ImageStreamListener>{};

  CachedGameSprite? operator [](String path) => spriteFor(path);

  CachedGameSprite? spriteFor(
    String path, {
    GameSpriteResolution resolution = GameSpriteResolution.normal,
  }) =>
      _images[GameSpriteCacheKey(path, resolution)];

  bool contains(
    String path, {
    GameSpriteResolution resolution = GameSpriteResolution.normal,
  }) =>
      _images.containsKey(GameSpriteCacheKey(path, resolution));

  int get resolvedCount => _images.length;
  int get pendingCount => _streams.length;

  void prepare(
    Iterable<String> paths,
    ImageConfiguration configuration, {
    GameSpriteResolution resolution = GameSpriteResolution.normal,
  }) {
    for (final path in paths) {
      final key = GameSpriteCacheKey(path, resolution);
      if (_images.containsKey(key) || _streams.containsKey(key)) continue;
      final provider = ResizeImage(
        AssetImage(path),
        width: resolution.cacheWidth,
        allowUpscaling: false,
      );
      final stream = provider.resolve(configuration);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          _images[key] = CachedGameSprite(info.image);
          _streams.remove(key);
          _listeners.remove(key);
          stream.removeListener(listener);
          notifyListeners();
        },
        onError: (_, __) {
          _streams.remove(key);
          _listeners.remove(key);
          stream.removeListener(listener);
        },
      );
      _streams[key] = stream;
      _listeners[key] = listener;
      stream.addListener(listener);
    }
  }

  @override
  void dispose() {
    for (final entry in _streams.entries) {
      final listener = _listeners[entry.key];
      if (listener != null) entry.value.removeListener(listener);
    }
    _streams.clear();
    _listeners.clear();
    _images.clear();
    super.dispose();
  }
}
