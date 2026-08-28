abstract final class PopSound {
  static const int gameplayVoiceCount = 8;
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
  static final Set<String> _preparedGameplayAssets = <String>{};

  static int get preparedGameplayAssetCount => _preparedGameplayAssets.length;
  static int get activeGameplayVoiceCount =>
      _preparedGameplayAssets.length * gameplayVoiceCount;

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
    if (_preparedGameplayAssets.add(assetPath)) gameplayAssetPrepareCount++;
    lastPreparedAssetPath = assetPath;
  }

  static void playGameplayAsset(String assetPath) {
    if (!enabled) return;
    if (!_preparedGameplayAssets.contains(assetPath)) return;
    gameplayAssetPlayCount++;
    lastAssetPath = assetPath;
  }

  static void releaseGameplayAsset(String assetPath) {
    _preparedGameplayAssets.remove(assetPath);
  }

  static void pauseGameplayAssets(Iterable<String> assetPaths) {
    if (assetPaths.any(_preparedGameplayAssets.contains)) {
      gameplayAssetPauseCount++;
    }
  }

  static void releaseGameplayAssets(Iterable<String> assetPaths) {
    _preparedGameplayAssets.removeAll(assetPaths.toSet());
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
    lastAssetPath = null;
    lastPreparedAssetPath = null;
    _preparedGameplayAssets.clear();
  }
}
