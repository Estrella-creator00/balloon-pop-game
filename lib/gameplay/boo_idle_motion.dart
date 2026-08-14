import 'dart:math';
import 'dart:typed_data';

/// Shared lookup used by BOO render views instead of evaluating trigonometric
/// functions for every balloon on every gameplay frame.
class BooIdleMotion {
  BooIdleMotion._();

  static const int sampleCount = 1024;
  static const double _turn = pi * 2;
  static const double _samplesPerRadian = sampleCount / _turn;
  static final Float64List _sines = _buildSines();

  static Float64List _buildSines() {
    final values = Float64List(sampleCount);
    for (var index = 0; index < sampleCount; index++) {
      values[index] = sin(index * _turn / sampleCount);
    }
    return values;
  }

  static void prepare() {
    _sines;
  }

  static double sinAt(double radians) {
    final sample = radians * _samplesPerRadian;
    final lower = sample.floor();
    final fraction = sample - lower;
    final lowerIndex = lower % sampleCount;
    final upperIndex = (lowerIndex + 1) % sampleCount;
    return _sines[lowerIndex] +
        (_sines[upperIndex] - _sines[lowerIndex]) * fraction;
  }

  static double cosAt(double radians) => sinAt(radians + pi / 2);
}
