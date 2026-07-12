abstract final class ProgressStorage {
  static bool _secondSectionUnlocked = false;

  static bool isSecondSectionUnlocked() => _secondSectionUnlocked;

  static void unlockSecondSection() {
    _secondSectionUnlocked = true;
  }

  static void clear() {
    _secondSectionUnlocked = false;
  }
}
