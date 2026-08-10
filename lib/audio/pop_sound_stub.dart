abstract final class PopSound {
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
  static String? lastAssetPath;

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

  static void playAsset(String assetPath) {
    if (!enabled) return;
    assetPlayCount++;
    lastAssetPath = assetPath;
  }

  static void resetDebug() {
    basicPlayCount = 0;
    heartPlayCount = 0;
    bossExplosionPlayCount = 0;
    fakePlayCount = 0;
    themedPlayCount = 0;
    assetPlayCount = 0;
    lastAssetPath = null;
  }
}
