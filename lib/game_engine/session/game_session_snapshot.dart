import 'package:flutter/foundation.dart';

enum GameSessionPhase {
  ready,
  playing,
  paused,
  stageClear,
  bossClear,
  sectionClear,
  failed,
  disposed,
}

@immutable
class GameSessionSnapshot {
  const GameSessionSnapshot({
    required this.stage,
    required this.score,
    required this.remainingBalloons,
    required this.phase,
    required this.secondsLeft,
    required this.stageClearCount,
    required this.activeBossCount,
    required this.bossHp,
    required this.bossMaxHp,
  });

  final int stage;
  final int score;
  final int remainingBalloons;
  final GameSessionPhase phase;
  final int secondsLeft;
  final int stageClearCount;
  final int activeBossCount;
  final int bossHp;
  final int bossMaxHp;

  bool get isPaused => phase == GameSessionPhase.paused;
  bool get isStageClear => phase == GameSessionPhase.stageClear;
  bool get isBossClear => phase == GameSessionPhase.bossClear;
  bool get isSectionClear => phase == GameSessionPhase.sectionClear;
  bool get isTimeOver => phase == GameSessionPhase.failed;
}
