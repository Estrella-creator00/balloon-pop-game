import '../storage/progress_storage.dart';

/// Owns POPPOP coin reward rules independently from UI and game rendering.
abstract final class CoinService {
  static int get balance => ProgressStorage.coinBalance();

  static int rewardForScore(int score) => score <= 0 ? 0 : score ~/ 10;

  static int grantScoreReward(int score) {
    final reward = rewardForScore(score);
    ProgressStorage.addCoins(reward);
    return reward;
  }
}

/// Prevents the same game session from granting its result reward twice.
class CoinRewardSession {
  bool _granted = false;
  int _earned = 0;

  bool get hasGranted => _granted;
  int get earned => _earned;

  int grantForScore(int score) {
    if (_granted) return _earned;
    _granted = true;
    _earned = CoinService.grantScoreReward(score);
    return _earned;
  }

  void reset() {
    _granted = false;
    _earned = 0;
  }
}
