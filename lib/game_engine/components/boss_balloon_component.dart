import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../stages/flame_stage_definition.dart';
import 'balloon_component.dart';

typedef BossHitRequest = bool Function(
  BossBalloonComponent boss,
  Vector2? worldPoint,
);
typedef BossSpriteResolver = Image Function(Color color, int hp, {bool fake});

class BossBalloonComponent extends PositionComponent with TapCallbacks {
  BossBalloonComponent({
    required this.bossId,
    required this.generation,
    required Vector2 position,
    required this.velocity,
    required this.playfieldSize,
    required this.rule,
    required this.initialSize,
    required this.color,
    required this.readHp,
    required this.readIsFake,
    required this.onHitRequested,
    required this.directionRoll,
    required this.spriteResolver,
    required Image initialSprite,
    required bool initialIsFake,
    this.preserveSpriteAspectRatio = false,
    this.breatheIdle = false,
    this.drawHealthBarSeparately = false,
    this.fakeSpriteOpacity = 0.35,
    this.turnIntervalOffset = 0,
    double? initialTurnCooldown,
  })  : _sprite = initialSprite,
        _visualHp = rule.maxHp,
        turnCooldown = initialTurnCooldown ?? rule.initialTurnCooldown,
        _sourceRect = Rect.fromLTWH(
          0,
          0,
          initialSprite.width.toDouble(),
          initialSprite.height.toDouble(),
        ),
        _destinationRect = Rect.fromLTWH(0, 0, initialSize, initialSize + 32),
        super(
          position: position,
          size: Vector2(initialSize, initialSize + 32),
          priority: 100,
        ) {
    if (initialIsFake) {
      _spritePaint.color = Color.fromRGBO(255, 255, 255, fakeSpriteOpacity);
    }
    _refreshDestinationRect();
    _refreshHealthBarGeometry();
  }

  final int bossId;
  final int generation;
  final Vector2 velocity;
  final Vector2 Function() playfieldSize;
  final FlameBossRule rule;
  final double initialSize;
  final Color color;
  final int Function(int bossId) readHp;
  final bool Function(int bossId) readIsFake;
  final BossHitRequest onHitRequested;
  final double Function() directionRoll;
  final BossSpriteResolver spriteResolver;
  final double turnIntervalOffset;
  final bool preserveSpriteAspectRatio;
  final bool breatheIdle;
  final bool drawHealthBarSeparately;
  final double fakeSpriteOpacity;
  final Paint _spritePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;
  final Paint _healthTrackPaint = Paint()..color = const Color(0x73000000);
  final Paint _healthFillPaint = Paint()..color = const Color(0xFFFF5C8A);

  Image _sprite;
  Rect _sourceRect;
  Rect _destinationRect;
  int _visualHp;
  bool _hitRequestInProgress = false;
  bool _defeated = false;
  double turnCooldown;
  double _lastAppliedDelta = 0;
  double _visualPhase = 0;
  Rect _healthTrackRect = Rect.zero;
  Rect _healthFillRect = Rect.zero;
  RRect _healthTrackRRect = RRect.zero;
  RRect _healthFillRRect = RRect.zero;

  static final List<double> _breatheScale = List<double>.generate(
    256,
    (index) => 1 + math.sin(index * math.pi * 2 / 256) * 0.018,
    growable: false,
  );

  int get currentHp => readHp(bossId);
  int get visualHp => _visualHp;
  int get maxHp => rule.maxHp;
  bool get isDefeated => _defeated;
  bool get isFake => readIsFake(bossId);
  double get diameter => size.x;
  double get lastAppliedDelta => _lastAppliedDelta;
  Color get displayColor => rule.colorForHp(_visualHp);
  Rect get playfieldBounds => Rect.fromLTWH(
        position.x,
        position.y,
        size.x,
        size.y,
      );

  @override
  void update(double dt) {
    super.update(dt);
    if (_defeated) return;
    final clampedDt = dt.clamp(0.0, BalloonComponent.maxUpdateDelta).toDouble();
    _lastAppliedDelta = clampedDt;
    _visualPhase += clampedDt * 2.2;

    turnCooldown -= clampedDt;
    if (turnCooldown <= 0) {
      final speed = velocity.length;
      final angle = directionRoll() * math.pi * 2;
      velocity.setValues(math.cos(angle) * speed, math.sin(angle) * speed);
      turnCooldown = rule.turnCooldownForHp(
        currentHp,
        offset: turnIntervalOffset,
      );
    }

    position.addScaled(velocity, clampedDt);
    _reflectInsidePlayfield();
  }

  void _reflectInsidePlayfield() {
    final bounds = playfieldSize();
    final maxX = math.max(0.0, bounds.x - diameter);
    final maxY = math.max(0.0, bounds.y - diameter - 26);
    if (position.x <= 0 && velocity.x < 0) velocity.x = -velocity.x;
    if (position.x >= maxX && velocity.x > 0) velocity.x = -velocity.x;
    if (position.y <= 0 && velocity.y < 0) velocity.y = -velocity.y;
    if (position.y >= maxY && velocity.y > 0) velocity.y = -velocity.y;
    position.x = position.x.clamp(0.0, maxX).toDouble();
    position.y = position.y.clamp(0.0, maxY).toDouble();
  }

  void applyRegisteredHit({required int hp}) {
    if (_defeated || hp <= 0 || hp >= _visualHp) return;
    _visualHp = hp;
    _sprite = spriteResolver(color, hp, fake: isFake);
    final nextDiameter = rule.sizeForHp(initialSize, hp);
    size.setValues(nextDiameter, nextDiameter + 32);
    _sourceRect = Rect.fromLTWH(
      0,
      0,
      _sprite.width.toDouble(),
      _sprite.height.toDouble(),
    );
    _refreshDestinationRect();
    _refreshHealthBarGeometry();

    final speed = rule.speedForHp(hp);
    final currentSpeed = velocity.length;
    if (currentSpeed > 0) {
      velocity.scale(speed / currentSpeed);
    }
    turnCooldown = math.min(
      turnCooldown,
      rule.hitTurnCooldownForHp(hp, offset: turnIntervalOffset),
    );
    _reflectInsidePlayfield();
  }

  void refreshRole() {
    if (_defeated || currentHp <= 0) return;
    _sprite = spriteResolver(color, currentHp, fake: isFake);
    _sourceRect = Rect.fromLTWH(
      0,
      0,
      _sprite.width.toDouble(),
      _sprite.height.toDouble(),
    );
    _spritePaint.color = isFake
        ? Color.fromRGBO(255, 255, 255, fakeSpriteOpacity)
        : const Color(0xFFFFFFFF);
  }

  void _refreshDestinationRect() {
    final bodyHeight = size.x;
    if (!preserveSpriteAspectRatio) {
      _destinationRect = Rect.fromLTWH(0, 0, size.x, size.y);
      return;
    }
    final sourceAspect = _sprite.width / _sprite.height;
    final width = sourceAspect >= 1 ? size.x : bodyHeight * sourceAspect;
    final height = sourceAspect >= 1 ? size.x / sourceAspect : bodyHeight;
    _destinationRect = Rect.fromLTWH(
      (size.x - width) / 2,
      (bodyHeight - height) / 2,
      width,
      height,
    );
  }

  void _refreshHealthBarGeometry() {
    final width = size.x * 0.72;
    _healthTrackRect = Rect.fromLTWH(
      (size.x - width) / 2,
      size.y - 16,
      width,
      8,
    );
    _healthFillRect = Rect.fromLTWH(
      _healthTrackRect.left,
      _healthTrackRect.top,
      width * (_visualHp / maxHp).clamp(0.0, 1.0),
      _healthTrackRect.height,
    );
    _healthTrackRRect =
        RRect.fromRectAndRadius(_healthTrackRect, const Radius.circular(4));
    _healthFillRRect =
        RRect.fromRectAndRadius(_healthFillRect, const Radius.circular(4));
  }

  void markDefeated() {
    _defeated = true;
  }

  @override
  void render(Canvas canvas) {
    if (breatheIdle) {
      final index = ((_visualPhase / (math.pi * 2) * 256).floor()) & 255;
      final scale = _breatheScale[index];
      canvas
        ..save()
        ..translate(size.x / 2, size.x / 2)
        ..scale(scale, scale)
        ..translate(-size.x / 2, -size.x / 2)
        ..drawImageRect(_sprite, _sourceRect, _destinationRect, _spritePaint)
        ..restore();
    } else {
      canvas.drawImageRect(
          _sprite, _sourceRect, _destinationRect, _spritePaint);
    }
    if (drawHealthBarSeparately && !isFake) {
      canvas
        ..drawRRect(_healthTrackRRect, _healthTrackPaint)
        ..drawRRect(_healthFillRRect, _healthFillPaint);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    requestHit(worldPoint: position + event.localPosition);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    if (!preserveSpriteAspectRatio) return super.containsLocalPoint(point);
    final hitBounds = breatheIdle
        ? _destinationRect.inflate(size.x * 0.02)
        : _destinationRect;
    return hitBounds.contains(Offset(point.x, point.y));
  }

  bool requestHit({Vector2? worldPoint}) {
    if (_defeated || _hitRequestInProgress) return false;
    _hitRequestInProgress = true;
    final accepted = onHitRequested(this, worldPoint);
    _hitRequestInProgress = false;
    return accepted;
  }
}
