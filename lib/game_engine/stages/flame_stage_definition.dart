import 'package:flutter/foundation.dart';

enum StageSuccessCondition { allBalloonsPopped }

enum StageFailureCondition { timeExpired }

enum StageCompletion { nextStage, normalClear }

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
  })  : assert(stage > 0),
        assert(timeLimitSeconds > 0),
        assert(balloonCount > 0);

  final int stage;
  final int timeLimitSeconds;
  final int balloonCount;
  final DoubleRange speedRange;
  final DoubleRange sizeRange;
  final StageScoreRule scoreRule;
  final StageSuccessCondition successCondition;
  final StageFailureCondition failureCondition;
  final StageCompletion completion;
}

const _productionNormalScoreRule = StageScoreRule(
  pointsPerBalloon: 0,
  remainingSecondMultiplier: 1,
);
const _productionNormalSizeRange = DoubleRange(78, 102);

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
    completion: StageCompletion.normalClear,
  ),
];

FlameStageDefinition flamePreviewStage(int stage) =>
    flamePreviewStages.singleWhere((definition) => definition.stage == stage);
