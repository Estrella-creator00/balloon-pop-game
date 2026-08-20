import 'package:flutter/foundation.dart';

enum StageSuccessCondition { allBalloonsPopped }

enum StageFailureCondition { timeExpired }

enum StageCompletion { nextStage, gameClear }

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
class FlameStageDefinition {
  const FlameStageDefinition({
    required this.stage,
    required this.timeLimitSeconds,
    required this.balloonCount,
    required this.speedRange,
    required this.sizeScaleRange,
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
  final DoubleRange sizeScaleRange;
  final StageSuccessCondition successCondition;
  final StageFailureCondition failureCondition;
  final StageCompletion completion;
}

const flamePreviewStages = <FlameStageDefinition>[
  FlameStageDefinition(
    stage: 1,
    timeLimitSeconds: 15,
    balloonCount: 2,
    speedRange: DoubleRange(84, 94),
    sizeScaleRange: DoubleRange(1, 1),
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.nextStage,
  ),
  FlameStageDefinition(
    stage: 2,
    timeLimitSeconds: 18,
    balloonCount: 3,
    speedRange: DoubleRange(88, 100),
    sizeScaleRange: DoubleRange(0.94, 1.04),
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.nextStage,
  ),
  FlameStageDefinition(
    stage: 3,
    timeLimitSeconds: 20,
    balloonCount: 4,
    speedRange: DoubleRange(92, 106),
    sizeScaleRange: DoubleRange(0.90, 1.06),
    successCondition: StageSuccessCondition.allBalloonsPopped,
    failureCondition: StageFailureCondition.timeExpired,
    completion: StageCompletion.gameClear,
  ),
];

FlameStageDefinition flamePreviewStage(int stage) =>
    flamePreviewStages.singleWhere((definition) => definition.stage == stage);
