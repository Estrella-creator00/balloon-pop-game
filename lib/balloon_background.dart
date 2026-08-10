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
      type: BalloonBackgroundSpec(
        type: type,
        assetPath: switch (type) {
          BalloonBackgroundType.crystalCave =>
            'assets/images/gemi_background_asset.png',
          BalloonBackgroundType.creamCafe =>
            'assets/images/shushu_background_asset.png',
          _ => null,
        },
      ),
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
    this.crystalPulse = 0,
  });
  final BalloonBackgroundType background;
  final Widget fallback;
  final BoxFit fit;
  final double crystalPulse;

  @override
  Widget build(BuildContext context) {
    final assetPath =
        BalloonBackgroundRegistry.definitionFor(background).assetPath;
    if (assetPath != null) {
      final image = Image.asset(
        assetPath,
        fit: fit,
        cacheWidth: 1024,
        gaplessPlayback: true,
      );
      if (background != BalloonBackgroundType.crystalCave) {
        return RepaintBoundary(child: image);
      }
      final pulse = crystalPulse.clamp(0.0, 1.0);
      return RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            DecoratedBox(
              key: const ValueKey('background-crystal-glow'),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.18),
                  radius: 0.43,
                  colors: [
                    Color.fromRGBO(184, 225, 255, 0.08 + pulse * 0.22),
                    const Color(0x00000000),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
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
