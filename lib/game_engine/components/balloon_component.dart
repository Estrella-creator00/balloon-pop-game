import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

typedef BalloonPopRequest = bool Function(BalloonComponent balloon);

/// A single Flame-owned balloon. Position, movement, rendering and input all
/// use this component as their shared source of truth.
class BalloonComponent extends PositionComponent with TapCallbacks {
  BalloonComponent({
    required this.balloonId,
    required Vector2 position,
    required Vector2 balloonSize,
    required this.velocity,
    required this.playfieldSize,
    required this.onPopRequested,
    required this.color,
    required this.sprite,
    required this.floatPhase,
    required this.floatPower,
  })  : _sourceRect = Rect.fromLTWH(
          0,
          0,
          sprite.width.toDouble(),
          sprite.height.toDouble(),
        ),
        _destinationRect = Rect.fromLTWH(
          0,
          0,
          balloonSize.x,
          balloonSize.y,
        ),
        super(position: position, size: balloonSize, priority: balloonId);

  static const double maxUpdateDelta = 0.05;
  static const double stringHeight = 26;
  static const double floatPhaseSpeed = 2.4;

  final int balloonId;
  final Vector2 velocity;
  final Vector2 Function() playfieldSize;
  final BalloonPopRequest onPopRequested;
  final Color color;
  final Image sprite;
  final Rect _sourceRect;
  final Rect _destinationRect;
  final Paint _spritePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;
  final double floatPower;

  double floatPhase;
  double _lastAppliedDelta = 0;
  bool _popRequested = false;

  bool get isPopRequested => _popRequested;
  double get lastAppliedDelta => _lastAppliedDelta;
  Rect get playfieldBounds => Rect.fromLTWH(
        position.x,
        position.y,
        size.x,
        size.y,
      );

  @override
  void update(double dt) {
    super.update(dt);
    if (_popRequested) return;

    final clampedDt = dt.clamp(0.0, maxUpdateDelta).toDouble();
    _lastAppliedDelta = clampedDt;
    floatPhase += clampedDt * floatPhaseSpeed;
    position.x += velocity.x * clampedDt;
    position.y +=
        velocity.y * clampedDt + math.sin(floatPhase) * floatPower * clampedDt;
    _reflectInsidePlayfield();
  }

  void _reflectInsidePlayfield() {
    final bounds = playfieldSize();
    final maxX = math.max(0.0, bounds.x - size.x);
    final maxY = math.max(0.0, bounds.y - size.y);
    if (position.x <= 0 && velocity.x < 0) velocity.x = -velocity.x;
    if (position.x >= maxX && velocity.x > 0) velocity.x = -velocity.x;
    if (position.y <= 0 && velocity.y < 0) velocity.y = -velocity.y;
    if (position.y >= maxY && velocity.y > 0) velocity.y = -velocity.y;
    position.x = position.x.clamp(0.0, maxX).toDouble();
    position.y = position.y.clamp(0.0, maxY).toDouble();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawImageRect(sprite, _sourceRect, _destinationRect, _spritePaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    requestPop();
  }

  bool requestPop() {
    if (_popRequested) return false;
    if (!onPopRequested(this)) return false;
    _popRequested = true;
    return true;
  }
}
