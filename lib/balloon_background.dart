import 'package:flutter/material.dart';

enum BalloonBackgroundType {
  none,
  galaxy,
  halloween,
  winter,
  underwater,
  crystalCave,
  creamCafe,
}

@immutable
class BalloonBackgroundSpec {
  const BalloonBackgroundSpec({required this.type, this.assetPath});
  final BalloonBackgroundType type;
  final String? assetPath;
}

abstract final class BalloonBackgroundRegistry {
  static final definitions = <BalloonBackgroundType, BalloonBackgroundSpec>{
    for (final type in BalloonBackgroundType.values)
      type: BalloonBackgroundSpec(type: type),
  };
  static BalloonBackgroundSpec definitionFor(BalloonBackgroundType type) =>
      definitions[type]!;
}

/// Shared static renderer for preview and gameplay. Legendary themes are
/// lightweight gradients/shapes: no timers, image assets, or animation.
class BalloonBackgroundRenderer extends StatelessWidget {
  const BalloonBackgroundRenderer({
    super.key,
    required this.background,
    required this.fallback,
    this.fit = BoxFit.cover,
  });
  final BalloonBackgroundType background;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final assetPath =
        BalloonBackgroundRegistry.definitionFor(background).assetPath;
    if (assetPath != null) {
      return RepaintBoundary(child: Image.asset(assetPath, fit: fit));
    }
    return switch (background) {
      BalloonBackgroundType.crystalCave => const RepaintBoundary(
          child: DecoratedBox(
            key: ValueKey('background-crystal-cave'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF21184F),
                  Color(0xFF43347A),
                  Color(0xFF172E52)
                ],
              ),
            ),
          ),
        ),
      BalloonBackgroundType.creamCafe => const RepaintBoundary(
          child: DecoratedBox(
            key: ValueKey('background-cream-cafe'),
            decoration: BoxDecoration(
              color: Color(0xFFFFF2D8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF8E9),
                  Color(0xFFFFE7BD),
                  Color(0xFFFFF3DC)
                ],
              ),
            ),
          ),
        ),
      _ => fallback,
    };
  }
}
