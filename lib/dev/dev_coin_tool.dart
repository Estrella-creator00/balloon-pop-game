// TEMP DEV TOOL - remove before production release.
const String tempDevCoinPassword = '0592';
const int tempDevCoinGrantAmount = 10000;
const int tempDevCoinRequiredTaps = 7;
const Duration tempDevCoinTapWindow = Duration(seconds: 2);

/// Detects rapid taps without scheduling timers or continuous work.
class DevCoinTapGate {
  DateTime? _firstTapAt;
  int _tapCount = 0;

  bool registerTap(DateTime now) {
    final firstTapAt = _firstTapAt;
    if (firstTapAt == null ||
        now.difference(firstTapAt) > tempDevCoinTapWindow) {
      _firstTapAt = now;
      _tapCount = 1;
      return false;
    }

    _tapCount++;
    if (_tapCount < tempDevCoinRequiredTaps) return false;
    // Deliberately reset instead of persisting a one-time claim flag. Each
    // fresh 7-tap + password flow may grant another local test balance.
    reset();
    return true;
  }

  void reset() {
    _firstTapAt = null;
    _tapCount = 0;
  }
}
