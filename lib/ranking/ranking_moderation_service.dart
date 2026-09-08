import 'online_ranking_models.dart';
import 'ranking_functions_client.dart';
import 'ranking_safety_store.dart';

enum RankingReportReason {
  personalInformation,
  hateOrHarassment,
  sexualContent,
  impersonation,
  otherInappropriate,
}

extension RankingReportReasonWire on RankingReportReason {
  String get wireName => switch (this) {
        RankingReportReason.personalInformation => 'personalInformation',
        RankingReportReason.hateOrHarassment => 'hateOrHarassment',
        RankingReportReason.sexualContent => 'sexualContent',
        RankingReportReason.impersonation => 'impersonation',
        RankingReportReason.otherInappropriate => 'otherInappropriate',
      };
}

class RankingModerationService {
  RankingModerationService({
    RankingFunctionsClient? functionsClient,
    RankingSafetyStore? safetyStore,
  })  : _functionsClient = functionsClient ?? FirebaseRankingFunctionsClient(),
        safetyStore = safetyStore ?? SharedPreferencesRankingSafetyStore();

  final RankingFunctionsClient _functionsClient;
  final RankingSafetyStore safetyStore;

  Future<void> hide(RankingCategory category, OnlineRankingEntry entry) =>
      entry.publicActorId == null
          ? safetyStore.hide(category, entry.entryId)
          : safetyStore.hideActor(entry.publicActorId!, entry.displayName);

  Future<bool> report({
    required RankingCategory category,
    required String entryId,
    required String? publicActorId,
    required String displayName,
    required RankingReportReason reason,
  }) async {
    if (await safetyStore.wasReported(category, entryId)) return false;
    final result = await _functionsClient.call('reportLeaderboardEntry', {
      'category': category.wireName,
      'entryId': entryId,
      'reason': reason.wireName,
      'policyVersion': SharedPreferencesRankingSafetyStore.currentPolicyVersion,
    });
    await safetyStore.markReported(category, entryId);
    if (publicActorId == null) {
      await safetyStore.hide(category, entryId);
    } else {
      await safetyStore.hideActor(publicActorId, displayName);
    }
    return result['reported'] == true;
  }
}
