import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/foundation.dart';

typedef BalloonPopRequest = bool Function(BalloonComponent balloon);

@immutable
class StageOneBalloonSpawn {
  const StageOneBalloonSpawn({
    required this.id,
    required this.positionFactor,
    required this.velocity,
    required this.color,
  });

  final int id;
  final Offset positionFactor;
  final Offset velocity;
  final Color color;
}

const stageOneBalloonSpawns = <StageOneBalloonSpawn>[
  StageOneBalloonSpawn(
    id: 1,
    positionFactor: Offset(0.16, 0.18),
    velocity: Offset(58, 72),
    color: Color(0xFFFF6B9D),
  ),
  StageOneBalloonSpawn(
    id: 2,
    positionFactor: Offset(0.70, 0.58),
    velocity: Offset(-64, -56),
    color: Color(0xFF5BC0EB),
  ),
];

/// A complete Stage 1 gameplay object: state, movement, rendering and hit area.
class BalloonComponent extends PositionComponent with TapCallbacks {
  BalloonComponent({
    required this.balloonId,
    required Vector2 position,
    required this.velocity,
    required this.playfieldSize,
    required this.onPopRequested,
    required this.color,
  }) : super(
          position: position,
          size: Vector2(balloonWidth, balloonHeight),
          anchor: Anchor.topLeft,
        ) {
    _bodyPaint.color = color;
    _tailPaint.color = color;
  }

  static const double balloonWidth = 72;
  static const double balloonHeight = 98;
  static const double bodyHeight = 72;
  static const double maxUpdateDelta = 0.05;

  final int balloonId;
  final Color color;
  final Vector2 velocity;
  final Vector2 Function() playfieldSize;
  final BalloonPopRequest onPopRequested;

  final Paint _bodyPaint = Paint()..isAntiAlias = true;
  final Paint _tailPaint = Paint()..isAntiAlias = true;
  final Paint _stringPaint = Paint()
    ..isAntiAlias = true
    ..color = const Color(0xFFB58C72)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  final Paint _highlightPaint = Paint()
    ..isAntiAlias = true
    ..color = const Color(0x66FFFFFF);
  final Path _bodyPath = Path()
    ..addOval(const Rect.fromLTWH(2, 0, 68, bodyHeight));
  final Path _tailPath = Path()
    ..moveTo(31, 69)
    ..lineTo(41, 69)
    ..lineTo(36, 78)
    ..close();
  static const Offset _stringStart = Offset(36, 77);
  static const Offset _stringEnd = Offset(36, balloonHeight);
  static const Offset _highlightCenter = Offset(24, 21);

  bool _popRequested = false;
  double lastAppliedDelta = 0;

  bool get isActive => !_popRequested && !isRemoving && !isRemoved;
  Rect get playfieldBounds => Rect.fromLTWH(
        position.x,
        position.y,
        size.x,
        size.y,
      );

  @override
  void render(Canvas canvas) {
    canvas.drawLine(_stringStart, _stringEnd, _stringPaint);
    canvas.drawPath(_bodyPath, _bodyPaint);
    canvas.drawPath(_tailPath, _tailPaint);
    canvas.drawCircle(_highlightCenter, 7, _highlightPaint);
  }

  @override
  void update(double dt) {
    final clampedDt = min(dt, maxUpdateDelta);
    lastAppliedDelta = clampedDt;
    position.x += velocity.x * clampedDt;
    position.y += velocity.y * clampedDt;
    _resolveBounds(playfieldSize());
  }

  void _resolveBounds(Vector2 bounds) {
    final maxX = max(0.0, bounds.x - size.x);
    final maxY = max(0.0, bounds.y - size.y);
    if (position.x <= 0) {
      position.x = 0;
      velocity.x = velocity.x.abs();
    } else if (position.x >= maxX) {
      position.x = maxX;
      velocity.x = -velocity.x.abs();
    }
    if (position.y <= 0) {
      position.y = 0;
      velocity.y = velocity.y.abs();
    } else if (position.y >= maxY) {
      position.y = maxY;
      velocity.y = -velocity.y.abs();
    }
  }

  bool requestPop() {
    if (!isActive) return false;
    _popRequested = true;
    final accepted = onPopRequested(this);
    if (!accepted) _popRequested = false;
    return accepted;
  }

  @override
  void onTapDown(TapDownEvent event) {
    requestPop();
  }
}
