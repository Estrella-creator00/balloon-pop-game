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
  String? get spriteAssetPath;
  List<double>? get spriteColorMatrix;
  List<double>? get spriteDetailColorMatrix;
  bool get preserveMochiDetails;
  Offset get visualOffset;
  double get visualRotation;
  double get visualScale;
  double get spriteOpacity;
}

abstract interface class BossBalloonRenderView {
  int get id;
  Offset get position;
  double get size;
  Color get displayColor;
  double get opacity;
  int get hp;
  int get maxHp;
  bool get showHealthBar;
  String? get spriteAssetPath;
  List<double>? get spriteColorMatrix;
  List<double>? get spriteDetailColorMatrix;
  bool get preserveMochiDetails;
  Offset get visualOffset;
  double get visualRotation;
  double get visualScale;
  double get spriteOpacity;
}

class GameRenderState<T extends BasicBalloonRenderView> {
  const GameRenderState({
    required this.basicBalloons,
    this.bosses = const <BossBalloonRenderView>[],
  });

  /// The existing mutable gameplay list, observed but never mutated here.
  final List<T> basicBalloons;
  final List<BossBalloonRenderView> bosses;
}
