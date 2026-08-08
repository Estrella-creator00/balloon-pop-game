import 'dart:js_interop';

@JS('window.localStorage')
external _LocalStorage get _localStorage;

extension type _LocalStorage._(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
  external void removeItem(JSString key);
}

abstract final class ProgressStorage {
  static const _key = 'balloon_pop_game_second_section_unlocked';
  static const _nextPlayableStageKey = 'poppop_next_playable_stage';
  static const _bestKey = 'poppop_best_score';
  static const _lastKey = 'poppop_last_score';
  static const _coinKey = 'poppop_coin_balance';
  static const _ownedProductsKey = 'poppop_owned_product_ids';
  static const _equippedProductsKey = 'poppop_equipped_product_ids';
  static const _nicknameKey = 'poppop_nickname';
  static const _nicknameOnboardingCompletedKey =
      'poppop_nickname_onboarding_completed';
  static const _soundEnabledKey = 'poppop_sound_enabled';
  static const _hapticEnabledKey = 'poppop_haptic_enabled';

  static bool isSecondSectionUnlocked() {
    try {
      return _localStorage.getItem(_key.toJS)?.toDart == 'true';
    } catch (_) {
      return false;
    }
  }

  static void unlockSecondSection() {
    try {
      _localStorage.setItem(_key.toJS, 'true'.toJS);
      advanceNextPlayableStage(11);
    } catch (_) {
      // Storage failure must not interrupt the game.
    }
  }

  static int nextPlayableStage() {
    final stored = _readInt(_nextPlayableStageKey);
    if (stored >= 1) return stored;
    return isSecondSectionUnlocked() ? 11 : 1;
  }

  static void advanceNextPlayableStage(int stage) {
    if (stage < 1 || stage <= nextPlayableStage()) return;
    try {
      _localStorage.setItem(_nextPlayableStageKey.toJS, '$stage'.toJS);
    } catch (_) {
      // Storage failure must not interrupt stage completion.
    }
  }

  static int bestScore() => _readInt(_bestKey);

  static int lastScore() => _readInt(_lastKey);

  static int coinBalance() => _readInt(_coinKey);

  static String? nickname() {
    try {
      final value = _localStorage.getItem(_nicknameKey.toJS)?.toDart;
      return value == null || value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  static void setNickname(String nickname) {
    try {
      _localStorage.setItem(_nicknameKey.toJS, nickname.toJS);
    } catch (_) {
      // Storage failure must not interrupt settings navigation.
    }
  }

  static bool nicknameOnboardingCompleted() {
    try {
      return _localStorage
              .getItem(_nicknameOnboardingCompletedKey.toJS)
              ?.toDart ==
          'true';
    } catch (_) {
      return false;
    }
  }

  static void setNicknameOnboardingCompleted(bool completed) {
    _writeBool(_nicknameOnboardingCompletedKey, completed);
  }

  static bool soundEnabled() => _readBool(_soundEnabledKey);

  static void setSoundEnabled(bool enabled) {
    _writeBool(_soundEnabledKey, enabled);
  }

  static bool hapticEnabled() => _readBool(_hapticEnabledKey);

  static void setHapticEnabled(bool enabled) {
    _writeBool(_hapticEnabledKey, enabled);
  }

  static int addCoins(int amount) {
    if (amount <= 0) return coinBalance();
    try {
      final updated = coinBalance() + amount;
      _localStorage.setItem(_coinKey.toJS, '$updated'.toJS);
      return updated;
    } catch (_) {
      return coinBalance();
    }
  }

  static Set<String> ownedProductIds() {
    try {
      final stored = _localStorage.getItem(_ownedProductsKey.toJS)?.toDart;
      if (stored == null || stored.isEmpty) return <String>{};
      return stored.split('|').where((id) => id.isNotEmpty).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static bool tryPurchaseProduct(String productId, int price) {
    if (price < 0) return false;
    try {
      final owned = ownedProductIds();
      final currentCoins = coinBalance();
      if (owned.contains(productId) || currentCoins < price) return false;

      final previousOwned = owned.join('|');
      owned.add(productId);
      _localStorage.setItem(_coinKey.toJS, '${currentCoins - price}'.toJS);
      try {
        _localStorage.setItem(_ownedProductsKey.toJS, owned.join('|').toJS);
      } catch (_) {
        _localStorage.setItem(_coinKey.toJS, '$currentCoins'.toJS);
        _localStorage.setItem(_ownedProductsKey.toJS, previousOwned.toJS);
        rethrow;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static String? equippedProductId(String category) {
    try {
      final entries = _readEquippedProducts();
      return entries[category];
    } catch (_) {
      return null;
    }
  }

  static void setEquippedProductId(String category, String productId) {
    try {
      final entries = _readEquippedProducts()..[category] = productId;
      final encoded = entries.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('|');
      _localStorage.setItem(_equippedProductsKey.toJS, encoded.toJS);
    } catch (_) {
      // Storage failure must not interrupt the store UI.
    }
  }

  static Map<String, String> _readEquippedProducts() {
    final stored = _localStorage.getItem(_equippedProductsKey.toJS)?.toDart;
    if (stored == null || stored.isEmpty) return <String, String>{};
    final result = <String, String>{};
    for (final item in stored.split('|')) {
      final separator = item.indexOf('=');
      if (separator <= 0 || separator == item.length - 1) continue;
      result[item.substring(0, separator)] = item.substring(separator + 1);
    }
    return result;
  }

  static bool saveScore(int score) {
    try {
      final isNew = score > bestScore();
      _localStorage.setItem(_lastKey.toJS, '$score'.toJS);
      if (isNew) _localStorage.setItem(_bestKey.toJS, '$score'.toJS);
      return isNew;
    } catch (_) {
      return false;
    }
  }

  static int _readInt(String key) {
    try {
      return int.tryParse(_localStorage.getItem(key.toJS)?.toDart ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static bool _readBool(String key) {
    try {
      final stored = _localStorage.getItem(key.toJS)?.toDart;
      return stored == null ? true : stored == 'true';
    } catch (_) {
      return true;
    }
  }

  static void _writeBool(String key, bool value) {
    try {
      _localStorage.setItem(key.toJS, '$value'.toJS);
    } catch (_) {
      // Storage failure must not interrupt settings changes.
    }
  }

  static void clear() {
    try {
      _localStorage.removeItem(_key.toJS);
      _localStorage.removeItem(_nextPlayableStageKey.toJS);
      _localStorage.removeItem(_bestKey.toJS);
      _localStorage.removeItem(_lastKey.toJS);
      _localStorage.removeItem(_coinKey.toJS);
      _localStorage.removeItem(_ownedProductsKey.toJS);
      _localStorage.removeItem(_equippedProductsKey.toJS);
      _localStorage.removeItem(_nicknameKey.toJS);
      _localStorage.removeItem(_nicknameOnboardingCompletedKey.toJS);
      _localStorage.removeItem(_soundEnabledKey.toJS);
      _localStorage.removeItem(_hapticEnabledKey.toJS);
    } catch (_) {
      // The menu still resets even if storage is unavailable.
    }
  }
}
