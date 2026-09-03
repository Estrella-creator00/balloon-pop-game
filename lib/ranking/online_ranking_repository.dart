import 'online_ranking_models.dart';

abstract interface class OnlineRankingRepository {
  Future<OnlineLeaderboard> fetch(RankingCategory category);

  Future<void> submitBest(RankedRunResult result, String? nickname);
}
