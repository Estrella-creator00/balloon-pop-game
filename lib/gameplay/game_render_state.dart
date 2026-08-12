import 'package:flutter/material.dart';

/// Read-only rendering contract implemented by the existing gameplay model.
///
/// The render state below keeps a reference to the original model list. It is
/// deliberately not a second source of gameplay truth.
abstract interface class BasicBalloonRenderView {
  int get id;
  Offset get position;
  Color get color;
  Color get displayColor;
  double get opacity;
  double get size;
}

class GameRenderState<T extends BasicBalloonRenderView> {
  const GameRenderState({required this.basicBalloons});

  /// The existing mutable gameplay list, observed but never mutated here.
  final List<T> basicBalloons;
}
