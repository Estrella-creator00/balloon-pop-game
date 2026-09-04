import 'dart:async';
import 'dart:io';

import 'package:balloon_pop_game/game_engine/game_session_state.dart';
import 'package:balloon_pop_game/game_engine/session/game_session_snapshot.dart';
import 'package:balloon_pop_game/game_engine/stages/flame_stage_definition.dart';
import 'package:balloon_pop_game/ranking/firebase_ranking_runtime.dart';
import 'package:balloon_pop_game/ranking/online_ranking_models.dart';
import 'package:balloon_pop_game/ranking/online_ranking_page.dart';
import 'package:balloon_pop_game/ranking/online_ranking_repository.dart';
import 'package:balloon_pop_game/ranking/ranking_nickname.dart';
import 'package:balloon_pop_game/ranking/ranking_pending_store.dart';
import 'package:balloon_pop_game/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Firebase runtime initializes and signs in anonymously once', () async {
    var initializationCount = 0;
    var signInCount = 0;
    final gate = Completer<void>();
    final runtime = FirebaseRankingRuntime(
      initialize: () async {
        initializationCount++;
        await gate.future;
      },
      currentUid: () => null,
      signInAnonymously: () async {
        signInCount++;
        return 'uid-1';
      },
    );

    final first = runtime.ensureUid();
    final second = runtime.ensureUid();
    expect(initializationCount, 1);
    gate.complete();
    expect(await Future.wait([first, second]), ['uid-1', 'uid-1']);
    expect(initializationCount, 1);
    expect(signInCount, 1);
  });

  test('ranking is lazy until repository is used', () {
    var initializationCount = 0;
    FirebaseRankingRuntime(initialize: () async => initializationCount++);
    expect(initializationCount, 0);
  });

  test('Firebase failure stays isolated and initialization can retry',
      () async {
    var attempts = 0;
    final runtime = FirebaseRankingRuntime(
      initialize: () async {
        attempts++;
        if (attempts == 1) throw StateError('offline');
      },
      currentUid: () => attempts > 1 ? 'uid-after-retry' : null,
      signInAnonymously: () async => 'unused',
    );
    await expectLater(runtime.ensureUid(), throwsStateError);

    final localSession = GameSessionState();
    localSession.startNewGame(
      flamePreviewStage(1),
      const {1: 1, 2: 1},
      generation: 1,
    );
    expect(localSession.phase, GameSessionPhase.playing);
    expect(await runtime.ensureUid(), 'uid-after-retry');
    expect(attempts, 2);
    localSession.dispose();
  });

  test('ranking nickname accepts safe text and falls back safely', () {
    expect(RankingNickname.sanitize('  팝팝 Player 7  '), '팝팝 Player 7');
    expect(RankingNickname.sanitize(''), RankingNickname.fallback);
    expect(RankingNickname.sanitize('bad\nname'), RankingNickname.fallback);
    expect(RankingNickname.sanitize('운영자'), RankingNickname.fallback);
  });

  test('pending store keeps only the best result per category', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesRankingPendingStore();
    await store.saveBest(const RankedRunResult(
      category: RankingCategory.sixtySeconds,
      score: 12,
    ));
    await store.saveBest(const RankedRunResult(
      category: RankingCategory.sixtySeconds,
      score: 8,
    ));
    expect((await store.read(RankingCategory.sixtySeconds))!.score, 12);
    await store.clear(RankingCategory.sixtySeconds);
    expect(await store.read(RankingCategory.sixtySeconds), isNull);
  });

  test('ranked Stage run reuses the complete production Stage 1-30 rules', () {
    final session = GameSessionState();
    var generation = 1;
    for (var index = 0; index < flamePreviewStages.length; index++) {
      final definition = flamePreviewStages[index];
      final targetHp = <int, int>{
        for (var i = 0; i < definition.balloonCount; i++)
          generation * 1000 + i: definition.balloonRule.requiredHits,
      };
      final fakeIds = <int>{
        for (var i = 0; i < definition.balloonRule.fakeCount; i++)
          generation * 1000 + 500 + i,
      };
      final bossHp = <int, int>{
        for (var i = 0; i < (definition.bossRule?.bossCount ?? 0); i++)
          generation * 1000 + 700 + i: definition.bossRule!.maxHp,
      };
      if (index == 0) {
        session.startNewGame(definition, targetHp,
            fakeIds: fakeIds, bossHpById: bossHp, generation: generation);
      } else {
        session.beginNextStage(definition, targetHp,
            fakeIds: fakeIds, bossHpById: bossHp, generation: generation);
      }
      if (definition.isBoss) {
        expect(session.startBoss(), isTrue);
        if (definition.bossRule!.sharedHp) {
          final real = session.stage30RealBossId!;
          for (var hit = 0; hit < definition.bossRule!.maxHp; hit++) {
            session.hitBoss(real, swapRoll: 1);
          }
        } else {
          for (final id in bossHp.keys) {
            for (var hit = 0; hit < definition.bossRule!.maxHp; hit++) {
              session.hitBoss(id, swapRoll: 1);
            }
          }
        }
      } else {
        for (final entry in targetHp.entries) {
          for (var hit = 0; hit < entry.value; hit++) {
            session.hitBalloon(entry.key);
          }
        }
      }
      generation++;
    }
    expect(session.stage, 30);
    expect(session.phase, GameSessionPhase.bossClear);
    session.completeCoreClear();
    expect(session.phase, GameSessionPhase.coreClear);
    session.dispose();
  });

  test('60 second challenge has six one-hit targets and stops while paused',
      () {
    final session = GameSessionState();
    session.startRankedSixtySeconds(
      {for (var id = 1; id <= 6; id++) id: 1},
      generation: 1,
    );
    expect(session.secondsLeft, 60);
    expect(session.remainingBalloons, 6);
    expect(session.fakeCount, 0);
    expect(session.activeBossCount, 0);
    expect(session.hitBalloon(1), BalloonHitResult.popped);
    expect(session.score, 1);
    session.addContinuousBalloon(7);
    expect(session.remainingBalloons, 6);
    session.pause();
    session.recordUpdate(20);
    expect(session.secondsLeft, 60);
    session.resume();
    session.recordUpdate(60);
    expect(session.phase, GameSessionPhase.rankedSixtySecondComplete);
    expect(session.score, 1);
    session.dispose();
  });

  for (final size in [
    const Size(360, 640),
    const Size(390, 844),
    const Size(768, 1024),
  ]) {
    testWidgets('online ranking fits ${size.width}x${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      final repository = _FakeOnlineRankingRepository();
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnlineRankingPage(
          currentNickname: '테스터',
          repository: repository,
          onChallenge: (_) async => null,
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('online-ranking-page')), findsOneWidget);
      expect(repository.fetchCount[RankingCategory.stage], 1);
    });
  }

  testWidgets('ranking loads each category once and refreshes explicitly',
      (tester) async {
    final repository = _FakeOnlineRankingRepository();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OnlineRankingPage(
        currentNickname: '테스터',
        repository: repository,
        onChallenge: (_) async => const RankedRunResult(
          category: RankingCategory.sixtySeconds,
          score: 5,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('60초 팝'));
    await tester.pumpAndSettle();
    expect(repository.fetchCount[RankingCategory.stage], 1);
    expect(repository.fetchCount[RankingCategory.sixtySeconds], 1);
    await tester.tap(find.text('STAGE 도전'));
    await tester.pumpAndSettle();
    expect(repository.fetchCount[RankingCategory.stage], 1);
    await tester.tap(find.byKey(const ValueKey('online-ranking-refresh')));
    await tester.pumpAndSettle();
    expect(repository.fetchCount[RankingCategory.stage], 2);
  });

  test('Firestore rules enforce UID documents and bounded TOP 100', () {
    final rules = File('firestore.rules').readAsStringSync();
    expect(rules, contains('request.auth.uid == uid'));
    expect(rules, contains('request.query.limit <= 100'));
    expect(
        rules, contains('request.resource.data.submittedAt == request.time'));
    expect(rules, contains('allow delete: if false'));
    expect(rules, isNot(contains('allow read, write: if true')));
  });

  test('leaderboard collections and score caps are separated', () {
    expect(RankingCategory.stage.collection, 'leaderboards_stage_v1');
    expect(RankingCategory.sixtySeconds.collection, 'leaderboards_60s_v1');
    expect(RankingLimits.maximumStageScore, 600);
    expect(RankingLimits.maximumSixtySecondScore, 10000);
  });

  test('repository is transaction-based with one UID document and no stream',
      () {
    final source = File('lib/ranking/firebase_online_ranking_repository.dart')
        .readAsStringSync();
    expect(source, contains('.doc(uid)'));
    expect(source, contains('runTransaction'));
    expect(source, contains('currentScore >= result.score'));
    expect(source, contains('.limit(RankingLimits.topLimit)'));
    expect(source, isNot(contains('.snapshots()')));
    expect(source, isNot(contains('Timer.')));
  });
}

class _FakeOnlineRankingRepository implements OnlineRankingRepository {
  final Map<RankingCategory, int> fetchCount = {};

  @override
  Future<OnlineLeaderboard> fetch(RankingCategory category) async {
    fetchCount[category] = (fetchCount[category] ?? 0) + 1;
    return OnlineLeaderboard(
      category: category,
      entries: const [],
      currentUser: null,
      currentUserOutsideTop100: false,
    );
  }

  @override
  Future<void> submitBest(RankedRunResult result, String? nickname) async {}
}
