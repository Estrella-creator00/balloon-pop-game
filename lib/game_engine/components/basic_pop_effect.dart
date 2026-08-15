import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import 'balloon_component.dart';

typedef PopEffectFinished = void Function(BasicPopEffect effect);

class BasicPopEffect extends PositionComponent {
  BasicPopEffect({
    required Vector2 center,
    required Color color,
    required this.onFinished,
  })  : _color = color,
        super(position: center, anchor: Anchor.center, priority: 20);

  static const int particleCount = 6;
  static const double lifetime = 0.30;
  static const List<double> _angles = <double>[
    -2.70,
    -1.82,
    -0.94,
    -0.05,
    0.84,
    1.73,
  ];
  static const List<double> _speeds = <double>[58, 68, 62, 72, 60, 66];

  final Color _color;
  final PopEffectFinished onFinished;
  final Paint _paint = Paint()..isAntiAlias = true;
  double _elapsed = 0;
  bool _finished = false;

  @override
  void update(double dt) {
    _elapsed += min(dt, BalloonComponent.maxUpdateDelta);
    if (_elapsed < lifetime || _finished) return;
    _finished = true;
    removeFromParent();
    onFinished(this);
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / lifetime).clamp(0.0, 1.0);
    _paint.color = _color.withValues(alpha: 1 - progress);
    for (var index = 0; index < particleCount; index++) {
      final distance = _speeds[index] * _elapsed;
      canvas.drawCircle(
        Offset(
          cos(_angles[index]) * distance,
          sin(_angles[index]) * distance,
        ),
        4 * (1 - progress * 0.45),
        _paint,
      );
    }
  }
}
