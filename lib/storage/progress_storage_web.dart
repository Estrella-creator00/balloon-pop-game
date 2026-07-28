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
    } catch (_) {
      // The menu still resets even if storage is unavailable.
    }
  }
}
