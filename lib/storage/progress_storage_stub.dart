abstract final class ProgressStorage {
  static bool _secondSectionUnlocked = false;
  static int _bestScore = 0;
  static int _lastScore = 0;
  static int _coinBalance = 0;
  static String? _nickname;
  static bool _soundEnabled = true;
  static bool _hapticEnabled = true;
  static final Set<String> _ownedProductIds = <String>{};
  static final Map<String, String> _equippedProductIds = <String, String>{};

  static bool isSecondSectionUnlocked() => _secondSectionUnlocked;

  static void unlockSecondSection() {
    _secondSectionUnlocked = true;
  }

  static int bestScore() => _bestScore;

  static int lastScore() => _lastScore;

  static int coinBalance() => _coinBalance;

  static String? nickname() => _nickname;

  static void setNickname(String nickname) {
    _nickname = nickname;
  }

  static bool soundEnabled() => _soundEnabled;

  static void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  static bool hapticEnabled() => _hapticEnabled;

  static void setHapticEnabled(bool enabled) {
    _hapticEnabled = enabled;
  }

  static int addCoins(int amount) {
    if (amount <= 0) return _coinBalance;
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
    return true;
  }

  static String? equippedProductId(String category) =>
      _equippedProductIds[category];

  static void setEquippedProductId(String category, String productId) {
    _equippedProductIds[category] = productId;
  }

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
    _coinBalance = 0;
    _nickname = null;
    _soundEnabled = true;
    _hapticEnabled = true;
    _ownedProductIds.clear();
    _equippedProductIds.clear();
  }
}
