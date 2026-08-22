import 'dart:ui';

class FlameSpriteFrame {
  const FlameSpriteFrame(
    this.image, {
    this.colorFilter,
  });

  final Image image;
  final ColorFilter? colorFilter;
}
