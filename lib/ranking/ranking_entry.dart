import 'package:flutter/foundation.dart';

/// One user's best score for a POPPOP ranking week.
@immutable
class RankingEntry {
  const RankingEntry({
    required this.userId,
    required this.nickname,
    required this.score,
    required this.rank,
    required this.weekId,
    required this.recordedAt,
  });

  final String userId;
  final String nickname;
  final int score;
  final int rank;
  final String weekId;
  final DateTime recordedAt;
}

/// KST ranking week bounded by Monday 17:00 through next Monday 16:59:59.
@immutable
class RankingWeek {
  const RankingWeek._({
    required this.id,
    required this.startUtc,
    required this.nextStartUtc,
  });

  static const kstOffset = Duration(hours: 9);
  static const boundaryHour = 17;

  final String id;
  final DateTime startUtc;
  final DateTime nextStartUtc;

  DateTime get startKst => startUtc.add(kstOffset);
  DateTime get nextStartKst => nextStartUtc.add(kstOffset);

  RankingWeek get previous => RankingWeek.forInstant(
        startUtc.subtract(const Duration(microseconds: 1)),
      );

  Duration remainingAt(DateTime instant) {
    final remaining = nextStartUtc.difference(instant.toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Uses a shifted KST calendar so Monday 17:00 becomes Monday 00:00 for
  /// week-boundary calculation. The stable week ID is that Monday's KST date.
  static RankingWeek forInstant(DateTime instant) {
    final kst = instant.toUtc().add(kstOffset);
    final shifted = kst.subtract(const Duration(hours: boundaryHour));
    final monday = DateTime.utc(
      shifted.year,
      shifted.month,
      shifted.day,
    ).subtract(Duration(days: shifted.weekday - DateTime.monday));
    final startUtc = DateTime.utc(
      monday.year,
      monday.month,
      monday.day,
      boundaryHour - kstOffset.inHours,
    );
    final nextStartUtc = startUtc.add(const Duration(days: 7));
    final id = '${monday.year.toString().padLeft(4, '0')}-'
        '${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}';
    return RankingWeek._(
      id: id,
      startUtc: startUtc,
      nextStartUtc: nextStartUtc,
    );
  }
}

@immutable
class WeeklyRankingData {
  const WeeklyRankingData({
    required this.week,
    required this.entries,
    required this.currentLeader,
    required this.previousLeader,
    required this.currentUser,
  });

  final RankingWeek week;
  final List<RankingEntry> entries;
  final RankingEntry? currentLeader;
  final RankingEntry? previousLeader;
  final RankingEntry? currentUser;
}
