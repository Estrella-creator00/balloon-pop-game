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
    extends StatefulWidget {
  const PersistentGameCanvas({
    super.key,
    required this.renderState,
    required this.frameListenable,
    required this.onPointerDown,
  });

  final GameRenderState<T> renderState;
  final Listenable frameListenable;
  final PointerDownEventListener onPointerDown;

  @override
  State<PersistentGameCanvas<T>> createState() =>
      _PersistentGameCanvasState<T>();
}

class _PersistentGameCanvasState<T extends BasicBalloonRenderView>
    extends State<PersistentGameCanvas<T>> {
  final Set<int> _activePointers = <int>{};

  void _handlePointerDown(PointerDownEvent event) {
    if (!_activePointers.add(event.pointer)) return;
    widget.onPointerDown(event);
  }

  void _handlePointerEnd(PointerEvent event) {
    _activePointers.remove(event.pointer);
  }

  @override
  Widget build(BuildContext context) => Listener(
        key: const ValueKey('canvas-playfield-hit-surface'),
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerEnd,
        onPointerCancel: _handlePointerEnd,
        child: RepaintBoundary(
          key: const ValueKey('canvas-playfield-boundary'),
          child: CustomPaint(
            key: const ValueKey('canvas-playfield-painter'),
            painter: GameScenePainter<T>(
              renderState: widget.renderState,
              repaint: widget.frameListenable,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
}
