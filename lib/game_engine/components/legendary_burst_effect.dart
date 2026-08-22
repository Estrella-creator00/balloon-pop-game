import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../legendary/flame_preview_skin.dart';
import '../legendary/legendary_skin_definition.dart';
import '../legendary/legendary_sprite_cache.dart';

enum LegendaryHitKind { firstHit, finalPop, bossPop }

class LegendaryParticle {
  LegendaryParticle({
    required this.image,
    required this.position,
    required this.velocity,
    required this.size,
    required this.rotation,
    required this.spin,
    required this.life,
  })  : maxLife = life,
        source = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        destination = _destinationFor(image, size);

  static Rect _destinationFor(Image image, double size) {
    final aspect = image.width / image.height;
    final width = aspect >= 1 ? size : size * aspect;
    final height = aspect >= 1 ? size / aspect : size;
    return Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );
  }

  final Image image;
  final Rect source;
  final Rect destination;
  final Vector2 position;
  final Vector2 velocity;
  final double size;
  double rotation;
  final double spin;
  double life;
  final double maxLife;
}

class LegendaryBurstEffect extends Component {
  LegendaryBurstEffect({
    required List<LegendaryParticle> particles,
    required this.onFinished,
  })  : particles =
            particles.take(maxParticlesPerEffect).toList(growable: true),
        super(priority: 500);

  static const int maxParticlesPerEffect = 16;

  final List<LegendaryParticle> particles;
  final void Function(LegendaryBurstEffect effect) onFinished;
  final Paint _paint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.low;
  bool _finished = false;

  int get particleCount => particles.length;

  @override
  void update(double dt) {
    if (_finished) return;
    for (final particle in particles) {
      particle.life -= dt;
      particle.position.addScaled(particle.velocity, dt);
      particle.rotation += particle.spin * dt;
    }
    particles.removeWhere((particle) => particle.life <= 0);
    if (particles.isNotEmpty) return;
    _finished = true;
    onFinished(this);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final particle in particles) {
      final alpha = (particle.life / particle.maxLife).clamp(0.0, 1.0);
      _paint.color = Color.fromRGBO(255, 255, 255, alpha);
      canvas
        ..save()
        ..translate(particle.position.x, particle.position.y)
        ..rotate(particle.rotation)
        ..drawImageRect(
          particle.image,
          particle.source,
          particle.destination,
          _paint,
        )
        ..restore();
    }
  }
}

class LegendaryEffectFactory {
  LegendaryEffectFactory({required this.random});

  final math.Random random;

  LegendaryBurstEffect create({
    required LegendarySkinDefinition definition,
    required LegendarySpriteCache cache,
    required LegendaryHitKind kind,
    required Vector2 center,
    required double sourceSize,
    required Color color,
    required Vector2 playfieldSize,
    required void Function(LegendaryBurstEffect effect) onFinished,
  }) {
    final particles = <LegendaryParticle>[];
    _addTool(definition, cache, center, sourceSize, particles);
    if (definition.skin == FlamePreviewSkin.gemi) {
      _addGemi(
        definition,
        cache,
        kind,
        center,
        sourceSize,
        color,
        playfieldSize,
        particles,
      );
    } else {
      _addShushu(
        definition,
        cache,
        kind,
        center,
        sourceSize,
        playfieldSize,
        particles,
      );
    }
    return LegendaryBurstEffect(
      particles: particles,
      onFinished: onFinished,
    );
  }

  void _addTool(
    LegendarySkinDefinition definition,
    LegendarySpriteCache cache,
    Vector2 center,
    double sourceSize,
    List<LegendaryParticle> particles,
  ) {
    final isShushu = definition.skin == FlamePreviewSkin.shushu;
    particles.add(LegendaryParticle(
      image: cache.imageForAsset(definition.catalog.hitToolAssetPath!),
      position: center.clone()
        ..add(isShushu ? Vector2(0, -72) : Vector2(-56, -32)),
      velocity: isShushu ? Vector2(0, 300) : Vector2(230, 360),
      size: isShushu ? 100 : 116,
      rotation: isShushu ? -2.72 : -1.12,
      spin: isShushu ? 1.2 : 3.8,
      life: 0.24,
    ));
  }

  void _addGemi(
    LegendarySkinDefinition definition,
    LegendarySpriteCache cache,
    LegendaryHitKind kind,
    Vector2 center,
    double sourceSize,
    Color color,
    Vector2 playfieldSize,
    List<LegendaryParticle> particles,
  ) {
    final shardPath =
        definition.catalog.runtimeShardAssetPaths[color.toARGB32()] ??
            definition.catalog.runtimeShardAssetPaths.values.first;
    final count = switch (kind) {
      LegendaryHitKind.firstHit => 2,
      LegendaryHitKind.finalPop => 8,
      LegendaryHitKind.bossPop => 12,
    };
    final image = cache.imageForAsset(shardPath);
    for (var index = 0; index < count; index++) {
      final angle = math.pi * 2 * index / count + random.nextDouble() * 0.8;
      final speed = 75 + random.nextDouble() * 65;
      particles.add(LegendaryParticle(
        image: image,
        position: center.clone(),
        velocity:
            Vector2(math.cos(angle) * speed, math.sin(angle) * speed - 18),
        size: sourceSize * (0.20 + random.nextDouble() * 0.08),
        rotation: random.nextDouble() * math.pi * 2,
        spin: (random.nextDouble() - 0.5) * 5,
        life: 0.48,
      ));
    }
    if (kind != LegendaryHitKind.firstHit &&
        random.nextDouble() < definition.catalog.screenCrackChance) {
      particles.add(LegendaryParticle(
        image: cache.imageForAsset(definition.catalog.screenCrackAssetPath!),
        position: Vector2(
          playfieldSize.x * (0.18 + random.nextDouble() * 0.64),
          playfieldSize.y * (0.18 + random.nextDouble() * 0.58),
        ),
        velocity: Vector2.zero(),
        size: 110,
        rotation: (random.nextDouble() - 0.5) * 0.65,
        spin: 0,
        life: 0.72,
      ));
    }
  }

  void _addShushu(
    LegendarySkinDefinition definition,
    LegendarySpriteCache cache,
    LegendaryHitKind kind,
    Vector2 center,
    double sourceSize,
    Vector2 playfieldSize,
    List<LegendaryParticle> particles,
  ) {
    final burst = cache.imageForAsset(definition.catalog.burstAssetPath!);
    final count = switch (kind) {
      LegendaryHitKind.firstHit => 2,
      LegendaryHitKind.finalPop => 5,
      LegendaryHitKind.bossPop => 8,
    };
    for (var index = 0; index < count; index++) {
      final angle = math.pi * 2 * index / count + random.nextDouble() * 0.35;
      final speed = (kind == LegendaryHitKind.bossPop ? 115 : 72) +
          random.nextDouble() * 45;
      particles.add(LegendaryParticle(
        image: burst,
        position: center.clone(),
        velocity:
            Vector2(math.cos(angle) * speed, math.sin(angle) * speed - 25),
        size: sourceSize * (kind == LegendaryHitKind.bossPop ? 0.16 : 0.22) +
            random.nextDouble() * 18,
        rotation: random.nextDouble() * math.pi * 2,
        spin: (random.nextDouble() - 0.5) * 3,
        life: 0.52,
      ));
    }
    if (kind == LegendaryHitKind.firstHit) return;
    final wall = cache.imageForAsset(definition.catalog.wallSplatAssetPath!);
    for (var index = 0; index < 2; index++) {
      final left = index == 0;
      particles.add(LegendaryParticle(
        image: wall,
        position: Vector2(
          left ? 4 : playfieldSize.x - 4,
          45 + random.nextDouble() * math.max(1, playfieldSize.y - 90),
        ),
        velocity: Vector2.zero(),
        size: 48 + random.nextDouble() * 24,
        rotation: left ? 0 : math.pi,
        spin: 0,
        life: 1.15,
      ));
    }
    particles.add(LegendaryParticle(
      image: cache.imageForAsset(definition.catalog.screenSplatAssetPath!),
      position: Vector2(
        playfieldSize.x * (0.22 + random.nextDouble() * 0.56),
        playfieldSize.y * (0.20 + random.nextDouble() * 0.56),
      ),
      velocity: Vector2.zero(),
      size: 42 + random.nextDouble() * 18,
      rotation: random.nextDouble() * math.pi * 2,
      spin: 0,
      life: 0.92,
    ));
  }
}
