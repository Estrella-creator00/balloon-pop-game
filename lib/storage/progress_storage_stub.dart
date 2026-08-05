abstract final class ProgressStorage {
  static bool _secondSectionUnlocked = false;
  static int _bestScore = 0;
  static int _lastScore = 0;
  static int _coinBalance = 0;
  static final Set<String> _ownedProductIds = <String>{};

  static bool isSecondSectionUnlocked() => _secondSectionUnlocked;

  static void unlockSecondSection() {
    _secondSectionUnlocked = true;
  }

  static int bestScore() => _bestScore;

  static int lastScore() => _lastScore;

  static int coinBalance() => _coinBalance;

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
    _ownedProductIds.clear();
  }
}
