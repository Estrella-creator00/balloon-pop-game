import 'package:flutter/material.dart';

import 'game_render_state.dart';

abstract final class GameHitTester {
  static Rect basicBalloonBounds(BasicBalloonRenderView balloon) =>
      Rect.fromLTWH(
        balloon.position.dx,
        balloon.position.dy,
        balloon.size,
        balloon.size + 26,
      );

  /// Matches Stack hit testing: later children are painted and hit-tested on
  /// top of earlier children.
  static T? topmostBasicBalloonAt<T extends BasicBalloonRenderView>(
    List<T> balloons,
    Offset point,
  ) {
    for (var index = balloons.length - 1; index >= 0; index--) {
      final balloon = balloons[index];
      if (basicBalloonBounds(balloon).contains(point)) return balloon;
    }
    return null;
  }

  static Rect bossBounds(BossBalloonRenderView boss) => Rect.fromLTWH(
        boss.position.dx,
        boss.position.dy,
        boss.size,
        boss.size + 32,
      );

  static T? topmostBossAt<T extends BossBalloonRenderView>(
    List<T> bosses,
    Offset point,
  ) {
    for (var index = bosses.length - 1; index >= 0; index--) {
      final boss = bosses[index];
      if (bossBounds(boss).contains(point)) return boss;
    }
    return null;
  }
}
