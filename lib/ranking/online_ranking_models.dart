import 'package:flutter/foundation.dart';

enum RankingCategory { stage, sixtySeconds }

extension RankingCategoryInfo on RankingCategory {
  String get label => switch (this) {
        RankingCategory.stage => 'STAGE 도전',
        RankingCategory.sixtySeconds => '60초 팝',
      };

  String get collection => switch (this) {
        RankingCategory.stage => 'leaderboards_stage_v2',
        RankingCategory.sixtySeconds => 'leaderboards_60s_v2',
      };

  String get legacyCollection => switch (this) {
        RankingCategory.stage => 'leaderboards_stage_v1',
        RankingCategory.sixtySeconds => 'leaderboards_60s_v1',
      };

  String get wireName => switch (this) {
        RankingCategory.stage => 'stage',
        RankingCategory.sixtySeconds => 'sixtySeconds',
      };
}

@immutable
class RankedRunResult {
  const RankedRunResult({
    required this.category,
    required this.score,
    this.reachedStage,
    this.cleared = false,
  });

  final RankingCategory category;
  final int score;
  final int? reachedStage;
  final bool cleared;
}

@immutable
class OnlineRankingEntry {
  const OnlineRankingEntry({
    required this.entryId,
    required this.displayName,
    required this.score,
    required this.rank,
    required this.submittedAt,
    this.reachedStage,
    this.cleared = false,
  });

  final String entryId;
  final String displayName;
  final int score;
  final int rank;
  final DateTime submittedAt;
  final int? reachedStage;
  final bool cleared;
}

@immutable
class OnlineLeaderboard {
  const OnlineLeaderboard({
    required this.category,
    required this.entries,
    required this.currentUser,
    required this.currentUserOutsideTop100,
  });

  final RankingCategory category;
  final List<OnlineRankingEntry> entries;
  final OnlineRankingEntry? currentUser;
  final bool currentUserOutsideTop100;
}

abstract final class RankingLimits {
  static const schemaVersion = 2;
  static const topLimit = 100;
  static const maximumStageScore = 600;
  static const maximumSixtySecondScore = 900;
}
