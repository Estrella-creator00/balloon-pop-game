abstract final class PopSound {
  static int heartPlayCount = 0;

  static void play() {}

  static void playHeart() => heartPlayCount++;

  static void playLightTap() {}

  static void playBossExplosion() {}

  static void resetDebug() => heartPlayCount = 0;
}
