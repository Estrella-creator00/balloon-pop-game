abstract final class PopSound {
  static const int gameplayVoiceCount = 4;
  static const int rapidGameplayVoiceCount = 8;
  static const uiClickAssetPath = 'assets/sounds/ui_click.mp3.mp3';
  static const bossAppearAssetPath = 'assets/sounds/boss_appear.mp3.mp3';
  static const bossClearAssetPath = 'assets/sounds/boss_clear.mp3.mp3';
  static const shopPurchaseAssetPath = 'assets/sounds/shop_purchase.mp3.mp3';
  static const shopEquipAssetPath = 'assets/sounds/shop_equip.mp3.mp3';

  static bool enabled = true;
  static int basicPlayCount = 0;
  static int heartPlayCount = 0;
  static int bossExplosionPlayCount = 0;
  static int fakePlayCount = 0;
  static int themedPlayCount = 0;
  static int assetPlayCount = 0;
  static int polyphonicAssetPlayCount = 0;
  static int gameplayAssetPrepareCount = 0;
  static int gameplayAssetPlayCount = 0;
  static int gameplayAssetPauseCount = 0;
  static String? lastAssetPath;
  static String? lastPreparedAssetPath;
  static final Map<String, int> _preparedGameplayAssets = <String, int>{};
  static final Map<String, int> _playingGameplayVoices = <String, int>{};
  static int gameplayPendingPrepareCount = 0;

  static int get preparedGameplayAssetCount => _preparedGameplayAssets.length;
  static int get activeGameplayVoiceCount =>
      _preparedGameplayAssets.values.fold(0, (sum, count) => sum + count);
  static int get playingGameplayVoiceCount =>
      _playingGameplayVoices.values.fold(0, (sum, count) => sum + count);
  static int get readyGameplayAssetCount => _preparedGameplayAssets.length;
  static int get gameplayListenerCount => 0;

  static int gameplayVoiceCountForAsset(String assetPath) =>
      assetPath.endsWith('wari_watermelon_bite.mp3.mp3') ||
              assetPath.endsWith('muggy_break.mp3.mp3')
          ? rapidGameplayVoiceCount
          : gameplayVoiceCount;

  static void setEnabled(bool value) => enabled = value;

  static void preloadSharedAssets() {}

  static void playUiClick() => playAsset(uiClickAssetPath);
  static void playBossAppear() => playAsset(bossAppearAssetPath);
  static void playBossClear() => playAsset(bossClearAssetPath);
  static void playShopPurchase() => playAsset(shopPurchaseAssetPath);
  static void playShopEquip() => playAsset(shopEquipAssetPath);

  static void play() {
    if (enabled) basicPlayCount++;
  }

  static void playHeart() {
    if (enabled) heartPlayCount++;
  }

  static void playLightTap() {}

  static void playFake() {
    if (enabled) fakePlayCount++;
  }

  static void playBossExplosion() {
    if (enabled) bossExplosionPlayCount++;
  }

  static void playGhost() {
    if (enabled) themedPlayCount++;
  }

  static void playCrackle() {
    if (enabled) themedPlayCount++;
  }

  static void playCrystal() {
    if (enabled) themedPlayCount++;
  }

  static void playCream() {
    if (enabled) themedPlayCount++;
  }

  static void preloadAsset(String assetPath) {}

  static Future<void> prepareGameplayAsset(String assetPath) async {
    if (!enabled || _preparedGameplayAssets.containsKey(assetPath)) return;
    gameplayPendingPrepareCount++;
    _preparedGameplayAssets[assetPath] = gameplayVoiceCountForAsset(assetPath);
    gameplayAssetPrepareCount++;
    lastPreparedAssetPath = assetPath;
    gameplayPendingPrepareCount--;
  }

  static void playGameplayAsset(String assetPath) {
    if (!enabled) return;
    final voiceCount = _preparedGameplayAssets[assetPath];
    if (voiceCount == null) return;
    gameplayAssetPlayCount++;
    _playingGameplayVoices[assetPath] =
        ((_playingGameplayVoices[assetPath] ?? 0) + 1).clamp(0, voiceCount);
    lastAssetPath = assetPath;
  }

  static void releaseGameplayAsset(String assetPath) {
    _preparedGameplayAssets.remove(assetPath);
    _playingGameplayVoices.remove(assetPath);
  }

  static void pauseGameplayAssets(Iterable<String> assetPaths) {
    final paths = assetPaths.toSet();
    if (paths.any(_preparedGameplayAssets.containsKey)) {
      gameplayAssetPauseCount++;
    }
    for (final path in paths) {
      _playingGameplayVoices.remove(path);
    }
  }

  static void releaseGameplayAssets(Iterable<String> assetPaths) {
    for (final assetPath in assetPaths.toSet()) {
      releaseGameplayAsset(assetPath);
    }
  }

  static void preloadPolyphonicAsset(
    String assetPath, {
    int voiceCount = 12,
  }) {}

  static void playAsset(String assetPath) {
    if (!enabled) return;
    assetPlayCount++;
    lastAssetPath = assetPath;
  }

  static void playAssetPolyphonic(String assetPath) {
    if (!enabled) return;
    polyphonicAssetPlayCount++;
    lastAssetPath = assetPath;
  }

  static void resetDebug() {
    basicPlayCount = 0;
    heartPlayCount = 0;
    bossExplosionPlayCount = 0;
    fakePlayCount = 0;
    themedPlayCount = 0;
    assetPlayCount = 0;
    polyphonicAssetPlayCount = 0;
    gameplayAssetPrepareCount = 0;
    gameplayAssetPlayCount = 0;
    gameplayAssetPauseCount = 0;
    gameplayPendingPrepareCount = 0;
    lastAssetPath = null;
    lastPreparedAssetPath = null;
    _preparedGameplayAssets.clear();
    _playingGameplayVoices.clear();
  }
}
