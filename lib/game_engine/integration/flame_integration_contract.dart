import '../session/game_session_snapshot.dart';

enum FlameGameplayFeedbackKind {
  balloonFirstHit,
  balloonPop,
  kickExitStarted,
  fakeHit,
  bossHit,
  bossDefeated,
  bossClear,
  bossReady,
}

class FlameGameplayFeedbackEvent {
  const FlameGameplayFeedbackEvent({required this.kind, required this.skinId});

  final FlameGameplayFeedbackKind kind;
  final String skinId;
}

class FlameStageCompletionEvent {
  const FlameStageCompletionEvent({
    required this.stage,
    required this.phase,
    required this.generation,
  });

  final int stage;
  final GameSessionPhase phase;
  final int generation;
}

enum FlameIntegrationOutcome { completed, failed, endlessFinished, exited }

enum FlameRankedRunMode { none, stage, sixtySeconds }

class EndlessRecordResult {
  const EndlessRecordResult({
    required this.score,
    required this.bestScore,
    required this.isNewBest,
  });

  final int score;
  final int bestScore;
  final bool isNewBest;
}

class FlameIntegrationResult {
  const FlameIntegrationResult({
    required this.outcome,
    required this.stage,
    required this.score,
    required this.sessionId,
  });

  final FlameIntegrationOutcome outcome;
  final int stage;
  final int score;
  final int sessionId;

  bool get recordsResult =>
      outcome == FlameIntegrationOutcome.completed ||
      outcome == FlameIntegrationOutcome.failed;
}

typedef FlameGameplayFeedbackCallback = void Function(
  FlameGameplayFeedbackEvent event,
);
typedef FlameStageCompletionCallback = void Function(
  FlameStageCompletionEvent event,
);
typedef EndlessRecordCallback = EndlessRecordResult Function(int score);
