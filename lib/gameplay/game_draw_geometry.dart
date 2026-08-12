import 'package:flutter/material.dart';

class BasicBalloonDrawing {
  BasicBalloonDrawing._(Size size, Color color)
      : _size = size,
        _color = color,
        _balloonHeight = size.height - 26,
        _body = Rect.fromLTWH(3, 0, size.width - 6, size.height - 35) {
    _shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    _bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.42),
        radius: 0.88,
        colors: [
          Color.lerp(color, Colors.white, 0.40)!,
          color,
          Color.lerp(color, Colors.black, 0.24)!,
        ],
        stops: const [0, 0.60, 1],
      ).createShader(_body);
    _outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    _shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.70);
    _shineDotPaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    _knotPaint = Paint()..color = color;
    _stringPaint = Paint()
      ..color = const Color(0xFF666666)
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

  factory BasicBalloonDrawing.forBalloon(Size size, Color color) =>
      BasicBalloonDrawing._(size, color);

  final Size _size;
  final Color _color;
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

  bool matches(Size size, Color color) => _size == size && _color == color;

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
