import '../audio/pop_sound.dart';
import '../storage/progress_storage.dart';
import 'haptic_service.dart';

/// Shared local player/settings state for SET-01 and future ranking onboarding.
abstract final class SettingsService {
  static const int minNicknameLength = 2;
  static const int maxNicknameLength = 10;

  static String? get nickname => ProgressStorage.nickname();
  static bool get soundEnabled => ProgressStorage.soundEnabled();
  static bool get hapticEnabled => ProgressStorage.hapticEnabled();

  static String? normalizeNickname(String input) {
    final normalized = input.trim();
    if (normalized.length < minNicknameLength ||
        normalized.length > maxNicknameLength) {
      return null;
    }
    return normalized;
  }

  static bool saveNickname(String input) {
    final normalized = normalizeNickname(input);
    if (normalized == null) return false;
    ProgressStorage.setNickname(normalized);
    return true;
  }

  static void setSoundEnabled(bool enabled) {
    ProgressStorage.setSoundEnabled(enabled);
    PopSound.setEnabled(enabled);
  }

  static void setHapticEnabled(bool enabled) {
    ProgressStorage.setHapticEnabled(enabled);
    HapticService.setEnabled(enabled);
  }

  /// Applies persisted preferences to the runtime service gates at app start.
  static void applyStoredPreferences() {
    PopSound.setEnabled(soundEnabled);
    HapticService.setEnabled(hapticEnabled);
  }

  /// Clears every local game value through the existing storage owner.
  static void resetAllData() {
    ProgressStorage.clear();
    applyStoredPreferences();
  }
}
