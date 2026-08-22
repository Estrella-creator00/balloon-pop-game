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
    required BossHitRequest onHitRequested,
    required Image Function(int hp) spriteForHp,
  }) {
    final rule = definition.bossRule;
    if (rule == null) return const <BossBalloonComponent>[];

    final random = math.Random(seed + definition.stage * 997);
    final bounds = playfieldSize();
    final initialSize = rule.initialSizeFor(math.min(bounds.x, bounds.y));
    final bosses = <BossBalloonComponent>[];
    for (var index = 0; index < rule.bossCount; index++) {
      final maxX = math.max(0.0, bounds.x - initialSize);
      final maxY = math.max(0.0, bounds.y - initialSize - 26);
      final angle = random.nextDouble() * math.pi * 2;
      bosses.add(
        BossBalloonComponent(
          bossId: idBase + index,
          generation: generation,
          position: Vector2(
            random.nextDouble() * maxX,
            random.nextDouble() * maxY,
          ),
          velocity: Vector2(
            math.cos(angle) * rule.initialSpeed,
            math.sin(angle) * rule.initialSpeed,
          ),
          playfieldSize: playfieldSize,
          rule: rule,
          initialSize: initialSize,
          readHp: readHp,
          onHitRequested: onHitRequested,
          directionRoll: random.nextDouble,
          initialSprite: spriteForHp(rule.maxHp),
        ),
      );
    }
    return bosses;
  }
}
