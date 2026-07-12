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

  static void clear() {
    try {
      _localStorage.removeItem(_key.toJS);
    } catch (_) {
      // The menu still resets even if storage is unavailable.
    }
  }
}
