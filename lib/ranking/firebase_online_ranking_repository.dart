import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_ranking_runtime.dart';
import 'online_ranking_models.dart';
import 'online_ranking_repository.dart';
import 'ranking_functions_client.dart';
import 'ranking_nickname.dart';
import 'ranking_pending_store.dart';

class FirebaseOnlineRankingRepository implements OnlineRankingRepository {
  FirebaseOnlineRankingRepository({
    FirebaseRankingRuntime? runtime,
    FirebaseFirestore? firestore,
    RankingPendingStore? pendingStore,
    RankingFunctionsClient? functionsClient,
  })  : _runtime = runtime ?? FirebaseRankingRuntime.instance,
        _firestore = firestore,
        _pendingStore = pendingStore ?? SharedPreferencesRankingPendingStore(),
        _functionsClient = functionsClient ?? FirebaseRankingFunctionsClient();

  static final FirebaseOnlineRankingRepository instance =
      FirebaseOnlineRankingRepository();

  final FirebaseRankingRuntime _runtime;
  final FirebaseFirestore? _firestore;
  final RankingPendingStore _pendingStore;
  final RankingFunctionsClient _functionsClient;
  final Map<RankingCategory, Future<void>> _activeSubmissions = {};
  Future<void>? _activeDeletion;
  bool _deleting = false;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Future<OnlineLeaderboard> fetch(RankingCategory category) async {
    await _runtime.ensureUid(reactivateAfterDeletion: true);
    await _retryPending(category);
    final collection = _db.collection(category.collection);
    final results = await Future.wait<Object?>([
      collection
          .orderBy('score', descending: true)
          .limit(RankingLimits.topLimit)
          .get(),
      _functionsClient.call('getMyLeaderboardEntry', {
        'category': category.wireName,
      }),
    ]);
    final topSnapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final mineResult = results[1] as Map<String, dynamic>;
    final entries = _rankDocuments(category, topSnapshot.docs);
    final mineData = mineResult['entry'];
    final mineId = mineResult['entryId'] as String?;
    final inTop = mineId == null
        ? null
        : entries.where((entry) => entry.entryId == mineId).firstOrNull;
    if (inTop != null) {
      return OnlineLeaderboard(
        category: category,
        entries: entries,
        currentUser: inTop,
        currentUserOutsideTop100: false,
      );
    }
    if (mineId == null || mineData is! Map) {
      return OnlineLeaderboard(
        category: category,
        entries: entries,
        currentUser: null,
        currentUserOutsideTop100: false,
      );
    }
    final normalized = mineData.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    return OnlineLeaderboard(
      category: category,
      entries: entries,
      currentUser: _entry(
        category,
        mineId,
        normalized,
        RankingLimits.topLimit + 1,
      ),
      currentUserOutsideTop100: true,
    );
  }

  @override
  Future<void> submitBest(RankedRunResult result, String? nickname) {
    if (_deleting) {
      return Future.error(
        const OnlineDataDeletionException(
          OnlineDataDeletionFailure.unauthenticated,
        ),
      );
    }
    return _activeSubmissions.putIfAbsent(result.category, () async {
      try {
        await _runtime.ensureUid(reactivateAfterDeletion: true);
        await _submit(result, RankingNickname.sanitize(nickname));
        await _pendingStore.clear(result.category);
      } catch (_) {
        await _pendingStore.saveBest(result);
        rethrow;
      } finally {
        _activeSubmissions.remove(result.category);
      }
    });
  }

  Future<void> _retryPending(RankingCategory category) async {
    final pending = await _pendingStore.read(category);
    if (pending == null || _deleting) return;
    try {
      await _submit(pending, RankingNickname.fallback);
      await _pendingStore.clear(category);
    } catch (_) {
      // The foreground fetch reports its own network error; retain one best retry.
    }
  }

  Future<void> _submit(
    RankedRunResult result,
    String displayName,
  ) async {
    await _functionsClient.call('submitLeaderboard', {
      'category': result.category.wireName,
      'displayName': displayName,
      'score': result.score,
      if (result.category == RankingCategory.stage) ...{
        'reachedStage': result.reachedStage ?? 1,
        'cleared': result.cleared,
      },
    });
  }

  @override
  Future<void> deleteOnlineData() {
    return _activeDeletion ??= _deleteOnlineDataOnce().whenComplete(() {
      _activeDeletion = null;
    });
  }

  Future<void> _deleteOnlineDataOnce() async {
    _deleting = true;
    try {
      await Future.wait(
        _activeSubmissions.values.map(
          (submission) => submission.catchError((Object _) {}),
        ),
      );
      await _runtime.ensureUid();
      await _functionsClient.call('deleteOnlineData');
      await _pendingStore.clearAll();
      await _runtime.markCurrentUserDeleted();
    } on FirebaseFunctionsException catch (error) {
      throw OnlineDataDeletionException(_deletionFailure(error.code));
    } finally {
      _deleting = false;
    }
  }

  OnlineDataDeletionFailure _deletionFailure(String code) => switch (code) {
        'unauthenticated' => OnlineDataDeletionFailure.unauthenticated,
        'unavailable' ||
        'deadline-exceeded' ||
        'network-request-failed' =>
          OnlineDataDeletionFailure.offline,
        _ => OnlineDataDeletionFailure.server,
      };

  List<OnlineRankingEntry> _rankDocuments(
    RankingCategory category,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    var previousScore = -1;
    var rank = 0;
    return List.generate(documents.length, (index) {
      final data = documents[index].data();
      final score = data['score'] as int? ?? 0;
      if (score != previousScore) rank = index + 1;
      previousScore = score;
      return _entry(category, documents[index].id, data, rank);
    }, growable: false);
  }

  OnlineRankingEntry _entry(
    RankingCategory category,
    String entryId,
    Map<String, dynamic> data,
    int rank,
  ) {
    final timestamp = data['submittedAt'];
    final submittedAt = switch (timestamp) {
      Timestamp value => value.toDate(),
      String value => DateTime.tryParse(value) ?? DateTime(1970),
      _ => DateTime(1970),
    };
    return OnlineRankingEntry(
      entryId: entryId,
      displayName: data['displayName'] as String? ?? RankingNickname.fallback,
      score: data['score'] as int? ?? 0,
      rank: rank,
      submittedAt: submittedAt,
      reachedStage: category == RankingCategory.stage
          ? data['reachedStage'] as int? ?? 1
          : null,
      cleared: data['cleared'] as bool? ?? false,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
