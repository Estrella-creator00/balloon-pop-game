import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

typedef BalloonPopRequest = bool Function(BalloonComponent balloon);

/// A complete Stage 1 gameplay object: state, movement, rendering and hit area.
class BalloonComponent extends PositionComponent with TapCallbacks {
  BalloonComponent({
    required this.balloonId,
    required Vector2 position,
    required this.velocity,
    required this.playfieldSize,
    required this.onPopRequested,
    required this.color,
    Vector2? balloonSize,
  }) : super(
          position: position,
          size: balloonSize ?? Vector2(balloonWidth, balloonHeight),
          anchor: Anchor.topLeft,
        ) {
    _bodyPaint.color = color;
    _tailPaint.color = color;
    _buildGeometry();
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
  late final Path _bodyPath;
  late final Path _tailPath;
  late final Offset _stringStart;
  late final Offset _stringEnd;
  late final Offset _highlightCenter;
  late final double _highlightRadius;

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
    canvas.drawCircle(_highlightCenter, _highlightRadius, _highlightPaint);
  }

  void _buildGeometry() {
    final scaleX = size.x / balloonWidth;
    final scaleY = size.y / balloonHeight;
    final bodyHeight = BalloonComponent.bodyHeight * scaleY;
    final centerX = size.x / 2;
    _bodyPath = Path()
      ..addOval(
        Rect.fromLTWH(
          2 * scaleX,
          0,
          68 * scaleX,
          bodyHeight,
        ),
      );
    _tailPath = Path()
      ..moveTo(centerX - 5 * scaleX, bodyHeight - 3 * scaleY)
      ..lineTo(centerX + 5 * scaleX, bodyHeight - 3 * scaleY)
      ..lineTo(centerX, bodyHeight + 6 * scaleY)
      ..close();
    _stringStart = Offset(centerX, bodyHeight + 5 * scaleY);
    _stringEnd = Offset(centerX, size.y);
    _highlightCenter = Offset(24 * scaleX, 21 * scaleY);
    _highlightRadius = 7 * min(scaleX, scaleY);
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
