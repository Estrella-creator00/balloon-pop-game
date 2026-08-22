import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../components/boss_balloon_component.dart';
import 'flame_stage_definition.dart';

class StageBossSpawner {
  const StageBossSpawner({this.seed = 10107});

  final int seed;

  List<BossBalloonComponent> create({
    required FlameStageDefinition definition,
    required int generation,
    required int idBase,
    required Vector2 Function() playfieldSize,
    required int Function(int bossId) readHp,
    required bool Function(int bossId) readIsFake,
    required BossHitRequest onHitRequested,
    required BossSpriteResolver spriteForHp,
    List<Color>? palette,
    bool preserveSpriteAspectRatio = false,
    bool breatheIdle = false,
    bool ghostIdle = false,
    double baseSpriteOpacity = 1,
    bool drawHealthBarSeparately = false,
    double fakeSpriteOpacity = 0.35,
    int visualVariantCount = 1,
  }) {
    final rule = definition.bossRule;
    if (rule == null) return const <BossBalloonComponent>[];

    final random = math.Random(seed + definition.stage * 997);
    final activePalette = palette ?? const <Color>[Color(0xFF7E57C2)];
    final bounds = playfieldSize();
    final initialSize = rule.initialSizeFor(math.min(bounds.x, bounds.y));
    final bosses = <BossBalloonComponent>[];
    final occupied = <Rect>[];
    double? previousAngle;
    for (var index = 0; index < rule.bossCount; index++) {
      final initialIsFake = rule.sharedHp && index != 0;
      final color = activePalette[random.nextInt(activePalette.length)];
      final visualVariant = visualVariantCount <= 1
          ? 0
          : (random.nextDouble() * visualVariantCount).floor();
      final maxX = math.max(0.0, bounds.x - initialSize);
      final maxY = math.max(0.0, bounds.y - initialSize - 26);
      var angle = random.nextDouble() * math.pi * 2;
      if (rule.sharedHp && previousAngle != null) {
        final difference = math
            .atan2(
              math.sin(angle - previousAngle),
              math.cos(angle - previousAngle),
            )
            .abs();
        if (difference < math.pi / 3) {
          angle = (angle + math.pi / 2) % (math.pi * 2);
        }
      }
      previousAngle = angle;
      var position =
          Vector2(random.nextDouble() * maxX, random.nextDouble() * maxY);
      for (var attempt = 0; attempt < 80; attempt++) {
        final rect =
            Rect.fromLTWH(position.x, position.y, initialSize, initialSize);
        if (occupied.every((other) => !other.inflate(12).overlaps(rect))) break;
        position =
            Vector2(random.nextDouble() * maxX, random.nextDouble() * maxY);
      }
      occupied
          .add(Rect.fromLTWH(position.x, position.y, initialSize, initialSize));
      bosses.add(
        BossBalloonComponent(
          bossId: idBase + index,
          generation: generation,
          position: position,
          velocity: Vector2(
            math.cos(angle) * rule.initialSpeed,
            math.sin(angle) * rule.initialSpeed,
          ),
          playfieldSize: playfieldSize,
          rule: rule,
          initialSize: initialSize,
          color: color,
          readHp: readHp,
          readIsFake: readIsFake,
          onHitRequested: onHitRequested,
          directionRoll: random.nextDouble,
          spriteResolver: spriteForHp,
          initialSprite: spriteForHp(
            color,
            rule.maxHp,
            fake: initialIsFake,
            visualVariant: visualVariant,
          ),
          initialIsFake: initialIsFake,
          visualVariant: visualVariant,
          preserveSpriteAspectRatio: preserveSpriteAspectRatio,
          breatheIdle: breatheIdle,
          ghostIdle: ghostIdle,
          baseSpriteOpacity: baseSpriteOpacity,
          drawHealthBarSeparately: drawHealthBarSeparately,
          fakeSpriteOpacity: fakeSpriteOpacity,
          turnIntervalOffset: rule.sharedHp ? (index == 0 ? -0.055 : 0.055) : 0,
          initialTurnCooldown: rule.sharedHp
              ? 0.52 + index * 0.17 + random.nextDouble() * 0.08
              : rule.initialTurnCooldown,
        ),
      );
    }
    return bosses;
  }
}
