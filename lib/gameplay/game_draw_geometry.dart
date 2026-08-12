import 'package:flutter/material.dart';

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
