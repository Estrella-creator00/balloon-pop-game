import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/pop_sound.dart';
import '../l10n/l10n.dart';
import 'firebase_online_ranking_repository.dart';
import 'online_ranking_models.dart';
import 'online_ranking_repository.dart';

typedef RankedChallengeLauncher = Future<RankedRunResult?> Function(
  RankingCategory category,
);

class OnlineRankingPage extends StatefulWidget {
  OnlineRankingPage({
    super.key,
    required this.currentNickname,
    required this.onChallenge,
    OnlineRankingRepository? repository,
  }) : repository = repository ?? FirebaseOnlineRankingRepository.instance;

  final String? currentNickname;
  final RankedChallengeLauncher onChallenge;
  final OnlineRankingRepository repository;

  @override
  State<OnlineRankingPage> createState() => _OnlineRankingPageState();
}

class _OnlineRankingPageState extends State<OnlineRankingPage> {
  RankingCategory _category = RankingCategory.stage;
  final Map<RankingCategory, Future<OnlineLeaderboard>> _loads = {};
  bool _challengeRunning = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _load(_category);
  }

  Future<OnlineLeaderboard> _load(
    RankingCategory category, {
    bool refresh = false,
  }) {
    if (refresh) _loads.remove(category);
    return _loads.putIfAbsent(
        category, () => widget.repository.fetch(category));
  }

  void _select(RankingCategory category) {
    if (_category == category) return;
    PopSound.playUiClick();
    setState(() {
      _category = category;
      _load(category);
    });
  }

  void _refresh() {
    setState(() {
      _load(_category, refresh: true);
    });
  }

  Future<void> _challenge() async {
    if (_challengeRunning) return;
    _challengeRunning = true;
    try {
      final result = await widget.onChallenge(_category);
      if (_disposed || !mounted || result == null) return;
      try {
        await widget.repository.submitBest(result, widget.currentNickname);
        if (_disposed || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.rankingSaved)),
        );
        _refresh();
      } catch (_) {
        if (_disposed || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.rankingPending)),
        );
      }
    } finally {
      _challengeRunning = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        key: const ValueKey('online-ranking-page'),
        backgroundColor: const Color(0xFFE8F8FF),
        body: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 8),
              SegmentedButton<RankingCategory>(
                key: const ValueKey('ranking-category-selector'),
                segments: RankingCategory.values
                    .map((category) => ButtonSegment(
                          value: category,
                          label: Text(category == RankingCategory.stage
                              ? context.l10n.stageChallenge
                              : context.l10n.sixtySecondPop),
                        ))
                    .toList(growable: false),
                selected: {_category},
                onSelectionChanged: (selection) => _select(selection.single),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<OnlineLeaderboard>(
                  future: _load(_category),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        key: ValueKey('online-ranking-loading'),
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return _RankingError(onRetry: _refresh);
                    }
                    return _LeaderboardView(board: snapshot.data!);
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  key: const ValueKey('online-ranking-challenge'),
                  onPressed: _challenge,
                  child: Text(context.l10n.challenge),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _header() => SizedBox(
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const ValueKey('ranking-back-button'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            Text(
              context.l10n.rankingTitle,
              style: TextStyle(
                color: Color(0xFFFF4F7B),
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                key: const ValueKey('online-ranking-refresh'),
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: context.l10n.retry,
              ),
            ),
          ],
        ),
      );
}

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView({required this.board});

  final OnlineLeaderboard board;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _MyBest(
              entry: board.currentUser,
              outside: board.currentUserOutsideTop100),
          const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(
                  width: 48, child: Text('순위', textAlign: TextAlign.center)),
              Expanded(child: Text('닉네임')),
              Text('기록'),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: board.entries.isEmpty
                ? Center(
                    key: ValueKey('online-ranking-empty'),
                    child: Text(context.l10n.rankingEmpty),
                  )
                : ListView.builder(
                    key: const ValueKey('online-ranking-top-100'),
                    itemCount: board.entries.length,
                    itemBuilder: (context, index) => _RankingRow(
                        entry: board.entries[index], category: board.category),
                  ),
          ),
        ],
      );
}

class _MyBest extends StatelessWidget {
  const _MyBest({required this.entry, required this.outside});
  final OnlineRankingEntry? entry;
  final bool outside;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('online-ranking-my-best'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          entry == null
              ? '내 최고 기록  -'
              : '내 최고 기록  ${entry!.score}점 · ${outside ? '100위 밖' : '${entry!.rank}위'}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry, required this.category});
  final OnlineRankingEntry entry;
  final RankingCategory category;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('online-ranking-row-${entry.rank}'),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE3EEF3))),
        ),
        child: Row(
          children: [
            SizedBox(
                width: 40,
                child: Text('${entry.rank}', textAlign: TextAlign.center)),
            Expanded(
              child: Text(entry.displayName, overflow: TextOverflow.ellipsis),
            ),
            Text(
              category == RankingCategory.stage
                  ? '${entry.score} · ${entry.cleared ? 'ALL CLEAR' : 'STAGE ${entry.reachedStage}'}'
                  : '${entry.score}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
}

class _RankingError extends StatelessWidget {
  const _RankingError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        key: const ValueKey('online-ranking-error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.rankingLoadError, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const ValueKey('online-ranking-retry'),
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
}
