import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

enum FlameStageType { normal, boss }

enum StageSuccessCondition { allBalloonsPopped, allBossesDefeated }

enum StageFailureCondition { timeExpired }

enum StageCompletion { nextStage, sectionClear }

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
  const StageScoreRule({
    required this.pointsPerBalloon,
    required this.remainingSecondMultiplier,
  })  : assert(pointsPerBalloon >= 0),
        assert(remainingSecondMultiplier >= 0);

  final int pointsPerBalloon;
  final int remainingSecondMultiplier;

  int clearBonus(int secondsLeft) => secondsLeft * remainingSecondMultiplier;
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

  double initialSizeFor(double playfieldShortestSide) => math
      .min(playfieldShortestSide * playfieldSizeFactor, maximumSize)
      .clamp(minimumSize, maximumSize)
      .toDouble();

  double sizeForHp(double initialSize, int hp) =>
      initialSize * math.pow(hitSizeMultiplier, maxHp - hp);

  double speedForHp(int hp) =>
      initialSpeed * math.pow(hitSpeedMultiplier, maxHp - hp);

  double get maximumSpeed => speedForHp(1);

  double turnCooldownForHp(int hp) => math.max(
        minimumTurnCooldown,
        turnCooldownBase + (hp / maxHp) * turnCooldownHpFactor,
      );

  double hitTurnCooldownForHp(int hp) =>
      hitTurnCooldownBase + (hp / maxHp) * hitTurnCooldownHpFactor;

  Color colorForHp(int hp) => Color.lerp(
        const Color(0xFF7E57C2),
        const Color(0xFFFF3D67),
        (maxHp - hp) / maxHp,
      )!;
}

@immutable
class FlameStageDefinition {
  const FlameStageDefinition({
    required this.stage,
    required this.timeLimitSeconds,
    required this.balloonCount,
    required this.speedRange,
    required this.sizeRange,
    required this.scoreRule,
    required this.successCondition,
    required this.failureCondition,
    required this.completion,
    this.bossRule,
  })  : assert(stage > 0),
        assert(timeLimitSeconds > 0),
        assert(balloonCount >= 0),
        assert(
          (bossRule == null && balloonCount > 0) ||
              (bossRule != null && balloonCount == 0),
        );

  final int stage;
  final int timeLimitSeconds;
  final int balloonCount;
  final DoubleRange speedRange;
  final DoubleRange sizeRange;
  final StageScoreRule scoreRule;
  final StageSuccessCondition successCondition;
  final StageFailureCondition failureCondition;
  final StageCompletion completion;
  final FlameBossRule? bossRule;

  FlameStageType get type =>
      bossRule == null ? FlameStageType.normal : FlameStageType.boss;
  bool get isBoss => bossRule != null;
}

const _productionNormalScoreRule = StageScoreRule(
  pointsPerBalloon: 0,
  remainingSecondMultiplier: 1,
);
const _productionNormalSizeRange = DoubleRange(78, 102);
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

// Mirrors StageConfig.forStage and _spawnBalloonGroup for production Stages
// 1-9. The upper speed and size bounds are exclusive because Random.nextDouble
// never returns 1.
const flamePreviewStages = <FlameStageDefinition>[
  FlameStageDefinition(
    stage: 1,
    timeLimitSeconds: 10,
    balloonCount: 2,
    speedRange: DoubleRange(52.2, 84.2),
    sizeRange: _productionNormalSizeRange,
    scoreRule: _productionNormalScoreRule,
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.nextStage,
  ),
  FlameStageDefinition(
    stage: 2,
    timeLimitSeconds: 10,
    balloonCount: 3,
    speedRange: DoubleRange(56.4, 88.4),
    sizeRange: _productionNormalSizeRange,
    scoreRule: _productionNormalScoreRule,
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.nextStage,
  ),
  FlameStageDefinition(
    stage: 3,
    timeLimitSeconds: 10,
    balloonCount: 4,
    speedRange: DoubleRange(60.6, 92.6),
    sizeRange: _productionNormalSizeRange,
    scoreRule: _productionNormalScoreRule,
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.nextStage,
  ),
  FlameStageDefinition(
    stage: 4,
    timeLimitSeconds: 15,
    balloonCount: 5,
    speedRange: DoubleRange(64.8, 96.8),
    sizeRange: _productionNormalSizeRange,
    scoreRule: _productionNormalScoreRule,
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.nextStage,
  ),
  FlameStageDefinition(
    stage: 5,
    timeLimitSeconds: 15,
    balloonCount: 6,
    speedRange: DoubleRange(69, 101),
    sizeRange: _productionNormalSizeRange,
    scoreRule: _productionNormalScoreRule,
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.nextStage,
  ),
  FlameStageDefinition(
    stage: 6,
    timeLimitSeconds: 15,
    balloonCount: 7,
    speedRange: DoubleRange(73.2, 105.2),
    sizeRange: _productionNormalSizeRange,
    scoreRule: _productionNormalScoreRule,
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.nextStage,
  ),
  FlameStageDefinition(
    stage: 7,
    timeLimitSeconds: 20,
    balloonCount: 8,
    speedRange: DoubleRange(77.4, 109.4),
    sizeRange: _productionNormalSizeRange,
    scoreRule: _productionNormalScoreRule,
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.nextStage,
  ),
  FlameStageDefinition(
    stage: 8,
    timeLimitSeconds: 20,
    balloonCount: 9,
    speedRange: DoubleRange(81.6, 113.6),
    sizeRange: _productionNormalSizeRange,
    scoreRule: _productionNormalScoreRule,
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.nextStage,
  ),
  FlameStageDefinition(
    stage: 9,
    timeLimitSeconds: 20,
    balloonCount: 10,
    speedRange: DoubleRange(85.8, 117.8),
    sizeRange: _productionNormalSizeRange,
    scoreRule: _productionNormalScoreRule,
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.nextStage,
  ),
  FlameStageDefinition(
    stage: 10,
    timeLimitSeconds: 8,
    balloonCount: 0,
    speedRange: DoubleRange(105, 201.310059560274),
    sizeRange: DoubleRange(210, 270),
    scoreRule: _productionNormalScoreRule,
    successCondition: StageSuccessCondition.allBossesDefeated,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.sectionClear,
    bossRule: stage10BossRule,
  ),
];

FlameStageDefinition flamePreviewStage(int stage) =>
    flamePreviewStages.singleWhere((definition) => definition.stage == stage);
