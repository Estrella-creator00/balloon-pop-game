import 'dart:ui';

import 'package:flame/components.dart';

class FlameSpriteFrame {
  const FlameSpriteFrame(
    this.image, {
    this.colorFilter,
  });

  final Image image;
  final ColorFilter? colorFilter;
}

/// Geometry shared by SHUSHU's normal and boss components. The decoded image
/// ratio is authoritative; [bodyWidth] is never stretched independently on X
/// and Y.
Vector2 sourceAspectComponentSize(
  Image image,
  double bodyWidth, {
  double trailingHeight = 0,
}) {
  final bodyHeight = bodyWidth * image.height / image.width;
  return Vector2(bodyWidth, bodyHeight + trailingHeight);
}

Rect sourceAspectDestinationRect(Image image, double bodyWidth) =>
    Rect.fromLTWH(0, 0, bodyWidth, bodyWidth * image.height / image.width);
