import 'ranking_entry.dart';

/// Data boundary for R-01. A future Supabase implementation can replace the
/// mock repository without changing the ranking UI.
abstract interface class RankingRepository {
  Future<List<RankingEntry>> fetchCurrentWeekTop20(RankingWeek week);

  Future<RankingEntry?> fetchCurrentWeekLeader(RankingWeek week);

  Future<RankingEntry?> fetchPreviousWeekLeader(RankingWeek week);

  Future<RankingEntry?> fetchCurrentUserRanking({
    required RankingWeek week,
    required String? nickname,
  });
}
