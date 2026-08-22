import 'package:flutter/foundation.dart';

enum GameSessionPhase {
  ready,
  loading,
  bossReady,
  playing,
  paused,
  stageClear,
  bossClear,
  coreClear,
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
    required this.damagedBalloonCount,
    required this.fakeCount,
    required this.stage30RealBossId,
    required this.generation,
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
  final int damagedBalloonCount;
  final int fakeCount;
  final int? stage30RealBossId;
  final int generation;
}
