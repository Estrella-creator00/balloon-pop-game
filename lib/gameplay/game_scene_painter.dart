import 'package:flutter/material.dart';

import 'game_draw_geometry.dart';
import 'game_render_state.dart';

class GameScenePainter<T extends BasicBalloonRenderView> extends CustomPainter {
  GameScenePainter({
    required this.renderState,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final GameRenderState<T> renderState;
  final Map<int, BasicBalloonDrawing> _drawings = <int, BasicBalloonDrawing>{};
  final Map<int, BossBalloonDrawing> _bossDrawings =
      <int, BossBalloonDrawing>{};

  @override
  void paint(Canvas canvas, Size size) {
    for (final balloon in renderState.basicBalloons) {
      final visualSize = Size(balloon.size, balloon.size + 26);
      final displayColor = balloon.displayColor;
      final opacity = balloon.opacity;
      var drawing = _drawings[balloon.id];
      if (drawing == null ||
          !drawing.matches(
            visualSize,
            displayColor,
            opacity: opacity,
          )) {
        drawing = BasicBalloonDrawing.forBalloon(
          visualSize,
          displayColor,
          opacity: opacity,
        );
        _drawings[balloon.id] = drawing;
      }
      canvas
        ..save()
        ..translate(balloon.position.dx, balloon.position.dy);
      drawing.draw(canvas);
      canvas.restore();
    }
    for (final boss in renderState.bosses) {
      final visualSize = Size(boss.size, boss.size + 32);
      final displayColor = boss.displayColor;
      final opacity = boss.opacity;
      var drawing = _bossDrawings[boss.id];
      if (drawing == null ||
          !drawing.matches(
            visualSize,
            displayColor,
            opacity: opacity,
            hp: boss.hp,
            maxHp: boss.maxHp,
            showHealthBar: boss.showHealthBar,
          )) {
        drawing = BossBalloonDrawing(
          visualSize,
          displayColor,
          opacity: opacity,
          hp: boss.hp,
          maxHp: boss.maxHp,
          showHealthBar: boss.showHealthBar,
        );
        _bossDrawings[boss.id] = drawing;
      }
      canvas
        ..save()
        ..translate(boss.position.dx, boss.position.dy);
      drawing.draw(canvas);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant GameScenePainter<T> oldDelegate) =>
      !identical(oldDelegate.renderState, renderState);
}
