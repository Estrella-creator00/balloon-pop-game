abstract final class ProgressStorage {
  static const int initialCoinBalance = 20000;

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
  static final Set<String> _ownedProductIds = <String>{};
  static final Map<String, String> _equippedProductIds = <String, String>{};

  static bool isSecondSectionUnlocked() => _secondSectionUnlocked;

  static void unlockSecondSection() {
    _hasStoredData = true;
    _secondSectionUnlocked = true;
    advanceNextPlayableStage(11);
  }

  static int nextPlayableStage() => _nextPlayableStage > 1
      ? _nextPlayableStage
      : (_secondSectionUnlocked ? 11 : 1);

  static void advanceNextPlayableStage(int stage) {
    if (stage > _nextPlayableStage) {
      _hasStoredData = true;
      _nextPlayableStage = stage;
    }
  }

  static int bestScore() => _bestScore;

  static int lastScore() => _lastScore;

  static int coinBalance() => _coinBalance;

  static int initializeNewUserCoins() {
    if (_hasStoredData) return _coinBalance;
    _coinBalance = initialCoinBalance;
    _hasStoredData = true;
    return _coinBalance;
  }

  static String? nickname() => _nickname;

  static void setNickname(String nickname) {
    _hasStoredData = true;
    _nickname = nickname;
  }

  static bool nicknameOnboardingCompleted() => _nicknameOnboardingCompleted;

  static void setNicknameOnboardingCompleted(bool completed) {
    _hasStoredData = true;
    _nicknameOnboardingCompleted = completed;
  }

  static bool soundEnabled() => _soundEnabled;

  static void setSoundEnabled(bool enabled) {
    _hasStoredData = true;
    _soundEnabled = enabled;
  }

  static bool hapticEnabled() => _hapticEnabled;

  static void setHapticEnabled(bool enabled) {
    _hasStoredData = true;
    _hapticEnabled = enabled;
  }

  static int addCoins(int amount) {
    if (amount <= 0) return _coinBalance;
    _hasStoredData = true;
    _coinBalance += amount;
    return _coinBalance;
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
    return true;
  }

  static String? equippedProductId(String category) =>
      _equippedProductIds[category];

  static void setEquippedProductId(String category, String productId) {
    _hasStoredData = true;
    _equippedProductIds[category] = productId;
  }

  static bool saveScore(int score) {
    _hasStoredData = true;
    _lastScore = score;
    if (score <= _bestScore) return false;
    _bestScore = score;
    return true;
  }

  static void clear() {
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
    _ownedProductIds.clear();
    _equippedProductIds.clear();
  }
}
