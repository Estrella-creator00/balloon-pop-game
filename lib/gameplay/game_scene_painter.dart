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

  @override
  void paint(Canvas canvas, Size size) {
    for (final balloon in renderState.basicBalloons) {
      final visualSize = Size(balloon.size, balloon.size + 26);
      var drawing = _drawings[balloon.id];
      if (drawing == null || !drawing.matches(visualSize, balloon.color)) {
        drawing = BasicBalloonDrawing.forBalloon(visualSize, balloon.color);
        _drawings[balloon.id] = drawing;
      }
      canvas
        ..save()
        ..translate(balloon.position.dx, balloon.position.dy);
      drawing.draw(canvas);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant GameScenePainter<T> oldDelegate) =>
      !identical(oldDelegate.renderState, renderState);
}
