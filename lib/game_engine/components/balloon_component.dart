import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

typedef BalloonHitRequest = bool Function(BalloonComponent balloon);
typedef BalloonSpriteResolver = Image Function(
  Color color,
  int hp,
  int maxHp,
  bool isFake,
);

class BalloonComponent extends PositionComponent with TapCallbacks {
  BalloonComponent({
    required this.balloonId,
    required this.generation,
    required Vector2 position,
    required Vector2 balloonSize,
    required this.velocity,
    required this.playfieldSize,
    required this.onHitRequested,
    required this.readHp,
    required this.color,
    required this.maxHp,
    required this.isFake,
    required Image sprite,
    required this.spriteResolver,
    required this.floatPhase,
    required this.floatPower,
    required this.firstHitSizeMultiplier,
  })  : _sprite = sprite,
        _visualHp = maxHp,
        _sourceRect = Rect.fromLTWH(
            0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
        _destinationRect = Rect.fromLTWH(0, 0, balloonSize.x, balloonSize.y),
        super(position: position, size: balloonSize, priority: balloonId) {
    if (isFake) _spritePaint.color = const Color(0x59FFFFFF);
  }

  static const double maxUpdateDelta = 0.05;
  static const double stringHeight = 26;
  static const double floatPhaseSpeed = 2.4;

  final int balloonId;
  final int generation;
  final Vector2 velocity;
  final Vector2 Function() playfieldSize;
  final BalloonHitRequest onHitRequested;
  final int Function(int id) readHp;
  final Color color;
  final int maxHp;
  final bool isFake;
  final BalloonSpriteResolver spriteResolver;
  final double floatPower;
  final double firstHitSizeMultiplier;
  final Paint _spritePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  Image _sprite;
  Rect _sourceRect;
  Rect _destinationRect;
  int _visualHp;
  bool _hitInProgress = false;
  bool _removed = false;
  double floatPhase;
  double _lastAppliedDelta = 0;

  int get currentHp => readHp(balloonId);
  int get visualHp => _visualHp;
  bool get isRemovedFromGame => _removed;
  bool get isPopRequested => _removed;
  double get lastAppliedDelta => _lastAppliedDelta;
  Rect get playfieldBounds =>
      Rect.fromLTWH(position.x, position.y, size.x, size.y);

  @override
  void update(double dt) {
    super.update(dt);
    if (_removed) return;
    final clamped = dt.clamp(0.0, maxUpdateDelta).toDouble();
    _lastAppliedDelta = clamped;
    floatPhase += clamped * floatPhaseSpeed;
    position.x += velocity.x * clamped;
    position.y +=
        velocity.y * clamped + math.sin(floatPhase) * floatPower * clamped;
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

  void applyRegisteredHit(int hp) {
    if (_removed || hp <= 0 || hp >= _visualHp) return;
    _visualHp = hp;
    _sprite = spriteResolver(color, hp, maxHp, isFake);
    final width = size.x * firstHitSizeMultiplier;
    size.setValues(width, width + stringHeight);
    _sourceRect = Rect.fromLTWH(
        0, 0, _sprite.width.toDouble(), _sprite.height.toDouble());
    _destinationRect = Rect.fromLTWH(0, 0, size.x, size.y);
    _reflectInsidePlayfield();
  }

  void markRemoved() => _removed = true;

  @override
  void render(Canvas canvas) => canvas.drawImageRect(
      _sprite, _sourceRect, _destinationRect, _spritePaint);

  @override
  void onTapDown(TapDownEvent event) => requestHit();

  bool requestHit() {
    if (_removed || _hitInProgress) return false;
    _hitInProgress = true;
    final accepted = onHitRequested(this);
    _hitInProgress = false;
    return accepted;
  }

  bool requestPop() => requestHit();
}
