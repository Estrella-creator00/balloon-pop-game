abstract final class PopSound {
  static int basicPlayCount = 0;
  static int heartPlayCount = 0;
  static int bossExplosionPlayCount = 0;

  static void play() => basicPlayCount++;

  static void playHeart() => heartPlayCount++;

  static void playLightTap() {}

  static void playBossExplosion() => bossExplosionPlayCount++;

  static void resetDebug() {
    basicPlayCount = 0;
    heartPlayCount = 0;
    bossExplosionPlayCount = 0;
  }
}
