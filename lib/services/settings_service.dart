import 'dart:async';

import '../audio/game_bgm.dart';
import '../audio/pop_sound.dart';
import '../storage/progress_storage.dart';
import '../ranking/ranking_nickname.dart';
import 'haptic_service.dart';

/// Shared local player/settings state for SET-01 and future ranking onboarding.
abstract final class SettingsService {
  static const int minNicknameLength = RankingNickname.minimumLength;
  static const int maxNicknameLength = RankingNickname.maximumLength;

  static String? get nickname => ProgressStorage.nickname();
  static bool get nicknameOnboardingCompleted =>
      ProgressStorage.nicknameOnboardingCompleted();
  static bool get soundEnabled => ProgressStorage.soundEnabled();
  static bool get hapticEnabled => ProgressStorage.hapticEnabled();

  static String? normalizeNickname(String input) =>
      RankingNickname.normalize(input);

  static bool saveNickname(String input) {
    final normalized = normalizeNickname(input);
    if (normalized == null) return false;
    ProgressStorage.setNickname(normalized);
    return true;
  }

  /// Saves the shared nickname and marks ON-01 complete without touching any
  /// existing game, purchase, coin, or preference data.
  static bool completeNicknameOnboarding(String input) {
    if (!saveNickname(input)) return false;
    ProgressStorage.setNicknameOnboardingCompleted(true);
    return true;
  }

  static void setSoundEnabled(bool enabled) {
    ProgressStorage.setSoundEnabled(enabled);
    PopSound.setEnabled(enabled);
    unawaited(GameBgm.setEnabled(enabled));
  }

  static void setHapticEnabled(bool enabled) {
    ProgressStorage.setHapticEnabled(enabled);
    HapticService.setEnabled(enabled);
  }

  /// Applies persisted preferences to the runtime service gates at app start.
  static void applyStoredPreferences() {
    PopSound.setEnabled(soundEnabled);
    unawaited(GameBgm.setEnabled(soundEnabled));
    HapticService.setEnabled(hapticEnabled);
  }

  /// Clears every local game value through the existing storage owner.
  static void resetAllData() {
    ProgressStorage.clear();
    applyStoredPreferences();
  }
}
