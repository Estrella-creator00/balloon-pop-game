import 'dart:ui';

import 'package:flame/components.dart';

class LegendaryBackgroundComponent extends Component {
  LegendaryBackgroundComponent(this.image) : super(priority: -1000);

  final Image image;
  final Paint _paint = Paint()..filterQuality = FilterQuality.medium;
  late final Rect _source = Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );
  Rect _destination = Rect.zero;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final sourceRatio = image.width / image.height;
    final viewportRatio = size.x / size.y;
    final width = sourceRatio > viewportRatio ? size.y * sourceRatio : size.x;
    final height = sourceRatio > viewportRatio ? size.y : size.x / sourceRatio;
    _destination = Rect.fromLTWH(
      (size.x - width) / 2,
      (size.y - height) / 2,
      width,
      height,
    );
  }

  @override
  void render(Canvas canvas) =>
      canvas.drawImageRect(image, _source, _destination, _paint);
}

class LegendaryBackgroundPulseComponent extends Component {
  LegendaryBackgroundPulseComponent({
    required this.image,
    required this.strength,
    required this.onFinished,
  }) : super(priority: -900);

  static const double lifetime = 0.24;

  final Image image;
  final double strength;
  final void Function(LegendaryBackgroundPulseComponent pulse) onFinished;
  final Paint _paint = Paint()..filterQuality = FilterQuality.low;
  late final Rect _source = Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );
  Rect _destination = Rect.zero;
  double _elapsed = 0;
  bool _finished = false;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final width = size.x * 0.59;
    final height = width * image.height / image.width;
    _destination = Rect.fromCenter(
      center: Offset(size.x * 0.5, size.y * 0.43),
      width: width,
      height: height,
    );
  }

  @override
  void update(double dt) {
    if (_finished) return;
    _elapsed += dt;
    if (_elapsed < lifetime) return;
    _finished = true;
    onFinished(this);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / lifetime).clamp(0.0, 1.0);
    _paint.color = Color.fromRGBO(255, 255, 255, (1 - progress) * strength);
    canvas.drawImageRect(image, _source, _destination, _paint);
  }
}
