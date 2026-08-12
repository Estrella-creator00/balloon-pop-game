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
}
