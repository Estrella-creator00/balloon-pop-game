import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../rendering/flame_sprite_frame.dart';

typedef BalloonHitRequest = bool Function(BalloonComponent balloon);
typedef BalloonSpriteResolver = FlameSpriteFrame Function(
  Color color,
  int hp,
  int maxHp,
  bool isFake,
  int visualVariant,
);
typedef BalloonExitFinished = void Function(BalloonComponent balloon);

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
    required FlameSpriteFrame sprite,
    required this.spriteResolver,
    required this.visualVariant,
    required this.floatPhase,
    required this.floatPower,
    required this.firstHitSizeMultiplier,
    this.preserveSpriteAspectRatio = false,
    this.useSourceAspectGeometry = false,
    this.breatheIdle = false,
    this.ghostIdle = false,
    this.baseSpriteOpacity = 1,
    double? spriteOpacity,
  })  : _sprite = sprite.image,
        _visualHp = maxHp,
        _normalizedVisibleBounds = sprite.normalizedVisibleBounds,
        _sourceRect = Rect.fromLTWH(0, 0, sprite.image.width.toDouble(),
            sprite.image.height.toDouble()),
        _destinationRect = useSourceAspectGeometry
            ? sourceAspectDestinationRect(sprite.image, balloonSize.x)
            : Rect.fromLTWH(0, 0, balloonSize.x, balloonSize.y),
        _visibleBodyRect = useSourceAspectGeometry
            ? sourceAspectVisibleBodyRect(sprite, balloonSize.x)
            : Rect.fromLTWH(0, 0, balloonSize.x, balloonSize.y),
        super(position: position, size: balloonSize, priority: balloonId) {
    final opacity = (spriteOpacity ?? (isFake ? 0.35 : 1)) * baseSpriteOpacity;
    _spritePaint.color = Color.fromRGBO(255, 255, 255, opacity);
    _spritePaint.colorFilter = sprite.colorFilter;
    _refreshDestinationRect();
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
  final int visualVariant;
  final double floatPower;
  final double firstHitSizeMultiplier;
  final bool preserveSpriteAspectRatio;
  final bool useSourceAspectGeometry;
  final bool breatheIdle;
  final bool ghostIdle;
  final double baseSpriteOpacity;
  final Paint _spritePaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.medium;

  Image _sprite;
  Rect _normalizedVisibleBounds;
  Rect _sourceRect;
  Rect _destinationRect;
  Rect _visibleBodyRect;
  int _visualHp;
  bool _hitInProgress = false;
  bool _removed = false;
  bool _exiting = false;
  double _exitElapsed = 0;
  Vector2 _exitVelocity = Vector2.zero();
  BalloonExitFinished? _onExitFinished;
  double floatPhase;
  double _lastAppliedDelta = 0;

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

  int get currentHp => readHp(balloonId);
  int get visualHp => _visualHp;
  bool get isRemovedFromGame => _removed;
  bool get isPopRequested => _removed;
  bool get isExiting => _exiting;
  double get lastAppliedDelta => _lastAppliedDelta;
  Rect get playfieldBounds =>
      Rect.fromLTWH(position.x, position.y, size.x, size.y);
  Rect get destinationRect => _destinationRect;
  Rect get bodyRect => _visibleBodyRect;
  double get spriteAspectRatio => _sprite.width / _sprite.height;
  double get currentVisualScale =>
      breatheIdle ? _breatheScale[_visualPhaseIndex] : 1;
  Offset get visualCenterInParent => Offset(
        position.x + _visibleBodyRect.center.dx,
        position.y + _visibleBodyRect.center.dy,
      );
  Rect get visualBoundsInParent {
    final local = useSourceAspectGeometry
        ? Rect.fromCenter(
            center: _visibleBodyRect.center,
            width: _visibleBodyRect.width * currentVisualScale,
            height: _visibleBodyRect.height * currentVisualScale,
          )
        : _destinationRect;
    return local.shift(Offset(position.x, position.y));
  }

  int get _visualPhaseIndex =>
      ((floatPhase / (math.pi * 2) * 256).floor()) & 255;

  @override
  void update(double dt) {
    super.update(dt);
    if (_removed) return;
    final clamped = dt.clamp(0.0, maxUpdateDelta).toDouble();
    _lastAppliedDelta = clamped;
    if (_exiting) {
      _exitElapsed += clamped;
      position.addScaled(_exitVelocity, clamped);
      if (_exitElapsed >= 0.24) {
        _exiting = false;
        final finished = _onExitFinished;
        _onExitFinished = null;
        finished?.call(this);
      }
      return;
    }
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
    final frame = spriteResolver(color, hp, maxHp, isFake, visualVariant);
    _sprite = frame.image;
    _normalizedVisibleBounds = frame.normalizedVisibleBounds;
    _spritePaint.colorFilter = frame.colorFilter;
    final width = size.x * firstHitSizeMultiplier;
    if (useSourceAspectGeometry) {
      size.setFrom(sourceAspectComponentSize(_sprite, width));
    } else {
      size.setValues(width, width + stringHeight);
    }
    _sourceRect = Rect.fromLTWH(
        0, 0, _sprite.width.toDouble(), _sprite.height.toDouble());
    _refreshDestinationRect();
    _reflectInsidePlayfield();
  }

  void _refreshDestinationRect() {
    if (useSourceAspectGeometry) {
      _destinationRect = sourceAspectDestinationRect(_sprite, size.x);
      _visibleBodyRect = sourceAspectVisibleBodyRect(
        FlameSpriteFrame(
          _sprite,
          normalizedVisibleBounds: _normalizedVisibleBounds,
        ),
        size.x,
      );
      return;
    }
    if (!preserveSpriteAspectRatio) {
      _destinationRect = Rect.fromLTWH(0, 0, size.x, size.y);
      _visibleBodyRect = _destinationRect;
      return;
    }
    final sourceAspect = _sprite.width / _sprite.height;
    final targetAspect = size.x / size.y;
    final width = sourceAspect > targetAspect ? size.x : size.y * sourceAspect;
    final height = sourceAspect > targetAspect ? size.x / sourceAspect : size.y;
    _destinationRect = Rect.fromLTWH(
      (size.x - width) / 2,
      (size.y - height) / 2,
      width,
      height,
    );
    _visibleBodyRect = _destinationRect;
  }

  void markRemoved() {
    _removed = true;
    _exiting = false;
    _onExitFinished = null;
  }

  bool beginKickExit({
    required Vector2 velocity,
    required BalloonExitFinished onFinished,
  }) {
    if (_removed || _exiting) return false;
    _exiting = true;
    _exitElapsed = 0;
    _exitVelocity = velocity;
    _onExitFinished = onFinished;
    return true;
  }

  @override
  void render(Canvas canvas) {
    final phaseIndex = _visualPhaseIndex;
    var scale = breatheIdle ? _breatheScale[phaseIndex] : 1.0;
    var offset = Offset.zero;
    var rotation = 0.0;
    if (ghostIdle) {
      offset =
          Offset(_sinLookup[phaseIndex] * 1.4, _cosLookup[phaseIndex] * 2.2);
      rotation = _sinLookup[(phaseIndex * 7 ~/ 10) & 255] * 0.018;
    }
    if (_exiting) {
      scale *= (1 - (_exitElapsed / 0.24) * 0.42).clamp(0.58, 1.0);
    }
    if (scale == 1 && offset == Offset.zero && rotation == 0) {
      canvas.drawImageRect(
          _sprite, _sourceRect, _destinationRect, _spritePaint);
      return;
    }
    final pivot = useSourceAspectGeometry
        ? _visibleBodyRect.center
        : Offset(size.x / 2, size.y / 2);
    canvas
      ..save()
      ..translate(pivot.dx + offset.dx, pivot.dy + offset.dy)
      ..rotate(rotation)
      ..scale(scale, scale)
      ..translate(-pivot.dx, -pivot.dy)
      ..drawImageRect(_sprite, _sourceRect, _destinationRect, _spritePaint)
      ..restore();
  }

  @override
  void onTapDown(TapDownEvent event) => requestHit();

  @override
  bool containsLocalPoint(Vector2 point) {
    if (_exiting) return false;
    if (useSourceAspectGeometry) {
      final hitBounds = Rect.fromCenter(
        center: _visibleBodyRect.center,
        width: _visibleBodyRect.width * currentVisualScale,
        height: _visibleBodyRect.height * currentVisualScale,
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

  bool requestHit() {
    if (_removed || _exiting || _hitInProgress) return false;
    _hitInProgress = true;
    final accepted = onHitRequested(this);
    _hitInProgress = false;
    return accepted;
  }

  bool requestPop() => requestHit();
}
