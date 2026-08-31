import 'package:flutter/foundation.dart' show ValueListenable;
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
  static const gameplaySkyAssetPath =
      'assets/images/gameplay_sky_background.png';
  static const crystalGameplayAssetSize = Size(720, 1280);
  static const crystalImpactGlowAssetPath =
      'assets/images/gemi_crack_glow_runtime.png';
  static const crystalImpactGlowSourceRect = Rect.fromLTWH(
    143,
    311,
    423,
    581,
  );
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

  static String? gameplayAssetPathFor(BalloonBackgroundType type) =>
      switch (type) {
        BalloonBackgroundType.crystalCave =>
          'assets/images/gemi_background_mobile.png',
        BalloonBackgroundType.creamCafe =>
          'assets/images/shushu_background_mobile.png',
        _ => definitionFor(type).assetPath,
      };
}

/// One static, full-route background for every non-legendary gameplay skin.
/// It lives in Flutter's retained layer tree rather than Flame's render loop.
class GameplaySkyBackground extends StatelessWidget {
  const GameplaySkyBackground({super.key});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        key: const ValueKey('gameplay-sky-background-boundary'),
        child: Image.asset(
          BalloonBackgroundRegistry.gameplaySkyAssetPath,
          key: const ValueKey('gameplay-sky-background-image'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
      );
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
    this.crystalPulseListenable,
    this.assetPathOverride,
    this.cacheWidth = 1024,
  });
  final BalloonBackgroundType background;
  final Widget fallback;
  final BoxFit fit;
  final double crystalPulse;
  final ValueListenable<double>? crystalPulseListenable;
  final String? assetPathOverride;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final assetPath = assetPathOverride ??
        BalloonBackgroundRegistry.definitionFor(background).assetPath;
    if (assetPath != null) {
      final image = Image.asset(
        assetPath,
        fit: fit,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
      );
      if (background != BalloonBackgroundType.crystalCave) {
        return RepaintBoundary(child: image);
      }
      final pulse = crystalPulseListenable;
      if (pulse != null) {
        final glowImage = RepaintBoundary(
          key: const ValueKey('background-crystal-impact-glow-image'),
          child: Image.asset(
            BalloonBackgroundRegistry.crystalImpactGlowAssetPath,
            fit: BoxFit.fill,
            cacheWidth: 423,
            gaplessPlayback: true,
          ),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              key: const ValueKey('background-crystal-image-boundary'),
              child: image,
            ),
            ValueListenableBuilder<double>(
              valueListenable: pulse,
              child: glowImage,
              builder: (context, value, child) => _CrystalImpactGlowPlacement(
                opacity: 0.18 + value.clamp(0.0, 1.0) * 0.82,
                child: child!,
              ),
            ),
          ],
        );
      }
      const pulseGlow = RepaintBoundary(
        child: DecoratedBox(
          key: ValueKey('background-crystal-pulse-glow'),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.18),
              radius: 0.43,
              colors: [Color.fromRGBO(184, 225, 255, 0.239), Color(0x00000000)],
            ),
          ),
        ),
      );
      Widget pulseLayer(double value, Widget child) => Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          );
      return Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            key: const ValueKey('background-crystal-image-boundary'),
            child: image,
          ),
          RepaintBoundary(
            child: const DecoratedBox(
              key: ValueKey('background-crystal-glow'),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.18),
                  radius: 0.43,
                  colors: [
                    Color.fromRGBO(184, 225, 255, 0.08),
                    Color(0x00000000)
                  ],
                ),
              ),
            ),
          ),
          pulseLayer(crystalPulse, pulseGlow),
        ],
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

class _CrystalImpactGlowPlacement extends StatelessWidget {
  const _CrystalImpactGlowPlacement({
    required this.opacity,
    required this.child,
  });

  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.biggest;
          final fitted = applyBoxFit(
            BoxFit.cover,
            BalloonBackgroundRegistry.crystalGameplayAssetSize,
            viewport,
          );
          final destination = fitted.destination;
          final scale = destination.width /
              BalloonBackgroundRegistry.crystalGameplayAssetSize.width;
          final imageLeft = (viewport.width - destination.width) / 2;
          final imageTop = (viewport.height - destination.height) / 2;
          final source = BalloonBackgroundRegistry.crystalImpactGlowSourceRect;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: imageLeft + source.left * scale,
                top: imageTop + source.top * scale,
                width: source.width * scale,
                height: source.height * scale,
                child: Opacity(opacity: opacity, child: child),
              ),
            ],
          );
        },
      );
}
