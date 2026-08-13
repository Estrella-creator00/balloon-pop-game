import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

class CachedGameSprite {
  const CachedGameSprite(this.image);

  final ui.Image image;

  Rect get sourceRect => Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
}

class GameSpriteCache extends ChangeNotifier {
  final Map<String, CachedGameSprite> _images = <String, CachedGameSprite>{};
  final Map<String, ImageStream> _streams = <String, ImageStream>{};
  final Map<String, ImageStreamListener> _listeners =
      <String, ImageStreamListener>{};

  CachedGameSprite? operator [](String path) => _images[path];

  bool contains(String path) => _images.containsKey(path);

  int get resolvedCount => _images.length;
  int get pendingCount => _streams.length;

  void prepare(
    Iterable<String> paths,
    ImageConfiguration configuration, {
    int cacheWidth = 512,
  }) {
    for (final path in paths) {
      if (_images.containsKey(path) || _streams.containsKey(path)) continue;
      final provider = ResizeImage(AssetImage(path), width: cacheWidth);
      final stream = provider.resolve(configuration);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          _images[path] = CachedGameSprite(info.image);
          _streams.remove(path);
          _listeners.remove(path);
          stream.removeListener(listener);
          notifyListeners();
        },
        onError: (_, __) {
          _streams.remove(path);
          _listeners.remove(path);
          stream.removeListener(listener);
        },
      );
      _streams[path] = stream;
      _listeners[path] = listener;
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
