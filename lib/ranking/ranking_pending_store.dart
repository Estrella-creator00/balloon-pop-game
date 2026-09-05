import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'online_ranking_models.dart';

abstract interface class RankingPendingStore {
  Future<RankedRunResult?> read(RankingCategory category);
  Future<void> saveBest(RankedRunResult result);
  Future<void> clear(RankingCategory category);
  Future<void> clearAll();
}

class SharedPreferencesRankingPendingStore implements RankingPendingStore {
  SharedPreferencesRankingPendingStore()
      : _preferences = SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferences;

  String _key(RankingCategory category) =>
      'poppop_pending_ranking_${category.name}_v1';

  @override
  Future<RankedRunResult?> read(RankingCategory category) async {
    final preferences = await _preferences;
    final value = preferences.getString(_key(category));
    if (value == null) return null;
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      return RankedRunResult(
        category: category,
        score: json['score'] as int,
        reachedStage: json['reachedStage'] as int?,
        cleared: json['cleared'] as bool? ?? false,
      );
    } catch (_) {
      await clear(category);
      return null;
    }
  }

  @override
  Future<void> saveBest(RankedRunResult result) async {
    final previous = await read(result.category);
    if (previous != null && !_improves(previous, result)) return;
    final preferences = await _preferences;
    await preferences.setString(
      _key(result.category),
      jsonEncode({
        'score': result.score,
        if (result.reachedStage != null) 'reachedStage': result.reachedStage,
        'cleared': result.cleared,
      }),
    );
  }

  @override
  Future<void> clear(RankingCategory category) async {
    final preferences = await _preferences;
    await preferences.remove(_key(category));
  }

  @override
  Future<void> clearAll() async {
    for (final category in RankingCategory.values) {
      await clear(category);
    }
  }

  bool _improves(RankedRunResult previous, RankedRunResult next) {
    if (next.score != previous.score) return next.score > previous.score;
    if (next.category != RankingCategory.stage) return false;
    final previousStage = previous.reachedStage ?? 1;
    final nextStage = next.reachedStage ?? 1;
    return nextStage > previousStage ||
        (nextStage == previousStage && !previous.cleared && next.cleared);
  }
}
