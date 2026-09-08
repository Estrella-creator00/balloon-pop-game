import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'online_ranking_models.dart';

class BlockedRankingActor {
  const BlockedRankingActor({required this.actorId, required this.displayName});

  final String actorId;
  final String displayName;
}

abstract interface class RankingSafetyStore {
  Future<bool> hasCurrentConsent();
  Future<void> acceptCurrentPolicy();
  Future<bool> isOnlineRankingEnabled();
  Future<void> disableWithParentPin(String pin);
  Future<bool> enableWithParentPin(String pin);
  Future<void> hide(RankingCategory category, String entryId);
  Future<Set<String>> hiddenEntryIds(RankingCategory category);
  Future<void> hideActor(String actorId, String displayName);
  Future<Set<String>> hiddenActorIds();
  Future<List<BlockedRankingActor>> blockedActors();
  Future<void> unhideActor(String actorId);
  Future<bool> wasReported(RankingCategory category, String entryId);
  Future<void> markReported(RankingCategory category, String entryId);
  Future<void> clearAll();
}

class SharedPreferencesRankingSafetyStore implements RankingSafetyStore {
  SharedPreferencesRankingSafetyStore()
      : _preferences = SharedPreferences.getInstance();

  static const currentPolicyVersion = 1;
  static const _consentVersionKey = 'poppop_ranking_safety_consent_version';
  static const _enabledKey = 'poppop_online_ranking_enabled';
  static const _pinSaltKey = 'poppop_parent_pin_salt';
  static const _pinHashKey = 'poppop_parent_pin_hash';
  static const _hiddenKey = 'poppop_hidden_ranking_entries_v1';
  static const _reportedKey = 'poppop_reported_ranking_entries_v1';
  static const _blockedActorsKey = 'poppop_blocked_ranking_actors_v1';

  final Future<SharedPreferences> _preferences;

  String _entryKey(RankingCategory category, String entryId) =>
      '${category.wireName}:$entryId';

  @override
  Future<bool> hasCurrentConsent() async =>
      (await _preferences).getInt(_consentVersionKey) == currentPolicyVersion;

  @override
  Future<void> acceptCurrentPolicy() async {
    await (await _preferences).setInt(
      _consentVersionKey,
      currentPolicyVersion,
    );
  }

  @override
  Future<bool> isOnlineRankingEnabled() async =>
      (await _preferences).getBool(_enabledKey) ?? true;

  @override
  Future<void> disableWithParentPin(String pin) async {
    if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) {
      throw const FormatException('Invalid parent PIN.');
    }
    final preferences = await _preferences;
    final random = Random.secure();
    final salt = base64UrlEncode(
      List<int>.generate(18, (_) => random.nextInt(256)),
    );
    await preferences.setString(_pinSaltKey, salt);
    await preferences.setString(_pinHashKey, _hash(pin, salt));
    await preferences.setBool(_enabledKey, false);
  }

  @override
  Future<bool> enableWithParentPin(String pin) async {
    final preferences = await _preferences;
    final salt = preferences.getString(_pinSaltKey);
    final expected = preferences.getString(_pinHashKey);
    if (salt == null || expected == null || _hash(pin, salt) != expected) {
      return false;
    }
    await preferences.setBool(_enabledKey, true);
    return true;
  }

  @override
  Future<void> hide(RankingCategory category, String entryId) async {
    final preferences = await _preferences;
    final values = preferences.getStringList(_hiddenKey)?.toSet() ?? <String>{};
    values.add(_entryKey(category, entryId));
    await preferences.setStringList(_hiddenKey, values.toList()..sort());
  }

  @override
  Future<Set<String>> hiddenEntryIds(RankingCategory category) async {
    final values = (await _preferences).getStringList(_hiddenKey) ?? const [];
    final prefix = '${category.wireName}:';
    return values
        .where((value) => value.startsWith(prefix))
        .map((value) => value.substring(prefix.length))
        .toSet();
  }

  @override
  Future<void> hideActor(String actorId, String displayName) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(actorId)) return;
    final preferences = await _preferences;
    final actors = await blockedActors();
    final updated = <String, BlockedRankingActor>{
      for (final actor in actors) actor.actorId: actor,
      actorId: BlockedRankingActor(actorId: actorId, displayName: displayName),
    };
    await preferences.setStringList(
      _blockedActorsKey,
      updated.values
          .map((actor) => jsonEncode({
                'actorId': actor.actorId,
                'displayName': actor.displayName,
              }))
          .toList()
        ..sort(),
    );
  }

  @override
  Future<Set<String>> hiddenActorIds() async =>
      (await blockedActors()).map((actor) => actor.actorId).toSet();

  @override
  Future<List<BlockedRankingActor>> blockedActors() async {
    final values =
        (await _preferences).getStringList(_blockedActorsKey) ?? const [];
    final actors = <BlockedRankingActor>[];
    for (final value in values) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is! Map ||
            decoded['actorId'] is! String ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(decoded['actorId'] as String) ||
            decoded['displayName'] is! String) {
          continue;
        }
        actors.add(BlockedRankingActor(
          actorId: decoded['actorId'] as String,
          displayName: decoded['displayName'] as String,
        ));
      } catch (_) {
        // Ignore corrupt local-only block entries.
      }
    }
    actors.sort((a, b) => a.displayName.compareTo(b.displayName));
    return actors;
  }

  @override
  Future<void> unhideActor(String actorId) async {
    final preferences = await _preferences;
    final values = (await blockedActors())
        .where((actor) => actor.actorId != actorId)
        .map((actor) => jsonEncode({
              'actorId': actor.actorId,
              'displayName': actor.displayName,
            }))
        .toList();
    await preferences.setStringList(_blockedActorsKey, values);
  }

  @override
  Future<bool> wasReported(
    RankingCategory category,
    String entryId,
  ) async =>
      ((await _preferences).getStringList(_reportedKey) ?? const [])
          .contains(_entryKey(category, entryId));

  @override
  Future<void> markReported(
    RankingCategory category,
    String entryId,
  ) async {
    final preferences = await _preferences;
    final values =
        preferences.getStringList(_reportedKey)?.toSet() ?? <String>{};
    values.add(_entryKey(category, entryId));
    await preferences.setStringList(_reportedKey, values.toList()..sort());
  }

  @override
  Future<void> clearAll() async {
    final preferences = await _preferences;
    for (final key in [
      _consentVersionKey,
      _enabledKey,
      _pinSaltKey,
      _pinHashKey,
      _hiddenKey,
      _reportedKey,
      _blockedActorsKey,
    ]) {
      await preferences.remove(key);
    }
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
