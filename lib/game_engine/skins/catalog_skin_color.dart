import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' show HSLColor;

import '../../balloon_skin_catalog.dart';

const double _fakeSaturation = 0.78;
const double _fakeBrightness = 0.97;

List<double> catalogSpriteColorMatrix(
  BalloonSkinDefinition definition,
  Color color, {
  required bool fake,
}) {
  final base = switch (definition.imageColorMode) {
    BalloonImageColorMode.original => _identityMatrix,
    BalloonImageColorMode.grayscaleTint => _grayscaleTint(color),
    BalloonImageColorMode.hueShift => _hueShift(definition, color),
  };
  return fake ? _compose(fakeSpriteToneMatrix, base) : base;
}

bool catalogSpriteNeedsColorFilter(
  BalloonSkinDefinition definition,
  Color color, {
  required bool fake,
}) {
  if (fake) return true;
  if (definition.imageColorMode == BalloonImageColorMode.original) return false;
  return definition.previewColor.toARGB32() != color.toARGB32();
}

final List<double> fakeSpriteToneMatrix = _saturationBrightnessMatrix(
  saturation: _fakeSaturation,
  brightness: _fakeBrightness,
);

const List<double> _identityMatrix = <double>[
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

List<double> _grayscaleTint(Color color) {
  final red = color.r;
  final green = color.g;
  final blue = color.b;
  return <double>[
    0.213 * red,
    0.715 * red,
    0.072 * red,
    0,
    0,
    0.213 * green,
    0.715 * green,
    0.072 * green,
    0,
    0,
    0.213 * blue,
    0.715 * blue,
    0.072 * blue,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

List<double> _hueShift(BalloonSkinDefinition definition, Color color) {
  final sourceHue = HSLColor.fromColor(definition.previewColor).hue;
  final targetHue = HSLColor.fromColor(color).hue;
  final radians = ((targetHue - sourceHue + 540) % 360 - 180) * math.pi / 180;
  final cosine = math.cos(radians);
  final sine = math.sin(radians);
  return <double>[
    0.213 + cosine * 0.787 - sine * 0.213,
    0.715 - cosine * 0.715 - sine * 0.715,
    0.072 - cosine * 0.072 + sine * 0.928,
    0,
    0,
    0.213 - cosine * 0.213 + sine * 0.143,
    0.715 + cosine * 0.285 + sine * 0.140,
    0.072 - cosine * 0.072 - sine * 0.283,
    0,
    0,
    0.213 - cosine * 0.213 - sine * 0.787,
    0.715 - cosine * 0.715 + sine * 0.715,
    0.072 + cosine * 0.928 + sine * 0.072,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

List<double> _saturationBrightnessMatrix({
  required double saturation,
  required double brightness,
}) {
  final inverse = 1 - saturation;
  final red = 0.213 * inverse;
  final green = 0.715 * inverse;
  final blue = 0.072 * inverse;
  return <double>[
    (red + saturation) * brightness,
    green * brightness,
    blue * brightness,
    0,
    0,
    red * brightness,
    (green + saturation) * brightness,
    blue * brightness,
    0,
    0,
    red * brightness,
    green * brightness,
    (blue + saturation) * brightness,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

List<double> _compose(List<double> after, List<double> before) {
  final result = List<double>.filled(20, 0);
  for (var row = 0; row < 4; row++) {
    for (var column = 0; column < 4; column++) {
      for (var index = 0; index < 4; index++) {
        result[row * 5 + column] +=
            after[row * 5 + index] * before[index * 5 + column];
      }
    }
    result[row * 5 + 4] = after[row * 5 + 4];
    for (var index = 0; index < 4; index++) {
      result[row * 5 + 4] += after[row * 5 + index] * before[index * 5 + 4];
    }
  }
  return result;
}
