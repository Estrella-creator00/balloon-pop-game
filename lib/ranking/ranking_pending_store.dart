import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'online_ranking_models.dart';

abstract interface class RankingPendingStore {
  Future<RankedRunResult?> read(RankingCategory category);
  Future<void> saveBest(RankedRunResult result);
  Future<void> clear(RankingCategory category);
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
    if (previous != null && previous.score >= result.score) return;
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
}
