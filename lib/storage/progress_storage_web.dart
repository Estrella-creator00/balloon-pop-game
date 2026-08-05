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
  static const _bestKey = 'poppop_best_score';
  static const _lastKey = 'poppop_last_score';
  static const _coinKey = 'poppop_coin_balance';
  static const _ownedProductsKey = 'poppop_owned_product_ids';

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
    } catch (_) {
      // Storage failure must not interrupt the game.
    }
  }

  static int bestScore() => _readInt(_bestKey);

  static int lastScore() => _readInt(_lastKey);

  static int coinBalance() => _readInt(_coinKey);

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

  static void clear() {
    try {
      _localStorage.removeItem(_key.toJS);
      _localStorage.removeItem(_bestKey.toJS);
      _localStorage.removeItem(_lastKey.toJS);
      _localStorage.removeItem(_coinKey.toJS);
      _localStorage.removeItem(_ownedProductsKey.toJS);
    } catch (_) {
      // The menu still resets even if storage is unavailable.
    }
  }
}
