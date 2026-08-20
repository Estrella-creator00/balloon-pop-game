import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../components/balloon_component.dart';
import 'flame_stage_definition.dart';

typedef StageBalloonPopRequest = bool Function(BalloonComponent balloon);

class StageBalloonSpawner {
  const StageBalloonSpawner({this.seed = 3107});

  static const int maxPlacementAttemptsPerBalloon = 20;
  static const double minimumGap = 8;

  final int seed;

  List<BalloonComponent> create({
    required FlameStageDefinition definition,
    required Vector2 playfieldSize,
    required int idBase,
    required StageBalloonPopRequest onPopRequested,
  }) {
    // Component ids change per generation, but a seeded stage keeps the same
    // initial layout and motion after restart.
    final random = Random(seed + definition.stage * 997);
    final placedBounds = <Rect>[];
    final balloons = <BalloonComponent>[];

    for (var index = 0; index < definition.balloonCount; index++) {
      final scale = definition.sizeScaleRange.valueAt(random.nextDouble());
      final balloonSize = Vector2(
        BalloonComponent.balloonWidth * scale,
        BalloonComponent.balloonHeight * scale,
      );
      final position = _findPosition(
        index: index,
        size: balloonSize,
        playfieldSize: playfieldSize,
        occupied: placedBounds,
        random: random,
      );
      final speed = definition.speedRange.valueAt(random.nextDouble());
      final direction = _directions[index % _directions.length];
      final color = _colors[index % _colors.length];
      final balloon = BalloonComponent(
        balloonId: idBase + index,
        position: position,
        balloonSize: balloonSize,
        velocity: Vector2(direction.dx * speed, direction.dy * speed),
        playfieldSize: () => playfieldSize,
        onPopRequested: onPopRequested,
        color: color,
      );
      balloons.add(balloon);
      placedBounds.add(balloon.playfieldBounds.inflate(minimumGap / 2));
    }
    return balloons;
  }

  Vector2 _findPosition({
    required int index,
    required Vector2 size,
    required Vector2 playfieldSize,
    required List<Rect> occupied,
    required Random random,
  }) {
    final maxX = max(0.0, playfieldSize.x - size.x);
    final maxY = max(0.0, playfieldSize.y - size.y);
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
    final columns = max(1, (playfieldSize.x / size.x).floor());
    final row = index ~/ columns;
    final column = index % columns;
    return Vector2(
      min(maxX, column * (maxX / max(1, columns - 1))),
      min(maxY, row * size.y),
    );
  }

  static const List<Offset> _preferredPositions = <Offset>[
    Offset(0.16, 0.18),
    Offset(0.70, 0.58),
    Offset(0.42, 0.36),
    Offset(0.08, 0.72),
  ];

  static const List<Offset> _directions = <Offset>[
    Offset(0.63, 0.78),
    Offset(-0.75, -0.66),
    Offset(0.82, -0.57),
    Offset(-0.66, 0.75),
  ];

  static const List<Color> _colors = <Color>[
    Color(0xFFFF6B9D),
    Color(0xFF5BC0EB),
    Color(0xFFFFC857),
    Color(0xFF8ED081),
  ];
}
