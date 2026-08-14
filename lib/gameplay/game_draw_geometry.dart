import 'package:flutter/material.dart';

import 'game_sprite_cache.dart';

bool usesStaticSpriteFastPath({
  Offset offset = Offset.zero,
  double rotation = 0,
  double scale = 1,
}) =>
    offset == Offset.zero && rotation == 0 && scale == 1;

class SpriteBalloonDrawing {
  SpriteBalloonDrawing({
    required this.path,
    required this.sprite,
    required this.size,
    required List<double>? colorMatrix,
    required List<double>? detailColorMatrix,
    required this.preserveMochiDetails,
    required this.opacity,
  })  : _colorMatrix =
            colorMatrix == null ? null : List<double>.of(colorMatrix),
        _detailColorMatrix = detailColorMatrix == null
            ? null
            : List<double>.of(detailColorMatrix),
        _destination = _containRect(sprite.sourceRect.size, size),
        _bodyPaint = Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Colors.white.withValues(alpha: opacity)
          ..colorFilter =
              colorMatrix == null ? null : ColorFilter.matrix(colorMatrix),
        _detailPaint = Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Colors.white.withValues(alpha: opacity)
          ..colorFilter = detailColorMatrix == null
              ? null
              : ColorFilter.matrix(detailColorMatrix) {
    _detailClip = _mochiDetailPath(_destination);
  }

  final String path;
  final CachedGameSprite sprite;
  final Size size;
  final List<double>? _colorMatrix;
  final List<double>? _detailColorMatrix;
  final bool preserveMochiDetails;
  final double opacity;
  final Rect _destination;
  final Paint _bodyPaint;
  final Paint _detailPaint;
  late final Path _detailClip;

  bool matches(
    String path,
    CachedGameSprite sprite,
    Size size,
    List<double>? colorMatrix,
    List<double>? detailColorMatrix,
    bool preserveMochiDetails,
    double opacity,
  ) =>
      this.path == path &&
      identical(this.sprite, sprite) &&
      this.size == size &&
      _matrixEquals(_colorMatrix, colorMatrix) &&
      _matrixEquals(_detailColorMatrix, detailColorMatrix) &&
      this.preserveMochiDetails == preserveMochiDetails &&
      this.opacity == opacity;

  void draw(
    Canvas canvas, {
    Offset offset = Offset.zero,
    double rotation = 0,
    double scale = 1,
  }) {
    if (usesStaticSpriteFastPath(
      offset: offset,
      rotation: rotation,
      scale: scale,
    )) {
      canvas.drawImageRect(
        sprite.image,
        sprite.sourceRect,
        _destination,
        _bodyPaint,
      );
      if (preserveMochiDetails) {
        canvas
          ..save()
          ..clipPath(_detailClip)
          ..drawImageRect(
            sprite.image,
            sprite.sourceRect,
            _destination,
            _detailPaint,
          )
          ..restore();
      }
      return;
    }
    final center = size.center(offset);
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(rotation)
      ..scale(scale)
      ..translate(-center.dx, -center.dy)
      ..drawImageRect(
          sprite.image, sprite.sourceRect, _destination, _bodyPaint);
    if (preserveMochiDetails) {
      canvas
        ..save()
        ..clipPath(_detailClip)
        ..drawImageRect(
          sprite.image,
          sprite.sourceRect,
          _destination,
          _detailPaint,
        )
        ..restore();
    }
    canvas.restore();
  }
}

Rect _containRect(Size source, Size target) {
  final scale = (target.width / source.width).clamp(
    0.0,
    target.height / source.height,
  );
  final fitted = Size(source.width * scale, source.height * scale);
  return Offset(
        (target.width - fitted.width) / 2,
        (target.height - fitted.height) / 2,
      ) &
      fitted;
}

Path _mochiDetailPath(Rect rect) {
  Rect relative(double left, double top, double width, double height) =>
      Rect.fromLTWH(
        rect.left + rect.width * left,
        rect.top + rect.height * top,
        rect.width * width,
        rect.height * height,
      );
  return Path()
    ..addOval(relative(0.33, 0.52, 0.08, 0.09))
    ..addOval(relative(0.59, 0.52, 0.08, 0.09))
    ..addPolygon(<Offset>[
      Offset(rect.left + rect.width * 0.47, rect.top + rect.height * 0.59),
      Offset(rect.left + rect.width * 0.53, rect.top + rect.height * 0.59),
      Offset(rect.left + rect.width * 0.50, rect.top + rect.height * 0.63),
    ], true);
}

bool _matrixEquals(List<double>? a, List<double>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

class BasicBalloonDrawing {
  BasicBalloonDrawing._(Size size, Color color, double opacity)
      : _size = size,
        _color = color,
        _opacity = opacity,
        _balloonHeight = size.height - 26,
        _body = Rect.fromLTWH(3, 0, size.width - 6, size.height - 35) {
    _shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    _bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.42),
        radius: 0.88,
        colors: [
          _withOpacity(Color.lerp(color, Colors.white, 0.40)!, opacity),
          _withOpacity(color, opacity),
          _withOpacity(Color.lerp(color, Colors.black, 0.24)!, opacity),
        ],
        stops: const [0, 0.60, 1],
      ).createShader(_body);
    _outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    _shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.70 * opacity);
    _shineDotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95 * opacity);
    _knotPaint = Paint()..color = _withOpacity(color, opacity);
    _stringPaint = Paint()
      ..color = const Color(0xFF666666).withValues(alpha: opacity)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    _knot = Path()
      ..moveTo(size.width / 2, _balloonHeight - 11)
      ..lineTo(size.width / 2 - 8, _balloonHeight + 5)
      ..lineTo(size.width / 2 + 8, _balloonHeight + 5)
      ..close();
    _string = Path()
      ..moveTo(size.width / 2, _balloonHeight + 5)
      ..quadraticBezierTo(
        size.width * 0.68,
        _balloonHeight + 15,
        size.width * 0.47,
        size.height,
      );
  }

  factory BasicBalloonDrawing.forBalloon(
    Size size,
    Color color, {
    double opacity = 1,
  }) =>
      BasicBalloonDrawing._(size, color, opacity);

  final Size _size;
  final Color _color;
  final double _opacity;
  final double _balloonHeight;
  final Rect _body;
  late final Paint _shadowPaint;
  late final Paint _bodyPaint;
  late final Paint _outlinePaint;
  late final Paint _shinePaint;
  late final Paint _shineDotPaint;
  late final Paint _knotPaint;
  late final Paint _stringPaint;
  late final Path _knot;
  late final Path _string;

  bool matches(Size size, Color color, {double opacity = 1}) =>
      _size == size && _color == color && _opacity == opacity;

  void draw(Canvas canvas) {
    canvas.drawOval(_body.shift(const Offset(3, 6)), _shadowPaint);
    canvas.drawOval(_body, _bodyPaint);
    canvas.drawOval(_body, _outlinePaint);
    canvas.drawOval(
      Rect.fromLTWH(
        _size.width * 0.22,
        _balloonHeight * 0.15,
        _size.width * 0.17,
        _balloonHeight * 0.25,
      ),
      _shinePaint,
    );
    canvas.drawCircle(
      Offset(_size.width * 0.36, _balloonHeight * 0.13),
      _size.width * 0.035,
      _shineDotPaint,
    );
    canvas.drawPath(_knot, _knotPaint);
    canvas.drawPath(_string, _stringPaint);
  }
}

class BossBalloonDrawing {
  BossBalloonDrawing(
    Size size,
    Color color, {
    double opacity = 1,
    required int hp,
    required int maxHp,
    required bool showHealthBar,
  })  : _size = size,
        _color = color,
        _opacity = opacity,
        _hp = hp,
        _maxHp = maxHp,
        _showHealthBar = showHealthBar,
        _balloonHeight = size.height - 32,
        _body = Rect.fromLTWH(5, 0, size.width - 10, size.height - 46),
        _bodyPaint = Paint()..color = _withOpacity(color, opacity),
        _shinePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.48 * opacity),
        _barBackgroundPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8 * opacity),
        _barPaint = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: opacity) {
    _knot = Path()
      ..moveTo(size.width / 2, _balloonHeight - 14)
      ..lineTo(size.width / 2 - 16, _balloonHeight + 10)
      ..lineTo(size.width / 2 + 16, _balloonHeight + 10)
      ..close();
  }

  final Size _size;
  final Color _color;
  final double _opacity;
  final int _hp;
  final int _maxHp;
  final bool _showHealthBar;
  final double _balloonHeight;
  final Rect _body;
  final Paint _bodyPaint;
  final Paint _shinePaint;
  final Paint _barBackgroundPaint;
  final Paint _barPaint;
  late final Path _knot;

  bool matches(
    Size size,
    Color color, {
    required double opacity,
    required int hp,
    required int maxHp,
    required bool showHealthBar,
  }) =>
      _size == size &&
      _color == color &&
      _opacity == opacity &&
      _hp == hp &&
      _maxHp == maxHp &&
      _showHealthBar == showHealthBar;

  void draw(Canvas canvas) {
    canvas.drawOval(_body, _bodyPaint);
    canvas.drawOval(
      Rect.fromLTWH(
        _size.width * 0.22,
        _balloonHeight * 0.12,
        _size.width * 0.17,
        _balloonHeight * 0.24,
      ),
      _shinePaint,
    );
    canvas.drawPath(_knot, _bodyPaint);
    drawHealthBar(canvas);
  }

  void drawHealthBar(Canvas canvas) {
    if (!_showHealthBar) return;

    final barWidth = _size.width * 0.62;
    final barLeft = _size.width * 0.19;
    final barTop = _size.height - 16;
    final radius = const Radius.circular(8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, barWidth, 11),
        radius,
      ),
      _barBackgroundPaint,
    );
    final fraction = _maxHp <= 0 ? 0.0 : (_hp / _maxHp).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, barWidth * fraction, 11),
        radius,
      ),
      _barPaint,
    );
  }
}

Color _withOpacity(Color color, double opacity) =>
    color.withValues(alpha: color.a * opacity);

void drawBasicBalloon(
  Canvas canvas,
  Size size,
  Color color, {
  BasicBalloonDrawing? drawing,
}) {
  final resolved = drawing != null && drawing.matches(size, color)
      ? drawing
      : BasicBalloonDrawing.forBalloon(size, color);
  resolved.draw(canvas);
}
