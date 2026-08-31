import 'dart:ui' as ui;

abstract final class GemiFakeHologramSpec {
  static const ui.Color cyanRim = ui.Color(0xA66EF7FF);
  static const ui.Color magentaRim = ui.Color(0xA6FF6EC7);
  static const ui.Color upperBand = ui.Color(0xB875F8FF);
  static const ui.Color lowerBand = ui.Color(0xA8FF89D2);
  static const double rimOffsetFraction = .018;
  static const double bodyReinforcementOpacity = .38;
  static const List<double> projectionBandCenters = <double>[.36, .54];
  static const double projectionBandThicknessFraction = .018;
  static const ui.BlendMode projectionMaskBlendMode = ui.BlendMode.dstIn;

  static double rimOffsetForWidth(double width) =>
      (width * rimOffsetFraction).clamp(3.0, 8.0).toDouble();

  static List<ui.Rect> projectionBands(ui.Size size) {
    final thickness =
        (size.height * projectionBandThicknessFraction).clamp(4.0, 14.0);
    return <ui.Rect>[
      for (final center in projectionBandCenters)
        ui.Rect.fromLTWH(
          0,
          size.height * center - thickness / 2,
          size.width,
          thickness,
        ),
    ];
  }
}

/// Produces one immutable GEMI Fake frame during profile preparation. The
/// gameplay render path still draws exactly one cached image per balloon.
abstract final class GemiFakeHologramComposer {
  static Future<ui.Image> compose({
    required ui.Image normal,
    required ui.Image fadedFake,
  }) async {
    assert(normal.width == fadedFake.width);
    assert(normal.height == fadedFake.height);
    final size = ui.Size(normal.width.toDouble(), normal.height.toDouble());
    final bounds = ui.Offset.zero & size;
    final rimOffset = GemiFakeHologramSpec.rimOffsetForWidth(size.width);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Draw two displaced silhouettes into an isolated layer, then remove the
    // centered silhouette so only restrained cyan/magenta edge echoes remain.
    canvas.saveLayer(bounds, ui.Paint());
    canvas
      ..drawImage(
        normal,
        ui.Offset(-rimOffset, 0),
        ui.Paint()
          ..colorFilter = const ui.ColorFilter.mode(
            GemiFakeHologramSpec.cyanRim,
            ui.BlendMode.srcIn,
          ),
      )
      ..drawImage(
        normal,
        ui.Offset(rimOffset, 0),
        ui.Paint()
          ..colorFilter = const ui.ColorFilter.mode(
            GemiFakeHologramSpec.magentaRim,
            ui.BlendMode.srcIn,
          ),
      )
      ..drawImage(
        normal,
        ui.Offset.zero,
        ui.Paint()..blendMode = ui.BlendMode.dstOut,
      )
      ..restore();

    // Preserve the existing faded Fake artwork while restoring enough of the
    // original facet color to remain readable against the crystal cave.
    canvas
      ..drawImage(fadedFake, ui.Offset.zero, ui.Paint())
      ..drawImage(
        normal,
        ui.Offset.zero,
        ui.Paint()
          ..color = ui.Color.fromRGBO(
            255,
            255,
            255,
            GemiFakeHologramSpec.bodyReinforcementOpacity,
          ),
      );

    // Build exactly two horizontal bands, then mask the layer with GEMI's
    // existing alpha silhouette. No line can appear in transparent pixels.
    canvas.saveLayer(bounds, ui.Paint());
    final bands = GemiFakeHologramSpec.projectionBands(size);
    canvas
      ..drawRect(bands[0], ui.Paint()..color = GemiFakeHologramSpec.upperBand)
      ..drawRect(bands[1], ui.Paint()..color = GemiFakeHologramSpec.lowerBand)
      ..drawImage(
        normal,
        ui.Offset.zero,
        ui.Paint()..blendMode = GemiFakeHologramSpec.projectionMaskBlendMode,
      )
      ..restore();

    final picture = recorder.endRecording();
    try {
      return await picture.toImage(normal.width, normal.height);
    } finally {
      picture.dispose();
    }
  }
}
