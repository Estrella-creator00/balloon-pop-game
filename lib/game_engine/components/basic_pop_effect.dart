import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../balloon_skin_catalog.dart';
import 'balloon_component.dart';

typedef PopEffectFinished = void Function(BasicPopEffect effect);

class BasicPopEffect extends PositionComponent {
  BasicPopEffect({
    required Vector2 center,
    required Color color,
    required this.onFinished,
    this.effectType = BalloonPopEffectType.shards,
    this.themed = false,
    this.big = false,
  })  : _color = color,
        super(position: center, anchor: Anchor.center, priority: 20);

  static const int particleCount = 6;
  static const int normalThemedParticleCount = 7;
  static const int bossThemedParticleCount = 18;
  static const double lifetime = 0.30;
  static const List<double> _legacyAngles = <double>[
    -2.70,
    -1.82,
    -0.94,
    -0.05,
    0.84,
    1.73,
  ];
  static const List<double> _legacySpeeds = <double>[58, 68, 62, 72, 60, 66];

  final Color _color;
  final PopEffectFinished onFinished;
  final BalloonPopEffectType effectType;
  final bool themed;
  final bool big;
  final Paint _paint = Paint()..isAntiAlias = true;
  static final Path _heartPath = Path()
    ..moveTo(0, 1)
    ..cubicTo(-1.7, 0, -1, -1, 0, -0.2)
    ..cubicTo(1, -1, 1.7, 0, 0, 1);
  double _elapsed = 0;
  bool _finished = false;

  int get activeParticleCount => themed
      ? (big ? bossThemedParticleCount : normalThemedParticleCount)
      : particleCount;
  double get _lifetime => themed ? (big ? 1.15 : 0.72) : lifetime;

  @override
  void update(double dt) {
    _elapsed += min(dt, BalloonComponent.maxUpdateDelta);
    if (_elapsed < _lifetime || _finished) return;
    _finished = true;
    removeFromParent();
    onFinished(this);
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / _lifetime).clamp(0.0, 1.0);
    _paint.color = _color.withValues(alpha: 1 - progress);
    if (!themed) {
      for (var index = 0; index < particleCount; index++) {
        final distance = _legacySpeeds[index] * _elapsed;
        canvas.drawCircle(
          Offset(
            cos(_legacyAngles[index]) * distance,
            sin(_legacyAngles[index]) * distance,
          ),
          4 * (1 - progress * 0.45),
          _paint,
        );
      }
      return;
    }
    for (var index = 0; index < activeParticleCount; index++) {
      final angle = -2.72 + index * (pi * 2 / activeParticleCount);
      final speed = (big ? 124.0 : 72.0) + (index % 4) * 8;
      final distance = speed * _elapsed;
      final center = Offset(
        cos(angle) * distance,
        sin(angle) * distance + 48 * _elapsed * _elapsed,
      );
      final radius = (big ? 6.5 : 4.2) * (1 - progress * 0.45);
      switch (effectType) {
        case BalloonPopEffectType.hearts:
          _drawHeart(canvas, center, radius);
        case BalloonPopEffectType.mist:
          canvas.drawOval(
            Rect.fromCenter(
              center: center,
              width: radius * 3,
              height: radius * 1.6,
            ),
            _paint,
          );
        case BalloonPopEffectType.shards:
        case BalloonPopEffectType.gel:
        case BalloonPopEffectType.crystal:
        case BalloonPopEffectType.cream:
          canvas.drawCircle(center, radius, _paint);
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double radius) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(radius, radius)
      ..drawPath(_heartPath, _paint)
      ..restore();
  }
}
