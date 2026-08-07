import 'package:flutter/material.dart';

/// Optional game background selected by a balloon skin.
///
/// Rarity never implies a background. A skin must opt in through its own
/// definition data.
enum BalloonBackgroundType { none, galaxy, halloween, winter, underwater }

@immutable
class BalloonBackgroundSpec {
  const BalloonBackgroundSpec({required this.type, this.assetPath});

  final BalloonBackgroundType type;
  final String? assetPath;
}

/// Single registry used by both the shop preview and gameplay.
///
/// NEW BACKGROUND: add an optimized static asset to pubspec.yaml, then set its
/// path on the matching entry below. Until a path is registered, the renderer
/// safely keeps the caller's existing background.
abstract final class BalloonBackgroundRegistry {
  static const definitions = <BalloonBackgroundType, BalloonBackgroundSpec>{
    BalloonBackgroundType.none: BalloonBackgroundSpec(
      type: BalloonBackgroundType.none,
    ),
    BalloonBackgroundType.galaxy: BalloonBackgroundSpec(
      type: BalloonBackgroundType.galaxy,
    ),
    BalloonBackgroundType.halloween: BalloonBackgroundSpec(
      type: BalloonBackgroundType.halloween,
    ),
    BalloonBackgroundType.winter: BalloonBackgroundSpec(
      type: BalloonBackgroundType.winter,
    ),
    BalloonBackgroundType.underwater: BalloonBackgroundSpec(
      type: BalloonBackgroundType.underwater,
    ),
  };

  static BalloonBackgroundSpec definitionFor(BalloonBackgroundType type) =>
      definitions[type]!;
}

/// Shared, static background renderer for preview and gameplay surfaces.
///
/// It never creates timers or animation controllers. [fallback] preserves the
/// existing surface exactly for `none` and for future types whose asset has not
/// been registered yet.
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
    if (background == BalloonBackgroundType.none || assetPath == null) {
      return fallback;
    }
    return RepaintBoundary(
      child: Image.asset(assetPath, fit: fit),
    );
  }
}
