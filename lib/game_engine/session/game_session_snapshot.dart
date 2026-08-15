import 'package:flutter/foundation.dart';

enum GameSessionPhase { ready, playing, stageClear, failed, paused, disposed }

@immutable
class GameSessionSnapshot {
  const GameSessionSnapshot({
    required this.stage,
    required this.score,
    required this.remainingBalloons,
    required this.phase,
    required this.secondsLeft,
    required this.stageClearCount,
  });

  final int stage;
  final int score;
  final int remainingBalloons;
  final GameSessionPhase phase;
  final int secondsLeft;
  final int stageClearCount;

  bool get isPaused => phase == GameSessionPhase.paused;
}
