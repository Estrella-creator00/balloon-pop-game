import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../stages/flame_stage_definition.dart';
import '../rendering/flame_sprite_frame.dart';
import 'balloon_component.dart';

typedef BossHitRequest = bool Function(
  BossBalloonComponent boss,
  Vector2? worldPoint,
);
typedef BossSpriteResolver = FlameSpriteFrame Function(
  Color color,
  int hp, {
  required bool fake,
  required int visualVariant,
});

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
    required FlameSpriteFrame initialSprite,
    required bool initialIsFake,
    required this.visualVariant,
    this.preserveSpriteAspectRatio = false,
    this.useSourceAspectGeometry = false,
    this.breatheIdle = false,
    this.ghostIdle = false,
    this.baseSpriteOpacity = 1,
    this.drawHealthBarSeparately = false,
    this.fakeSpriteOpacity = 0.35,
    this.turnIntervalOffset = 0,
    double? initialTurnCooldown,
  })  : _sprite = initialSprite.image,
        _visualHp = rule.maxHp,
        turnCooldown = initialTurnCooldown ?? rule.initialTurnCooldown,
        _sourceRect = Rect.fromLTWH(
          0,
          0,
          initialSprite.image.width.toDouble(),
          initialSprite.image.height.toDouble(),
        ),
        _destinationRect = useSourceAspectGeometry
            ? sourceAspectDestinationRect(initialSprite.image, initialSize)
            : Rect.fromLTWH(0, 0, initialSize, initialSize + 32),
        super(
          position: position,
          size: useSourceAspectGeometry
              ? sourceAspectComponentSize(
                  initialSprite.image,
                  initialSize,
                  trailingHeight: healthBarAreaHeight,
                )
              : Vector2(initialSize, initialSize + healthBarAreaHeight),
          priority: 100,
        ) {
    _spritePaint.color = Color.fromRGBO(
      255,
      255,
      255,
      baseSpriteOpacity * (initialIsFake ? fakeSpriteOpacity : 1),
    );
    _spritePaint.colorFilter = initialSprite.colorFilter;
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
  final int visualVariant;
  final double turnIntervalOffset;
  final bool preserveSpriteAspectRatio;
  final bool useSourceAspectGeometry;
  final bool breatheIdle;
  final bool ghostIdle;
  final double baseSpriteOpacity;
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
  static final List<double> _sinLookup = List<double>.generate(
    256,
    (index) => math.sin(index * math.pi * 2 / 256),
    growable: false,
  );
  static final List<double> _cosLookup = List<double>.generate(
    256,
    (index) => math.cos(index * math.pi * 2 / 256),
    growable: false,
  );
  static const double healthBarAreaHeight = 32;

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
  Rect get destinationRect => _destinationRect;
  double get spriteAspectRatio => _sprite.width / _sprite.height;
  double get currentVisualScale =>
      breatheIdle ? _breatheScale[_visualPhaseIndex] : 1;
  Offset get visualCenterInParent => Offset(
        position.x + _destinationRect.center.dx,
        position.y + _destinationRect.center.dy,
      );
  Rect get visualBoundsInParent {
    final local = useSourceAspectGeometry
        ? Rect.fromCenter(
            center: _destinationRect.center,
            width: _destinationRect.width * currentVisualScale,
            height: _destinationRect.height * currentVisualScale,
          )
        : _destinationRect;
    return local.shift(Offset(position.x, position.y));
  }

  int get _visualPhaseIndex =>
      ((_visualPhase / (math.pi * 2) * 256).floor()) & 255;

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
    final maxY = math.max(
      0.0,
      bounds.y - (useSourceAspectGeometry ? size.y : diameter + 26),
    );
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
    final frame = spriteResolver(
      color,
      hp,
      fake: isFake,
      visualVariant: visualVariant,
    );
    _sprite = frame.image;
    _spritePaint.colorFilter = frame.colorFilter;
    final nextDiameter = rule.sizeForHp(initialSize, hp);
    if (useSourceAspectGeometry) {
      size.setFrom(sourceAspectComponentSize(
        _sprite,
        nextDiameter,
        trailingHeight: healthBarAreaHeight,
      ));
    } else {
      size.setValues(nextDiameter, nextDiameter + healthBarAreaHeight);
    }
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
    final frame = spriteResolver(
      color,
      currentHp,
      fake: isFake,
      visualVariant: visualVariant,
    );
    _sprite = frame.image;
    _spritePaint.colorFilter = frame.colorFilter;
    _sourceRect = Rect.fromLTWH(
      0,
      0,
      _sprite.width.toDouble(),
      _sprite.height.toDouble(),
    );
    _spritePaint.color = Color.fromRGBO(
      255,
      255,
      255,
      baseSpriteOpacity * (isFake ? fakeSpriteOpacity : 1),
    );
  }

  void _refreshDestinationRect() {
    if (useSourceAspectGeometry) {
      _destinationRect = sourceAspectDestinationRect(_sprite, size.x);
      return;
    }
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
      _destinationRect.bottom + 8,
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
    final index = _visualPhaseIndex;
    final scale = breatheIdle ? _breatheScale[index] : 1.0;
    final offset = ghostIdle
        ? Offset(_sinLookup[index] * 1.4, _cosLookup[index] * 2.2)
        : Offset.zero;
    final rotation =
        ghostIdle ? _sinLookup[(index * 7 ~/ 10) & 255] * 0.018 : 0.0;
    if (scale != 1 || offset != Offset.zero || rotation != 0) {
      final pivot = useSourceAspectGeometry
          ? _destinationRect.center
          : Offset(size.x / 2, size.x / 2);
      canvas
        ..save()
        ..translate(pivot.dx + offset.dx, pivot.dy + offset.dy)
        ..rotate(rotation)
        ..scale(scale, scale)
        ..translate(-pivot.dx, -pivot.dy)
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
    if (useSourceAspectGeometry) {
      final hitBounds = Rect.fromCenter(
        center: _destinationRect.center,
        width: _destinationRect.width * currentVisualScale,
        height: _destinationRect.height * currentVisualScale,
      );
      return point.x > hitBounds.left &&
          point.x < hitBounds.right &&
          point.y > hitBounds.top &&
          point.y < hitBounds.bottom;
    }
    if (!preserveSpriteAspectRatio) return super.containsLocalPoint(point);
    final hitBounds = (breatheIdle || ghostIdle)
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
