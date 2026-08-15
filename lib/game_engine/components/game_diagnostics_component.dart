import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

typedef DiagnosticsTextProvider = String Function(
  double fps,
  double averageFrameMilliseconds,
);

/// Flame-rendered diagnostics so frame statistics do not rebuild Flutter UI.
class GameDiagnosticsComponent extends TextComponent {
  GameDiagnosticsComponent({required this.textProvider})
      : super(
          text: 'FPS --',
          position: Vector2(8, 8),
          priority: 1000,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFFD8F3FF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        );

  static const double refreshInterval = 0.25;
  final DiagnosticsTextProvider textProvider;
  double _elapsed = 0;
  int _frames = 0;

  @override
  void update(double dt) {
    _elapsed += dt;
    _frames++;
    if (_elapsed < refreshInterval) return;
    final fps = _frames / _elapsed;
    final averageFrameMilliseconds = _elapsed * 1000 / _frames;
    text = textProvider(fps, averageFrameMilliseconds);
    _elapsed = 0;
    _frames = 0;
  }
}
