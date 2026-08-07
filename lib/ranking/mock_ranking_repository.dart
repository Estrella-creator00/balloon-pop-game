import 'ranking_entry.dart';
import 'ranking_repository.dart';

/// Deterministic development data for R-01. Replace this provider, not the UI,
/// when Supabase ranking storage is introduced.
class MockRankingRepository implements RankingRepository {
  const MockRankingRepository();

  static const _players = <(String, String, int)>[
    ('mock-01', '시원이', 4960),
    ('mock-02', 'POPKING', 4730),
    ('mock-03', '풍선왕', 4510),
    ('mock-04', '하트팡', 4320),
    ('mock-05', 'Bubble', 4140),
    ('mock-06', 'StarPop', 3980),
    ('mock-07', '구름톡', 3760),
    ('mock-08', '팡팡이', 3520),
    ('mock-09', 'MintPop', 3390),
    ('mock-10', '별사탕', 3250),
    ('mock-11', 'ToyBall', 3110),
    ('mock-12', '보라팡', 2970),
    ('mock-13', 'Cloudy', 2840),
    ('mock-14', '핑크별', 2710),
    ('mock-15', 'PopTree', 2580),
    ('mock-16', '노랑콩', 2440),
    ('mock-17', 'SkyTap', 2290),
    ('mock-18', '민트별', 2140),
    ('mock-19', '토이팝', 1980),
    ('mock-20', 'BUBBLE', 1820),
    ('mock-21', '테스트21', 1700),
    ('mock-22', '테스트22', 1590),
    ('mock-23', '테스트23', 1510),
    ('mock-24', '테스트24', 1450),
  ];

  List<RankingEntry> _entries(RankingWeek week) => List.unmodifiable(
        [
          for (var index = 0; index < _players.length; index++)
            RankingEntry(
              userId: _players[index].$1,
              nickname: _players[index].$2,
              score: _players[index].$3,
              rank: index + 1,
              weekId: week.id,
              recordedAt: week.startUtc.add(
                Duration(hours: 2 + index * 3),
              ),
            ),
        ],
      );

  @override
  Future<List<RankingEntry>> fetchCurrentWeekTop20(
    RankingWeek week,
  ) async =>
      _entries(week).take(20).toList(growable: false);

  @override
  Future<RankingEntry?> fetchCurrentWeekLeader(RankingWeek week) async =>
      _entries(week).first;

  @override
  Future<RankingEntry?> fetchPreviousWeekLeader(RankingWeek week) async {
    final previous = week.previous;
    return RankingEntry(
      userId: 'previous-mock-winner',
      nickname: 'POPKING',
      score: 5820,
      rank: 1,
      weekId: previous.id,
      recordedAt: previous.startUtc.add(const Duration(days: 5)),
    );
  }

  @override
  Future<RankingEntry?> fetchCurrentUserRanking({
    required RankingWeek week,
    required String? nickname,
  }) async {
    final normalized = nickname?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final entry in _entries(week)) {
      if (entry.nickname == normalized) return entry;
    }
    return RankingEntry(
      userId: 'mock-current-local-user',
      nickname: normalized,
      score: 1420,
      rank: 34,
      weekId: week.id,
      recordedAt: week.startUtc.add(const Duration(days: 3, hours: 4)),
    );
  }
}
