abstract interface class ProgressStorageBackend {
  Set<String> get keys;

  Object? get(String key);

  Future<void> setBool(String key, bool value);

  Future<void> setInt(String key, int value);

  Future<void> setString(String key, String value);

  Future<void> clear();
}

typedef ProgressStorageBackendFactory = Future<ProgressStorageBackend>
    Function();

abstract final class ProgressStorageKeys {
  static const secondSectionUnlocked =
      'balloon_pop_game_second_section_unlocked';
  static const nextPlayableStage = 'poppop_next_playable_stage';
  static const bestScore = 'poppop_best_score';
  static const lastScore = 'poppop_last_score';
  static const coinBalance = 'poppop_coin_balance';
  static const ownedProductIds = 'poppop_owned_product_ids';
  static const equippedProductIds = 'poppop_equipped_product_ids';
  static const nickname = 'poppop_nickname';
  static const nicknameOnboardingCompleted =
      'poppop_nickname_onboarding_completed';
  static const soundEnabled = 'poppop_sound_enabled';
  static const hapticEnabled = 'poppop_haptic_enabled';
  static const endlessBestScore = 'poppop_endless_best';
  static const endlessLastScore = 'poppop_endless_last';
  static const endlessIntroSeen = 'poppop_endless_intro_seen';

  static const all = <String>{
    secondSectionUnlocked,
    nextPlayableStage,
    bestScore,
    lastScore,
    coinBalance,
    ownedProductIds,
    equippedProductIds,
    nickname,
    nicknameOnboardingCompleted,
    soundEnabled,
    hapticEnabled,
    endlessBestScore,
    endlessLastScore,
    endlessIntroSeen,
  };
}
