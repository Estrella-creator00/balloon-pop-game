import 'package:flutter/material.dart';

import 'mock_ranking_repository.dart';
import 'ranking_entry.dart';
import 'ranking_repository.dart';

/// R-01 주간 랭킹.
class WeeklyRankingPage extends StatefulWidget {
  const WeeklyRankingPage({
    super.key,
    this.repository = const MockRankingRepository(),
    this.currentNickname,
    this.now,
  });

  final RankingRepository repository;
  final String? currentNickname;
  final DateTime Function()? now;

  @override
  State<WeeklyRankingPage> createState() => _WeeklyRankingPageState();
}

class _WeeklyRankingPageState extends State<WeeklyRankingPage> {
  late RankingWeek _week;
  late Future<WeeklyRankingData> _rankingFuture;

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _week = RankingWeek.forInstant(_now());
    _rankingFuture = _loadRanking();
  }

  Future<WeeklyRankingData> _loadRanking() async {
    final entries = await widget.repository.fetchCurrentWeekTop20(_week);
    final leadersAndUser = await Future.wait<RankingEntry?>([
      widget.repository.fetchCurrentWeekLeader(_week),
      widget.repository.fetchPreviousWeekLeader(_week),
      widget.repository.fetchCurrentUserRanking(
        week: _week,
        nickname: widget.currentNickname,
      ),
    ]);
    return WeeklyRankingData(
      week: _week,
      entries: entries,
      currentLeader: leadersAndUser[0],
      previousLeader: leadersAndUser[1],
      currentUser: leadersAndUser[2],
    );
  }

  void _retry() => setState(_reload);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('weekly-ranking-page'),
      backgroundColor: const Color(0xFFE8F8FF),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: FutureBuilder<WeeklyRankingData>(
          future: _rankingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _RankingLoadingView();
            }
            if (snapshot.hasError) {
              return _RankingErrorView(onRetry: _retry);
            }
            final data = snapshot.data!;
            return _RankingContent(
              data: data,
              now: _now(),
              currentNickname: widget.currentNickname,
            );
          },
        ),
      ),
    );
  }
}

class _RankingContent extends StatelessWidget {
  const _RankingContent({
    required this.data,
    required this.now,
    required this.currentNickname,
  });

  final WeeklyRankingData data;
  final DateTime now;
  final String? currentNickname;

  bool _isCurrentUser(RankingEntry entry) {
    final current = data.currentUser;
    if (current != null && current.userId == entry.userId) return true;
    final nickname = currentNickname?.trim();
    return nickname != null &&
        nickname.isNotEmpty &&
        nickname == entry.nickname;
  }

  @override
  Widget build(BuildContext context) {
    if (data.entries.isEmpty) {
      return const Column(
        children: [
          _RankingHeader(),
          Expanded(child: _RankingEmptyView()),
        ],
      );
    }

    final outsideTop20 =
        data.currentUser != null && data.currentUser!.rank > 20;
    return ListView(
      key: const ValueKey('ranking-scroll'),
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        const _RankingHeader(),
        const SizedBox(height: 12),
        _WeekInformationCard(week: data.week, now: now),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LeaderSummaryCard(
                key: const ValueKey('previous-week-leader-card'),
                label: '지난주 1위',
                entry: data.previousLeader,
                accent: const Color(0xFF7354E8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LeaderSummaryCard(
                key: const ValueKey('current-week-leader-card'),
                label: '현재 1위',
                entry: data.currentLeader,
                accent: const Color(0xFFFF4F7B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              SizedBox(
                width: 46,
                child: Text(
                  '순위',
                  textAlign: TextAlign.center,
                  style: _columnLabelStyle,
                ),
              ),
              SizedBox(width: 9),
              Expanded(child: Text('닉네임', style: _columnLabelStyle)),
              Text('점수', style: _columnLabelStyle),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.white,
          elevation: 3,
          shadowColor: const Color(0x33204A5F),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < data.entries.length; index++) ...[
                RankingEntryRow(
                  entry: data.entries[index],
                  isCurrentUser: _isCurrentUser(data.entries[index]),
                ),
                if (index != data.entries.length - 1)
                  const Divider(
                    height: 1,
                    indent: 62,
                    endIndent: 14,
                    color: Color(0xFFE7EFF3),
                  ),
              ],
            ],
          ),
        ),
        if (outsideTop20) ...[
          const SizedBox(height: 14),
          _MyRankingCard(entry: data.currentUser!),
        ],
      ],
    );
  }
}

const _columnLabelStyle = TextStyle(
  color: Color(0xFF718A98),
  fontSize: 12,
  fontWeight: FontWeight.w800,
);

class _RankingHeader extends StatelessWidget {
  const _RankingHeader();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Colors.white,
                elevation: 2,
                shadowColor: const Color(0x33003366),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: const ValueKey('ranking-back-button'),
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(14),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF2D70A0),
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
            const Text(
              '주간 랭킹',
              style: TextStyle(
                color: Color(0xFFFF4F7B),
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _WeekInformationCard extends StatelessWidget {
  const _WeekInformationCard({required this.week, required this.now});

  final RankingWeek week;
  final DateTime now;

  String get _remainingLabel {
    final remaining = week.remainingAt(now);
    final days = remaining.inDays;
    final hours = remaining.inHours.remainder(24);
    return '다음 랭킹까지 $days일 $hours시간';
  }

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('ranking-week-info'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FDFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD6EDF5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF42A7D8),
              size: 25,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '이번 주 랭킹',
                    style: TextStyle(
                      color: Color(0xFF244F68),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '월요일 17:00 ~ 다음 월요일 16:59 (KST) · $_remainingLabel',
                    style: const TextStyle(
                      color: Color(0xFF718A98),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LeaderSummaryCard extends StatelessWidget {
  const _LeaderSummaryCard({
    super.key,
    required this.label,
    required this.entry,
    required this.accent,
  });

  final String label;
  final RankingEntry? entry;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29204A5F),
              blurRadius: 9,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              entry?.nickname ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF244F68),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              entry == null ? '-' : '${formatRankingScore(entry!.score)}점',
              style: const TextStyle(
                color: Color(0xFF7354E8),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class RankingEntryRow extends StatelessWidget {
  const RankingEntryRow({
    super.key,
    required this.entry,
    required this.isCurrentUser,
  });

  final RankingEntry entry;
  final bool isCurrentUser;

  Color get _rankColor => switch (entry.rank) {
        1 => const Color(0xFFE5A900),
        2 => const Color(0xFF8E9BA5),
        3 => const Color(0xFFB9784B),
        _ => const Color(0xFF8CA2AE),
      };

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('ranking-row-${entry.rank}'),
        height: 55,
        color: isCurrentUser ? const Color(0xFFFFF2F7) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Center(
                child: entry.rank == 1
                    ? Icon(
                        Icons.workspace_premium_rounded,
                        key: const ValueKey('ranking-top-accent-1'),
                        color: _rankColor,
                        size: 23,
                      )
                    : Container(
                        key: entry.rank <= 3
                            ? ValueKey('ranking-top-accent-${entry.rank}')
                            : null,
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: entry.rank <= 3
                              ? _rankColor.withValues(alpha: 0.14)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${entry.rank}',
                          style: TextStyle(
                            color: _rankColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      entry.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF244F68),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 6),
                    Container(
                      key: const ValueKey('ranking-current-user-badge'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD7E3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '나',
                        style: TextStyle(
                          color: Color(0xFFD93D69),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatRankingScore(entry.score),
              style: TextStyle(
                color: entry.rank <= 3
                    ? const Color(0xFF7354E8)
                    : const Color(0xFF405E6E),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _MyRankingCard extends StatelessWidget {
  const _MyRankingCard({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('ranking-outside-top20-card'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2F7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD2E0)),
        ),
        child: Row(
          children: [
            const Text(
              '내 순위',
              style: TextStyle(
                color: Color(0xFFD93D69),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 13),
            Text(
              '${entry.rank}위',
              style: const TextStyle(
                color: Color(0xFF7354E8),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF244F68),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${formatRankingScore(entry.score)}점',
              style: const TextStyle(
                color: Color(0xFF405E6E),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _RankingLoadingView extends StatelessWidget {
  const _RankingLoadingView();

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          _RankingHeader(),
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                key: ValueKey('ranking-loading'),
                color: Color(0xFFFF4F7B),
              ),
            ),
          ),
        ],
      );
}

class _RankingEmptyView extends StatelessWidget {
  const _RankingEmptyView();

  @override
  Widget build(BuildContext context) => const Center(
        key: ValueKey('ranking-empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: Color(0xFF8CBED6),
              size: 44,
            ),
            SizedBox(height: 12),
            Text(
              '이번 주 랭킹이 아직 없어요.',
              style: TextStyle(
                color: Color(0xFF244F68),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 5),
            Text(
              '첫 기록의 주인공이 되어보세요!',
              style: TextStyle(
                color: Color(0xFF718A98),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _RankingErrorView extends StatelessWidget {
  const _RankingErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const _RankingHeader(),
          Expanded(
            child: Center(
              key: const ValueKey('ranking-error'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '랭킹을 불러오지 못했어요.',
                    style: TextStyle(
                      color: Color(0xFF244F68),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('ranking-retry-button'),
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4F7B),
                    ),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

String formatRankingScore(int score) {
  final digits = score.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
