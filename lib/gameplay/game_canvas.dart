import 'package:flutter/material.dart';

import 'game_render_state.dart';
import 'game_scene_painter.dart';

enum GameplayRendererMode { legacy, canvasPhase1 }

/// One-line rollback switch for production. Tests may inject either mode.
const defaultGameplayRendererMode = GameplayRendererMode.canvasPhase1;

bool phase1CanvasInputEnabled({
  required bool isPlaying,
  required bool canvasActive,
}) =>
    isPlaying && canvasActive;

class PersistentGameCanvas<T extends BasicBalloonRenderView>
    extends StatelessWidget {
  const PersistentGameCanvas({
    super.key,
    required this.renderState,
    required this.frameListenable,
    required this.onTapUp,
  });

  final GameRenderState<T> renderState;
  final Listenable frameListenable;
  final GestureTapUpCallback onTapUp;

  @override
  Widget build(BuildContext context) => GestureDetector(
        key: const ValueKey('canvas-playfield-hit-surface'),
        behavior: HitTestBehavior.translucent,
        onTapUp: onTapUp,
        child: RepaintBoundary(
          key: const ValueKey('canvas-playfield-boundary'),
          child: CustomPaint(
            key: const ValueKey('canvas-playfield-painter'),
            painter: GameScenePainter<T>(
              renderState: renderState,
              repaint: frameListenable,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
}
