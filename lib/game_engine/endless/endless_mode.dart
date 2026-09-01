import '../stages/flame_stage_definition.dart';

class EndlessBalloonProfile {
  const EndlessBalloonProfile({
    required this.requiredHits,
    required this.isFake,
    required this.speed,
    required this.size,
  });

  final int requiredHits;
  final bool isFake;
  final double speed;
  final double size;
}

abstract final class EndlessModeRules {
  static const int activeBalloonLimit = 6;
  static const double maximumSpeed = 220;

  static EndlessBalloonProfile profileFor({
    required int record,
    required int spawnOrdinal,
  }) {
    final speed = (56 + record * 1.35 + (spawnOrdinal % 3) * 12)
        .clamp(56, maximumSpeed)
        .toDouble();
    final size = 78 + (spawnOrdinal % 4) * 8.0;
    return EndlessBalloonProfile(
      requiredHits: 1,
      isFake: false,
      speed: speed,
      size: size,
    );
  }
}

const endlessPreparationStage = FlameStageDefinition(
  stage: 0,
  type: FlameStageType.normal,
  timeLimitSeconds: 0,
  balloonCount: EndlessModeRules.activeBalloonLimit,
  speedRange: DoubleRange(56, EndlessModeRules.maximumSpeed),
  sizeRange: productionNormalSizeRange,
  scoreRule: StageScoreRule(
    pointsPerBalloon: 1,
    remainingSecondMultiplier: 0,
  ),
  successCondition: StageSuccessCondition.allTargetsPopped,
  failureCondition: StageFailureCondition.timeExpired,
  completion: StageCompletion.nextStage,
  balloonRule: FlameBalloonRule(
    requiredHits: 1,
    fakeCount: 0,
    fakePenaltySeconds: 0,
    firstHitSizeMultiplier: 1,
  ),
);
