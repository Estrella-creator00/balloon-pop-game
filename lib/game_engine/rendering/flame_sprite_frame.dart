import 'dart:ui';

import 'package:flame/components.dart';

class FlameSpriteFrame {
  const FlameSpriteFrame(
    this.image, {
    this.colorFilter,
    this.normalizedVisibleBounds = const Rect.fromLTWH(0, 0, 1, 1),
  });

  final Image image;
  final ColorFilter? colorFilter;
  final Rect normalizedVisibleBounds;
}

/// Geometry shared by SHUSHU's normal and boss components. The decoded image
/// ratio is authoritative and contained inside a square gameplay extent.
Vector2 sourceAspectComponentSize(
  Image image,
  double bodyExtent, {
  double trailingHeight = 0,
}) =>
    Vector2(bodyExtent, bodyExtent + trailingHeight);

Rect sourceAspectDestinationRect(Image image, double bodyExtent) {
  final aspect = image.width / image.height;
  final width = aspect >= 1 ? bodyExtent : bodyExtent * aspect;
  final height = aspect >= 1 ? bodyExtent / aspect : bodyExtent;
  return Rect.fromLTWH(
    (bodyExtent - width) / 2,
    (bodyExtent - height) / 2,
    width,
    height,
  );
}

Rect sourceAspectVisibleBodyRect(
  FlameSpriteFrame frame,
  double bodyExtent,
) {
  final destination = sourceAspectDestinationRect(frame.image, bodyExtent);
  final visible = frame.normalizedVisibleBounds;
  return Rect.fromLTRB(
    destination.left + destination.width * visible.left,
    destination.top + destination.height * visible.top,
    destination.left + destination.width * visible.right,
    destination.top + destination.height * visible.bottom,
  );
}
