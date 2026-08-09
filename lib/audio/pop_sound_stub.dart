abstract final class PopSound {
  static bool enabled = true;
  static int basicPlayCount = 0;
  static int heartPlayCount = 0;
  static int bossExplosionPlayCount = 0;
  static int fakePlayCount = 0;
  static int themedPlayCount = 0;

  static void setEnabled(bool value) => enabled = value;

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

  static void resetDebug() {
    basicPlayCount = 0;
    heartPlayCount = 0;
    bossExplosionPlayCount = 0;
    fakePlayCount = 0;
    themedPlayCount = 0;
  }
}
