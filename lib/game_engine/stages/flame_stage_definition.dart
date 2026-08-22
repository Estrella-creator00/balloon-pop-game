import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

enum FlameStageType { normal, multiHit, fake, boss, stage30Boss }

enum StageSuccessCondition { allTargetsPopped, allBossesDefeated }

enum StageFailureCondition { timeExpired }

enum StageCompletion { nextStage, coreClear }

@immutable
class DoubleRange {
  const DoubleRange(this.minimum, this.maximum)
      : assert(minimum > 0),
        assert(maximum >= minimum);
  final double minimum;
  final double maximum;
  double valueAt(double factor) => minimum + (maximum - minimum) * factor;
}

@immutable
class StageScoreRule {
  const StageScoreRule(
      {required this.pointsPerBalloon,
      required this.remainingSecondMultiplier});
  final int pointsPerBalloon;
  final int remainingSecondMultiplier;
  int clearBonus(int secondsLeft) => secondsLeft * remainingSecondMultiplier;
}

@immutable
class FlameBalloonRule {
  const FlameBalloonRule({
    required this.requiredHits,
    required this.fakeCount,
    required this.fakePenaltySeconds,
    required this.firstHitSizeMultiplier,
  });
  final int requiredHits;
  final int fakeCount;
  final int fakePenaltySeconds;
  final double firstHitSizeMultiplier;
}

@immutable
class FlameBossRule {
  const FlameBossRule({
    required this.bossCount,
    required this.maxHp,
    required this.initialSpeed,
    required this.minimumSize,
    required this.maximumSize,
    required this.playfieldSizeFactor,
    required this.hitSizeMultiplier,
    required this.hitSpeedMultiplier,
    required this.initialTurnCooldown,
    required this.minimumTurnCooldown,
    required this.turnCooldownBase,
    required this.turnCooldownHpFactor,
    required this.hitTurnCooldownBase,
    required this.hitTurnCooldownHpFactor,
    required this.defeatPoints,
    required this.remainingSecondMultiplier,
    required this.fakeBossCount,
    this.sharedHp = false,
    this.swapChance = 0,
    this.maximumSpeed,
  });
  final int bossCount;
  final int maxHp;
  final double initialSpeed;
  final double minimumSize;
  final double maximumSize;
  final double playfieldSizeFactor;
  final double hitSizeMultiplier;
  final double hitSpeedMultiplier;
  final double initialTurnCooldown;
  final double minimumTurnCooldown;
  final double turnCooldownBase;
  final double turnCooldownHpFactor;
  final double hitTurnCooldownBase;
  final double hitTurnCooldownHpFactor;
  final int defeatPoints;
  final int remainingSecondMultiplier;
  final int fakeBossCount;
  final bool sharedHp;
  final double swapChance;
  final double? maximumSpeed;

  double initialSizeFor(double shortestSide) => math
      .min(shortestSide * playfieldSizeFactor, maximumSize)
      .clamp(minimumSize, maximumSize)
      .toDouble();
  double sizeForHp(double initialSize, int hp) =>
      initialSize * math.pow(hitSizeMultiplier, maxHp - hp);
  double speedForHp(int hp) {
    final value = initialSpeed * math.pow(hitSpeedMultiplier, maxHp - hp);
    return maximumSpeed == null ? value : math.min(value, maximumSpeed!);
  }

  double get peakSpeed => speedForHp(1);
  double turnCooldownForHp(int hp, {double offset = 0}) => math.max(
      minimumTurnCooldown,
      turnCooldownBase + (hp / maxHp) * turnCooldownHpFactor + offset);
  double hitTurnCooldownForHp(int hp, {double offset = 0}) => math.max(
      sharedHp ? 0.10 : minimumTurnCooldown,
      hitTurnCooldownBase + (hp / maxHp) * hitTurnCooldownHpFactor + offset);
  Color colorForHp(int hp) => Color.lerp(
      const Color(0xFF7E57C2), const Color(0xFFFF3D67), (maxHp - hp) / maxHp)!;
}

@immutable
class FlameStageDefinition {
  const FlameStageDefinition({
    required this.stage,
    required this.type,
    required this.timeLimitSeconds,
    required this.balloonCount,
    required this.speedRange,
    required this.sizeRange,
    required this.scoreRule,
    required this.successCondition,
    required this.failureCondition,
    required this.completion,
    required this.balloonRule,
    this.bossRule,
  });
  final int stage;
  final FlameStageType type;
  final int timeLimitSeconds;
  final int balloonCount;
  final DoubleRange speedRange;
  final DoubleRange sizeRange;
  final StageScoreRule scoreRule;
  final StageSuccessCondition successCondition;
  final StageFailureCondition failureCondition;
  final StageCompletion completion;
  final FlameBalloonRule balloonRule;
  final FlameBossRule? bossRule;
  bool get isBoss => bossRule != null;
  bool get isStage30 => type == FlameStageType.stage30Boss;
}

const productionNormalScoreRule =
    StageScoreRule(pointsPerBalloon: 0, remainingSecondMultiplier: 1);
const productionNormalSizeRange = DoubleRange(78, 102);
const productionFakePenaltySeconds = 2;
const stage10BossRule = FlameBossRule(
  bossCount: 1,
  maxHp: 10,
  initialSpeed: 105,
  minimumSize: 210,
  maximumSize: 270,
  playfieldSizeFactor: 0.62,
  hitSizeMultiplier: 0.965,
  hitSpeedMultiplier: 1.075,
  initialTurnCooldown: 0.65,
  minimumTurnCooldown: 0.12,
  turnCooldownBase: 0.24,
  turnCooldownHpFactor: 0.38,
  hitTurnCooldownBase: 0.18,
  hitTurnCooldownHpFactor: 0.28,
  defeatPoints: 10,
  remainingSecondMultiplier: 1,
  fakeBossCount: 0,
);
const stage20BossRule = FlameBossRule(
  bossCount: 2,
  maxHp: 15,
  initialSpeed: 126,
  minimumSize: 225,
  maximumSize: 300,
  playfieldSizeFactor: 0.62,
  hitSizeMultiplier: 0.965,
  hitSpeedMultiplier: 1.075,
  initialTurnCooldown: 0.65,
  minimumTurnCooldown: 0.12,
  turnCooldownBase: 0.24,
  turnCooldownHpFactor: 0.38,
  hitTurnCooldownBase: 0.18,
  hitTurnCooldownHpFactor: 0.28,
  defeatPoints: 10,
  remainingSecondMultiplier: 1,
  fakeBossCount: 0,
);
const stage30BossRule = FlameBossRule(
  bossCount: 2,
  maxHp: 12,
  initialSpeed: 126,
  minimumSize: 225,
  maximumSize: 300,
  playfieldSizeFactor: 0.62,
  hitSizeMultiplier: 0.965,
  hitSpeedMultiplier: 1.075,
  initialTurnCooldown: 0.52,
  minimumTurnCooldown: 0.12,
  turnCooldownBase: 0.24,
  turnCooldownHpFactor: 0.38,
  hitTurnCooldownBase: 0.18,
  hitTurnCooldownHpFactor: 0.28,
  defeatPoints: 10,
  remainingSecondMultiplier: 1,
  fakeBossCount: 1,
  sharedHp: true,
  swapChance: 0.50,
  maximumSpeed: 220,
);

FlameStageDefinition _productionStage(int stage) {
  final isBoss = stage % 10 == 0;
  final tier = (stage - 1) ~/ 10;
  final position = (stage - 1) % 10 + 1;
  final timeGroup = (position - 1) ~/ 3;
  final requiredHits = isBoss
      ? tier + 1
      : stage >= 11 && stage <= 19
          ? 2
          : 1;
  final fakeCount = stage >= 21 && stage <= 29 ? 2 : 0;
  final bossRule = switch (stage) {
    10 => stage10BossRule,
    20 => stage20BossRule,
    30 => stage30BossRule,
    _ => null,
  };
  return FlameStageDefinition(
    stage: stage,
    type: stage == 30
        ? FlameStageType.stage30Boss
        : isBoss
            ? FlameStageType.boss
            : requiredHits == 2
                ? FlameStageType.multiHit
                : fakeCount > 0
                    ? FlameStageType.fake
                    : FlameStageType.normal,
    timeLimitSeconds: stage == 30
        ? 18
        : isBoss
            ? 8 + tier * 2
            : 10 + tier * 2 + timeGroup * 5,
    balloonCount: isBoss ? 0 : position + 1,
    speedRange: isBoss
        ? DoubleRange(bossRule!.initialSpeed, bossRule.peakSpeed)
        : DoubleRange(48 + stage * 4.2, 80 + stage * 4.2),
    sizeRange: isBoss
        ? DoubleRange(bossRule!.minimumSize, bossRule.maximumSize)
        : productionNormalSizeRange,
    scoreRule: productionNormalScoreRule,
    successCondition: isBoss
        ? StageSuccessCondition.allBossesDefeated
        : StageSuccessCondition.allTargetsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion:
        stage == 30 ? StageCompletion.coreClear : StageCompletion.nextStage,
    balloonRule: FlameBalloonRule(
      requiredHits: requiredHits,
      fakeCount: fakeCount,
      fakePenaltySeconds: productionFakePenaltySeconds,
      firstHitSizeMultiplier: 0.88,
    ),
    bossRule: bossRule,
  );
}

final List<FlameStageDefinition> flamePreviewStages =
    List<FlameStageDefinition>.unmodifiable(
        List.generate(30, (index) => _productionStage(index + 1)));

FlameStageDefinition flamePreviewStage(int stage) =>
    flamePreviewStages.singleWhere((definition) => definition.stage == stage);
