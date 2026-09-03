import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_ranking_runtime.dart';
import 'online_ranking_models.dart';
import 'online_ranking_repository.dart';
import 'ranking_nickname.dart';
import 'ranking_pending_store.dart';

class FirebaseOnlineRankingRepository implements OnlineRankingRepository {
  FirebaseOnlineRankingRepository({
    FirebaseRankingRuntime? runtime,
    FirebaseFirestore? firestore,
    RankingPendingStore? pendingStore,
  })  : _runtime = runtime ?? FirebaseRankingRuntime.instance,
        _firestore = firestore,
        _pendingStore = pendingStore ?? SharedPreferencesRankingPendingStore();

  static final FirebaseOnlineRankingRepository instance =
      FirebaseOnlineRankingRepository();

  final FirebaseRankingRuntime _runtime;
  final FirebaseFirestore? _firestore;
  final RankingPendingStore _pendingStore;
  final Map<RankingCategory, Future<void>> _activeSubmissions = {};

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Future<OnlineLeaderboard> fetch(RankingCategory category) async {
    final uid = await _runtime.ensureUid();
    await _retryPending(category, uid);
    final collection = _db.collection(category.collection);
    final topSnapshot = await collection
        .orderBy('score', descending: true)
        .limit(RankingLimits.topLimit)
        .get();
    final entries = _rankDocuments(category, topSnapshot.docs);
    final inTop = entries.where((entry) => entry.uid == uid).firstOrNull;
    if (inTop != null) {
      return OnlineLeaderboard(
        category: category,
        entries: entries,
        currentUser: inTop,
        currentUserOutsideTop100: false,
      );
    }
    final mine = await collection.doc(uid).get();
    if (!mine.exists || mine.data() == null) {
      return OnlineLeaderboard(
        category: category,
        entries: entries,
        currentUser: null,
        currentUserOutsideTop100: false,
      );
    }
    final data = mine.data()!;
    final entry = _entry(category, uid, data, RankingLimits.topLimit + 1);
    return OnlineLeaderboard(
      category: category,
      entries: entries,
      currentUser: entry,
      currentUserOutsideTop100: true,
    );
  }

  @override
  Future<void> submitBest(RankedRunResult result, String? nickname) {
    return _activeSubmissions.putIfAbsent(result.category, () async {
      try {
        final uid = await _runtime.ensureUid();
        await _submit(uid, result, RankingNickname.sanitize(nickname));
        await _pendingStore.clear(result.category);
      } catch (_) {
        await _pendingStore.saveBest(result);
        rethrow;
      } finally {
        _activeSubmissions.remove(result.category);
      }
    });
  }

  Future<void> _retryPending(RankingCategory category, String uid) async {
    final pending = await _pendingStore.read(category);
    if (pending == null) return;
    try {
      await _submit(uid, pending, RankingNickname.fallback);
      await _pendingStore.clear(category);
    } catch (_) {
      // The foreground fetch reports its own network error; retain one best retry.
    }
  }

  Future<void> _submit(
    String uid,
    RankedRunResult result,
    String displayName,
  ) async {
    final reference = _db.collection(result.category.collection).doc(uid);
    await _db.runTransaction((transaction) async {
      final current = await transaction.get(reference);
      final currentScore = current.data()?['score'] as int? ?? -1;
      if (currentScore >= result.score) return;
      transaction.set(reference, {
        'uid': uid,
        'displayName': displayName,
        'score': result.score,
        if (result.category == RankingCategory.stage) ...{
          'reachedStage': result.reachedStage ?? 1,
          'cleared': result.cleared,
        },
        'submittedAt': FieldValue.serverTimestamp(),
        'schemaVersion': RankingLimits.schemaVersion,
      });
    });
  }

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
    String uid,
    Map<String, dynamic> data,
    int rank,
  ) {
    final timestamp = data['submittedAt'];
    return OnlineRankingEntry(
      uid: uid,
      displayName: data['displayName'] as String? ?? RankingNickname.fallback,
      score: data['score'] as int? ?? 0,
      rank: rank,
      submittedAt: timestamp is Timestamp ? timestamp.toDate() : DateTime(1970),
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
