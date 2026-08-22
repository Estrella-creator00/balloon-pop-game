import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../stages/flame_stage_definition.dart';
import 'balloon_component.dart';

typedef BossHitRequest = bool Function(BossBalloonComponent boss);

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
    required this.onHitRequested,
    required this.directionRoll,
    required Image initialSprite,
  })  : _sprite = initialSprite,
        _visualHp = rule.maxHp,
        turnCooldown = rule.initialTurnCooldown,
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
        );

  final int bossId;
  final int generation;
  final Vector2 velocity;
  final Vector2 Function() playfieldSize;
  final FlameBossRule rule;
  final double initialSize;
  final int Function(int bossId) readHp;
  final BossHitRequest onHitRequested;
  final double Function() directionRoll;
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
      turnCooldown = rule.turnCooldownForHp(currentHp);
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

  void applyRegisteredHit({required int hp, required Image sprite}) {
    if (_defeated || hp <= 0 || hp >= _visualHp) return;
    _visualHp = hp;
    _sprite = sprite;
    final nextDiameter = rule.sizeForHp(initialSize, hp);
    size.setValues(nextDiameter, nextDiameter + 32);
    _sourceRect = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );
    _destinationRect = Rect.fromLTWH(0, 0, size.x, size.y);

    final speed = rule.speedForHp(hp);
    final currentSpeed = velocity.length;
    if (currentSpeed > 0) {
      velocity.scale(speed / currentSpeed);
    }
    turnCooldown = math.min(turnCooldown, rule.hitTurnCooldownForHp(hp));
    _reflectInsidePlayfield();
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
    requestHit();
  }

  bool requestHit() {
    if (_defeated || _hitRequestInProgress) return false;
    _hitRequestInProgress = true;
    final accepted = onHitRequested(this);
    _hitRequestInProgress = false;
    return accepted;
  }
}
