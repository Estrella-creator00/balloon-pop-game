import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_storage_backend.dart';

final class SharedPreferencesProgressStorageBackend
    implements ProgressStorageBackend {
  SharedPreferencesProgressStorageBackend._(this._preferences);

  final SharedPreferencesWithCache _preferences;

  static Future<SharedPreferencesProgressStorageBackend> create() async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: ProgressStorageKeys.all,
      ),
    );
    return SharedPreferencesProgressStorageBackend._(preferences);
  }

  @override
  Set<String> get keys => _preferences.keys;

  @override
  Object? get(String key) => _preferences.get(key);

  @override
  Future<void> setBool(String key, bool value) =>
      _preferences.setBool(key, value);

  @override
  Future<void> setInt(String key, int value) => _preferences.setInt(key, value);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> clear() => _preferences.clear();
}

abstract final class ProgressStorage {
  static const int initialCoinBalance = 20000;

  static ProgressStorageBackend? _backend;
  static ProgressStorageBackendFactory _backendFactory =
      SharedPreferencesProgressStorageBackend.create;
  static Future<void>? _initializationFuture;
  static Future<void> _pendingWrites = Future<void>.value();
  static Object? _initializationError;
  static Object? _lastWriteError;
  static bool _initializationFailed = false;
  static int _backendCreationCount = 0;

  static bool _hasStoredData = false;
  static bool _secondSectionUnlocked = false;
  static int _nextPlayableStage = 1;
  static int _bestScore = 0;
  static int _lastScore = 0;
  static int _coinBalance = 0;
  static String? _nickname;
  static bool _nicknameOnboardingCompleted = false;
  static bool _soundEnabled = true;
  static bool _hapticEnabled = true;
  static int _endlessBestScore = 0;
  static int _endlessLastScore = 0;
  static bool _endlessIntroSeen = false;
  static final Set<String> _ownedProductIds = <String>{};
  static final Map<String, String> _equippedProductIds = <String, String>{};

  static Future<void> initialize() =>
      _initializationFuture ??= _initializeOnce();

  static Future<void> _initializeOnce() async {
    try {
      final backend = await _backendFactory();
      _backendCreationCount++;
      _backend = backend;
      _loadFrom(backend);
      _initializationError = null;
      _initializationFailed = false;
    } catch (error, stackTrace) {
      _backend = null;
      _initializationError = error;
      _initializationFailed = true;
      _hasStoredData = true;
      developer.log(
        'Native progress storage initialization failed.',
        name: 'poppop.storage',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void _loadFrom(ProgressStorageBackend backend) {
    _resetMemory();
    _hasStoredData = backend.keys.any(ProgressStorageKeys.all.contains);
    _secondSectionUnlocked =
        _readBool(backend, ProgressStorageKeys.secondSectionUnlocked) ?? false;
    _nextPlayableStage = _validStage(
      _readInt(backend, ProgressStorageKeys.nextPlayableStage),
    );
    _bestScore = _nonNegative(
      _readInt(backend, ProgressStorageKeys.bestScore),
    );
    _lastScore = _nonNegative(
      _readInt(backend, ProgressStorageKeys.lastScore),
    );
    _coinBalance = _nonNegative(
      _readInt(backend, ProgressStorageKeys.coinBalance),
    );
    _nickname = _readNonEmptyString(backend, ProgressStorageKeys.nickname);
    _nicknameOnboardingCompleted = _readBool(
          backend,
          ProgressStorageKeys.nicknameOnboardingCompleted,
        ) ??
        false;
    _soundEnabled =
        _readBool(backend, ProgressStorageKeys.soundEnabled) ?? true;
    _hapticEnabled =
        _readBool(backend, ProgressStorageKeys.hapticEnabled) ?? true;
    _endlessBestScore = _nonNegative(
      _readInt(backend, ProgressStorageKeys.endlessBestScore),
    );
    _endlessLastScore = _nonNegative(
      _readInt(backend, ProgressStorageKeys.endlessLastScore),
    );
    _endlessIntroSeen =
        _readBool(backend, ProgressStorageKeys.endlessIntroSeen) ?? false;
    _ownedProductIds.addAll(
      _decodeIds(
        _readString(backend, ProgressStorageKeys.ownedProductIds),
      ),
    );
    _equippedProductIds.addAll(
      _decodeEquipped(
        _readString(backend, ProgressStorageKeys.equippedProductIds),
      ),
    );
  }

  static bool? _readBool(ProgressStorageBackend backend, String key) {
    try {
      final value = backend.get(key);
      return value is bool ? value : null;
    } catch (_) {
      return null;
    }
  }

  static int? _readInt(ProgressStorageBackend backend, String key) {
    try {
      final value = backend.get(key);
      return value is int ? value : null;
    } catch (_) {
      return null;
    }
  }

  static String? _readString(ProgressStorageBackend backend, String key) {
    try {
      final value = backend.get(key);
      return value is String ? value : null;
    } catch (_) {
      return null;
    }
  }

  static String? _readNonEmptyString(
    ProgressStorageBackend backend,
    String key,
  ) {
    final value = _readString(backend, key);
    return value == null || value.isEmpty ? null : value;
  }

  static int _nonNegative(int? value) =>
      value != null && value >= 0 ? value : 0;

  static int _validStage(int? value) =>
      value != null && value >= 1 && value <= 31 ? value : 1;

  static Set<String> _decodeIds(String? value) => value == null
      ? <String>{}
      : value.split('|').where((id) => id.isNotEmpty).toSet();

  static Map<String, String> _decodeEquipped(String? value) {
    final result = <String, String>{};
    if (value == null || value.isEmpty) return result;
    for (final item in value.split('|')) {
      final separator = item.indexOf('=');
      if (separator <= 0 || separator == item.length - 1) continue;
      result[item.substring(0, separator)] = item.substring(separator + 1);
    }
    return result;
  }

  static String _encodeEquipped() => _equippedProductIds.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join('|');

  static void _enqueue(
    Future<void> Function(ProgressStorageBackend backend) operation,
  ) {
    final backend = _backend;
    if (backend == null || _initializationFailed) return;
    _pendingWrites = _pendingWrites.then((_) => operation(backend)).catchError(
      (Object error, StackTrace stackTrace) {
        _lastWriteError = error;
        developer.log(
          'Native progress storage write failed.',
          name: 'poppop.storage',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  static Future<void> flush() => _pendingWrites;

  static bool isSecondSectionUnlocked() => _secondSectionUnlocked;

  static void unlockSecondSection() {
    _hasStoredData = true;
    if (!_secondSectionUnlocked) {
      _secondSectionUnlocked = true;
      _enqueue((backend) => backend.setBool(
            ProgressStorageKeys.secondSectionUnlocked,
            true,
          ));
    }
    advanceNextPlayableStage(11);
  }

  static int nextPlayableStage() => _nextPlayableStage > 1
      ? _nextPlayableStage
      : (_secondSectionUnlocked ? 11 : 1);

  static void advanceNextPlayableStage(int stage) {
    if (stage < 1 || stage > 31 || stage <= nextPlayableStage()) return;
    _hasStoredData = true;
    _nextPlayableStage = stage;
    _enqueue((backend) => backend.setInt(
          ProgressStorageKeys.nextPlayableStage,
          stage,
        ));
  }

  static int bestScore() => _bestScore;

  static int lastScore() => _lastScore;

  static int endlessBestScore() => _endlessBestScore;

  static bool saveEndlessBestScore(int score) {
    _hasStoredData = true;
    if (score < 0 || score <= _endlessBestScore) return false;
    _endlessBestScore = score;
    _enqueue((backend) => backend.setInt(
          ProgressStorageKeys.endlessBestScore,
          score,
        ));
    return true;
  }

  static int endlessLastScore() => _endlessLastScore;

  static bool saveEndlessLastScore(int score) {
    _hasStoredData = true;
    if (score < 0) return false;
    _endlessLastScore = score;
    _enqueue((backend) => backend.setInt(
          ProgressStorageKeys.endlessLastScore,
          score,
        ));
    return true;
  }

  static bool endlessIntroSeen() => _endlessIntroSeen;

  static void setEndlessIntroSeen(bool seen) {
    _hasStoredData = true;
    _endlessIntroSeen = seen;
    _enqueue((backend) => backend.setBool(
          ProgressStorageKeys.endlessIntroSeen,
          seen,
        ));
  }

  static int coinBalance() => _coinBalance;

  static int initializeNewUserCoins() {
    if (_hasStoredData || _initializationFailed) return _coinBalance;
    _coinBalance = initialCoinBalance;
    _hasStoredData = true;
    _enqueue((backend) => backend.setInt(
          ProgressStorageKeys.coinBalance,
          initialCoinBalance,
        ));
    return _coinBalance;
  }

  static String? nickname() => _nickname;

  static void setNickname(String nickname) {
    _hasStoredData = true;
    _nickname = nickname;
    _enqueue((backend) => backend.setString(
          ProgressStorageKeys.nickname,
          nickname,
        ));
  }

  static bool nicknameOnboardingCompleted() => _nicknameOnboardingCompleted;

  static void setNicknameOnboardingCompleted(bool completed) {
    _hasStoredData = true;
    _nicknameOnboardingCompleted = completed;
    _enqueue((backend) => backend.setBool(
          ProgressStorageKeys.nicknameOnboardingCompleted,
          completed,
        ));
  }

  static bool soundEnabled() => _soundEnabled;

  static void setSoundEnabled(bool enabled) {
    _hasStoredData = true;
    _soundEnabled = enabled;
    _enqueue((backend) => backend.setBool(
          ProgressStorageKeys.soundEnabled,
          enabled,
        ));
  }

  static bool hapticEnabled() => _hapticEnabled;

  static void setHapticEnabled(bool enabled) {
    _hasStoredData = true;
    _hapticEnabled = enabled;
    _enqueue((backend) => backend.setBool(
          ProgressStorageKeys.hapticEnabled,
          enabled,
        ));
  }

  static int addCoins(int amount) {
    if (amount <= 0) return _coinBalance;
    _hasStoredData = true;
    _coinBalance += amount;
    final updated = _coinBalance;
    _enqueue((backend) => backend.setInt(
          ProgressStorageKeys.coinBalance,
          updated,
        ));
    return updated;
  }

  static Set<String> ownedProductIds() => Set.unmodifiable(_ownedProductIds);

  static bool tryPurchaseProduct(String productId, int price) {
    if (_ownedProductIds.contains(productId) ||
        price < 0 ||
        _coinBalance < price) {
      return false;
    }
    _coinBalance -= price;
    _ownedProductIds.add(productId);
    _hasStoredData = true;
    final updatedCoins = _coinBalance;
    final updatedOwned = _ownedProductIds.join('|');
    _enqueue((backend) async {
      await backend.setInt(ProgressStorageKeys.coinBalance, updatedCoins);
      await backend.setString(
          ProgressStorageKeys.ownedProductIds, updatedOwned);
    });
    return true;
  }

  static String? equippedProductId(String category) =>
      _equippedProductIds[category];

  static void setEquippedProductId(String category, String productId) {
    _hasStoredData = true;
    _equippedProductIds[category] = productId;
    final encoded = _encodeEquipped();
    _enqueue((backend) => backend.setString(
          ProgressStorageKeys.equippedProductIds,
          encoded,
        ));
  }

  static bool saveScore(int score) {
    if (score < 0) return false;
    _hasStoredData = true;
    _lastScore = score;
    final isNew = score > _bestScore;
    if (isNew) _bestScore = score;
    final best = _bestScore;
    _enqueue((backend) async {
      await backend.setInt(ProgressStorageKeys.lastScore, score);
      if (isNew) await backend.setInt(ProgressStorageKeys.bestScore, best);
    });
    return isNew;
  }

  static void clear() {
    _resetMemory();
    _enqueue((backend) => backend.clear());
  }

  static void _resetMemory() {
    _hasStoredData = false;
    _secondSectionUnlocked = false;
    _nextPlayableStage = 1;
    _bestScore = 0;
    _lastScore = 0;
    _coinBalance = 0;
    _nickname = null;
    _nicknameOnboardingCompleted = false;
    _soundEnabled = true;
    _hapticEnabled = true;
    _endlessBestScore = 0;
    _endlessLastScore = 0;
    _endlessIntroSeen = false;
    _ownedProductIds.clear();
    _equippedProductIds.clear();
  }

  @visibleForTesting
  static Future<void> initializeForTesting(
    ProgressStorageBackendFactory factory,
  ) async {
    await resetForTesting();
    _backendFactory = factory;
    await initialize();
  }

  @visibleForTesting
  static Future<void> resetForTesting() async {
    await flush();
    _backend = null;
    _backendFactory = SharedPreferencesProgressStorageBackend.create;
    _initializationFuture = null;
    _pendingWrites = Future<void>.value();
    _initializationError = null;
    _lastWriteError = null;
    _initializationFailed = false;
    _backendCreationCount = 0;
    _resetMemory();
  }

  @visibleForTesting
  static Object? get initializationErrorForTesting => _initializationError;

  @visibleForTesting
  static Object? get lastWriteErrorForTesting => _lastWriteError;

  @visibleForTesting
  static int get backendCreationCountForTesting => _backendCreationCount;

  @visibleForTesting
  static Set<String> get storageKeysForTesting => ProgressStorageKeys.all;
}
