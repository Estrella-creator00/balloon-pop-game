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
typedef BossSpriteResolver = Image Function(int hp, {bool fake});

class BossBalloonComponent extends PositionComponent with TapCallbacks {
  BossBalloonComponent({
    required this.bossId,
    required this.generation,
    required Vector2 position,
    required this.velocity,
    required this.playfieldSize,
    required this.rule,
    required this.initialSize,
    required this.readHp,
    required this.readIsFake,
    required this.onHitRequested,
    required this.directionRoll,
    required this.spriteResolver,
    required Image initialSprite,
    required bool initialIsFake,
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
    if (initialIsFake) _spritePaint.color = const Color(0x59FFFFFF);
  }

  final int bossId;
  final int generation;
  final Vector2 velocity;
  final Vector2 Function() playfieldSize;
  final FlameBossRule rule;
  final double initialSize;
  final int Function(int bossId) readHp;
  final bool Function(int bossId) readIsFake;
  final BossHitRequest onHitRequested;
  final double Function() directionRoll;
  final BossSpriteResolver spriteResolver;
  final double turnIntervalOffset;
  final Paint _spritePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  Image _sprite;
  Rect _sourceRect;
  Rect _destinationRect;
  int _visualHp;
  bool _hitRequestInProgress = false;
  bool _defeated = false;
  double turnCooldown;
  double _lastAppliedDelta = 0;

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
    _sprite = spriteResolver(hp, fake: isFake);
    final nextDiameter = rule.sizeForHp(initialSize, hp);
    size.setValues(nextDiameter, nextDiameter + 32);
    _sourceRect = Rect.fromLTWH(
      0,
      0,
      _sprite.width.toDouble(),
      _sprite.height.toDouble(),
    );
    _destinationRect = Rect.fromLTWH(0, 0, size.x, size.y);

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
    _sprite = spriteResolver(currentHp, fake: isFake);
    _sourceRect = Rect.fromLTWH(
      0,
      0,
      _sprite.width.toDouble(),
      _sprite.height.toDouble(),
    );
    _spritePaint.color =
        isFake ? const Color(0x59FFFFFF) : const Color(0xFFFFFFFF);
  }

  void markDefeated() {
    _defeated = true;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawImageRect(_sprite, _sourceRect, _destinationRect, _spritePaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    requestHit(worldPoint: position + event.localPosition);
  }

  bool requestHit({Vector2? worldPoint}) {
    if (_defeated || _hitRequestInProgress) return false;
    _hitRequestInProgress = true;
    final accepted = onHitRequested(this, worldPoint);
    _hitRequestInProgress = false;
    return accepted;
  }
}
