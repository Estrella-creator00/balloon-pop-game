import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/pop_sound.dart';
import '../l10n/l10n.dart';
import 'firebase_online_ranking_repository.dart';
import 'online_ranking_models.dart';
import 'online_ranking_repository.dart';
import 'ranking_moderation_service.dart';
import 'ranking_functions_client.dart';

typedef RankedChallengeLauncher = Future<RankedRunResult?> Function(
  RankingCategory category,
);

class OnlineRankingPage extends StatefulWidget {
  OnlineRankingPage({
    super.key,
    required this.currentNickname,
    required this.onChallenge,
    OnlineRankingRepository? repository,
    RankingModerationService? moderationService,
  })  : repository = repository ?? FirebaseOnlineRankingRepository.instance,
        moderationService = moderationService ?? RankingModerationService();

  final String? currentNickname;
  final RankedChallengeLauncher onChallenge;
  final OnlineRankingRepository repository;
  final RankingModerationService moderationService;

  @override
  State<OnlineRankingPage> createState() => _OnlineRankingPageState();
}

class _OnlineRankingPageState extends State<OnlineRankingPage> {
  RankingCategory _category = RankingCategory.stage;
  final Map<RankingCategory, Future<OnlineLeaderboard>> _loads = {};
  bool _challengeRunning = false;
  bool _disposed = false;
  final Map<RankingCategory, Set<String>> _hidden = {};
  Set<String> _hiddenActors = const {};

  @override
  void initState() {
    super.initState();
    _load(_category);
    _loadHidden(_category);
  }

  Future<void> _loadHidden(RankingCategory category) async {
    final results = await Future.wait([
      widget.moderationService.safetyStore.hiddenEntryIds(category),
      widget.moderationService.safetyStore.hiddenActorIds(),
    ]);
    if (!mounted) return;
    setState(() {
      _hidden[category] = results[0];
      _hiddenActors = results[1];
    });
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
      _loadHidden(category);
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
      } on InvalidRankingNicknameException {
        if (_disposed || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.nicknameSafetyValidation)),
        );
      } on OnlineRankingAccessException {
        if (_disposed || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.onlineRankingDisabledBody)),
        );
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
                    return _LeaderboardView(
                      board: snapshot.data!,
                      hiddenEntryIds: _hidden[_category] ?? const {},
                      hiddenActorIds: _hiddenActors,
                      onHide: _hideEntry,
                      onReport: _reportEntry,
                    );
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

  Future<void> _hideEntry(OnlineRankingEntry entry) async {
    await widget.moderationService.hide(_category, entry);
    if (!mounted) return;
    setState(() {
      if (entry.publicActorId == null) {
        (_hidden[_category] ??= <String>{}).add(entry.entryId);
      } else {
        _hiddenActors = {..._hiddenActors, entry.publicActorId!};
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(entry.publicActorId == null
            ? context.l10n.rankingLegacyEntryHidden
            : context.l10n.rankingUserHidden),
      ),
    );
  }

  Future<void> _reportEntry(OnlineRankingEntry entry) async {
    final reason = await showDialog<RankingReportReason>(
      context: context,
      builder: (context) => _ReportReasonDialog(),
    );
    if (reason == null || !mounted) return;
    try {
      final created = await widget.moderationService.report(
        category: _category,
        entryId: entry.entryId,
        publicActorId: entry.publicActorId,
        displayName: entry.displayName,
        reason: reason,
      );
      if (!mounted) return;
      setState(() => _hiddenActors = {
            ..._hiddenActors,
            if (entry.publicActorId != null) entry.publicActorId!,
          });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(created
              ? context.l10n.rankingReportReceived
              : context.l10n.rankingAlreadyReported),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.rankingReportError)),
      );
    }
  }

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
  const _LeaderboardView({
    required this.board,
    required this.hiddenEntryIds,
    required this.hiddenActorIds,
    required this.onHide,
    required this.onReport,
  });

  final OnlineLeaderboard board;
  final Set<String> hiddenEntryIds;
  final Set<String> hiddenActorIds;
  final ValueChanged<OnlineRankingEntry> onHide;
  final ValueChanged<OnlineRankingEntry> onReport;

  @override
  Widget build(BuildContext context) {
    final visibleEntries = board.entries
        .where((entry) =>
            !hiddenEntryIds.contains(entry.entryId) &&
            (entry.publicActorId == null ||
                !hiddenActorIds.contains(entry.publicActorId)))
        .toList(growable: false);
    return Column(
      children: [
        _MyBest(
            entry: board.currentUser, outside: board.currentUserOutsideTop100),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
                width: 48,
                child: Text(context.l10n.rankingColumnRank,
                    textAlign: TextAlign.center)),
            Expanded(child: Text(context.l10n.rankingColumnNickname)),
            Text(context.l10n.rankingColumnRecord),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: visibleEntries.isEmpty
              ? Center(
                  key: ValueKey('online-ranking-empty'),
                  child: Text(context.l10n.rankingEmpty),
                )
              : ListView.builder(
                  key: const ValueKey('online-ranking-top-100'),
                  itemCount: visibleEntries.length,
                  itemBuilder: (context, index) {
                    final entry = visibleEntries[index];
                    return _RankingRow(
                      entry: entry,
                      category: board.category,
                      isCurrentUser:
                          entry.entryId == board.currentUser?.entryId,
                      onHide: () => onHide(entry),
                      onReport: () => onReport(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }
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
              ? context.l10n.myBestNone
              : context.l10n.myBest(
                  entry!.score,
                  outside
                      ? context.l10n.outsideTop100
                      : context.l10n.rankPosition(entry!.rank),
                ),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.entry,
    required this.category,
    required this.isCurrentUser,
    required this.onHide,
    required this.onReport,
  });
  final OnlineRankingEntry entry;
  final RankingCategory category;
  final bool isCurrentUser;
  final VoidCallback onHide;
  final VoidCallback onReport;

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
                  ? context.l10n.rankingScore(
                      entry.score,
                      entry.cleared
                          ? context.l10n.allClear
                          : context.l10n.reachedStage(entry.reachedStage!),
                    )
                  : '${entry.score}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            if (!isCurrentUser)
              PopupMenuButton<String>(
                key: ValueKey('ranking-entry-menu-${entry.entryId}'),
                tooltip: context.l10n.rankingEntryActions,
                onSelected: (value) {
                  if (value == 'hide') onHide();
                  if (value == 'report') onReport();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'hide',
                    child: Text(entry.publicActorId == null
                        ? context.l10n.hideRankingEntry
                        : context.l10n.hideRankingUser),
                  ),
                  if (entry.publicActorId != null)
                    PopupMenuItem(
                      value: 'report',
                      child: Text(context.l10n.reportNickname),
                    ),
                ],
              ),
          ],
        ),
      );
}

class _ReportReasonDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
        key: const ValueKey('ranking-report-dialog'),
        title: Text(context.l10n.reportNickname),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: RankingReportReason.values
              .map(
                (reason) => ListTile(
                  key: ValueKey('ranking-report-${reason.name}'),
                  title: Text(_label(context, reason)),
                  onTap: () => Navigator.pop(context, reason),
                ),
              )
              .toList(growable: false),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
        ],
      );

  String _label(BuildContext context, RankingReportReason reason) =>
      switch (reason) {
        RankingReportReason.personalInformation =>
          context.l10n.reportReasonPersonalInformation,
        RankingReportReason.hateOrHarassment =>
          context.l10n.reportReasonHateOrHarassment,
        RankingReportReason.sexualContent =>
          context.l10n.reportReasonSexualContent,
        RankingReportReason.impersonation =>
          context.l10n.reportReasonImpersonation,
        RankingReportReason.otherInappropriate =>
          context.l10n.reportReasonOther,
      };
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
