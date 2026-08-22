import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../balloon_skin_catalog.dart';
import '../components/balloon_component.dart';
import 'flame_stage_definition.dart';

typedef StageBalloonHitRequest = bool Function(BalloonComponent balloon);

class StageBalloonSpawner {
  const StageBalloonSpawner({this.seed = 3107});

  static const int maxPlacementAttemptsPerBalloon = 20;
  static const double minimumGap = 8;

  final int seed;

  List<BalloonComponent> create({
    required FlameStageDefinition definition,
    required Vector2 Function() playfieldSize,
    required int generation,
    required int idBase,
    required StageBalloonHitRequest onHitRequested,
    required int Function(int id) readHp,
    required BalloonSpriteResolver spriteResolver,
    List<Color>? palette,
    bool preserveSpriteAspectRatio = false,
    bool breatheIdle = false,
    bool ghostIdle = false,
    double baseSpriteOpacity = 1,
    double fakeSpriteOpacity = 0.35,
    int visualVariantCount = 1,
  }) {
    // Component ids change per generation, but a seeded stage keeps the same
    // initial layout and motion after restart.
    final random = math.Random(seed + definition.stage * 997);
    final placedBounds = <Rect>[];
    final balloons = <BalloonComponent>[];
    final initialPlayfieldSize = playfieldSize();
    final activePalette =
        palette ?? BalloonSkinCatalog.defaultSkin.colorPalette;

    final totalCount =
        definition.balloonCount + definition.balloonRule.fakeCount;
    for (var index = 0; index < totalCount; index++) {
      final isFake = index >= definition.balloonCount;
      final width = definition.sizeRange.valueAt(random.nextDouble());
      final balloonSize = Vector2(
        width,
        width + BalloonComponent.stringHeight,
      );
      final position = _findPosition(
        index: index,
        totalCount: totalCount,
        size: balloonSize,
        playfieldSize: initialPlayfieldSize,
        occupied: placedBounds,
        random: random,
      );
      final speed = definition.speedRange.valueAt(random.nextDouble());
      final angle = random.nextDouble() * math.pi * 2;
      final color = activePalette[random.nextInt(activePalette.length)];
      final visualVariant = visualVariantCount <= 1
          ? 0
          : (random.nextDouble() * visualVariantCount).floor();
      final balloon = BalloonComponent(
        balloonId: idBase + index,
        generation: generation,
        position: position,
        balloonSize: balloonSize,
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
        playfieldSize: playfieldSize,
        onHitRequested: onHitRequested,
        readHp: readHp,
        color: color,
        maxHp: isFake ? 1 : definition.balloonRule.requiredHits,
        isFake: isFake,
        sprite: spriteResolver(
          color,
          isFake ? 1 : definition.balloonRule.requiredHits,
          isFake ? 1 : definition.balloonRule.requiredHits,
          isFake,
          visualVariant,
        ),
        spriteResolver: spriteResolver,
        visualVariant: visualVariant,
        floatPhase: random.nextDouble() * math.pi * 2,
        floatPower: 10 + random.nextDouble() * 10,
        firstHitSizeMultiplier: definition.balloonRule.firstHitSizeMultiplier,
        preserveSpriteAspectRatio: preserveSpriteAspectRatio,
        breatheIdle: breatheIdle,
        ghostIdle: ghostIdle,
        baseSpriteOpacity: baseSpriteOpacity,
        spriteOpacity: isFake ? fakeSpriteOpacity : 1,
      );
      balloons.add(balloon);
      placedBounds.add(balloon.playfieldBounds.inflate(minimumGap / 2));
    }
    return balloons;
  }

  Vector2 _findPosition({
    required int index,
    required int totalCount,
    required Vector2 size,
    required Vector2 playfieldSize,
    required List<Rect> occupied,
    required math.Random random,
  }) {
    final maxX = math.max(0.0, playfieldSize.x - size.x);
    final maxY = math.max(0.0, playfieldSize.y - size.y);
    final preferred = _preferredPositions[index % _preferredPositions.length];

    for (var attempt = 0; attempt < maxPlacementAttemptsPerBalloon; attempt++) {
      final xFactor = attempt == 0 ? preferred.dx : random.nextDouble();
      final yFactor = attempt == 0 ? preferred.dy : random.nextDouble();
      final candidate = Rect.fromLTWH(
        maxX * xFactor,
        maxY * yFactor,
        size.x,
        size.y,
      );
      if (occupied.every((bounds) => !bounds.overlaps(candidate))) {
        return Vector2(candidate.left, candidate.top);
      }
    }

    // Bounded fallback: use a deterministic grid even when a very small
    // viewport cannot satisfy the preferred gap. No retry loop can run forever.
    final aspect =
        playfieldSize.y <= 0 ? 1.0 : playfieldSize.x / playfieldSize.y;
    final columns = math.max(1, math.sqrt(totalCount * aspect).ceil());
    final rows = math.max(1, (totalCount / columns).ceil());
    final row = index ~/ columns;
    final column = index % columns;
    return Vector2(
      math.min(maxX, column * (maxX / math.max(1, columns - 1))),
      math.min(maxY, row * (maxY / math.max(1, rows - 1))),
    );
  }

  static const List<Offset> _preferredPositions = <Offset>[
    Offset(0.16, 0.18),
    Offset(0.70, 0.58),
    Offset(0.42, 0.36),
    Offset(0.08, 0.72),
  ];
}
