abstract final class ProgressStorage {
  static bool _secondSectionUnlocked = false;
  static int _bestScore = 0;
  static int _lastScore = 0;

  static bool isSecondSectionUnlocked() => _secondSectionUnlocked;

  static void unlockSecondSection() {
    _secondSectionUnlocked = true;
  }

  static int bestScore() => _bestScore;

  static int lastScore() => _lastScore;

  static bool saveScore(int score) {
    _lastScore = score;
    if (score <= _bestScore) return false;
    _bestScore = score;
    return true;
  }

  static void clear() {
    _secondSectionUnlocked = false;
    _bestScore = 0;
    _lastScore = 0;
  }
}
