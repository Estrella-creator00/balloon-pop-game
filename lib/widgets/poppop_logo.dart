import 'package:flutter/material.dart';

abstract final class PoppopLogoStyle {
  static const fontFamily = 'Arial Rounded MT Bold';
  static const fontFamilyFallback = <String>['Arial', 'sans-serif'];
  static const goldColors = <Color>[
    Color(0xFFFFFF72),
    Color(0xFFFFC400),
    Color(0xFFFF8A00),
  ];
  static const pinkColors = <Color>[
    Color(0xFFFFB5C2),
    Color(0xFFFF5275),
    Color(0xFFE91E63),
  ];

  static TextStyle base({
    required double fontSize,
    required double letterSpacing,
    double height = 1,
  }) =>
      TextStyle(
        height: height,
        letterSpacing: letterSpacing,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
      );
}

/// Compact gameplay wordmark using the same typeface, depth, outline, and
/// gold/pink palettes as the production home logo.
class PoppopCompactLogo extends StatelessWidget {
  const PoppopCompactLogo({super.key, this.fontSize = 11});

  final double fontSize;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'POPPOP',
        image: true,
        excludeSemantics: true,
        child: SizedBox(
          key: const ValueKey('game-poppop-logo'),
          height: fontSize * 1.65,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LogoSegment(
                text: 'POP',
                colors: PoppopLogoStyle.goldColors,
                depthColor: const Color(0xFFD96500),
                fontSize: fontSize,
              ),
              _LogoSegment(
                text: 'POP',
                colors: PoppopLogoStyle.pinkColors,
                depthColor: const Color(0xFFAD174F),
                fontSize: fontSize,
              ),
            ],
          ),
        ),
      );
}

class _LogoSegment extends StatelessWidget {
  const _LogoSegment({
    required this.text,
    required this.colors,
    required this.depthColor,
    required this.fontSize,
  });

  final String text;
  final List<Color> colors;
  final Color depthColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = PoppopLogoStyle.base(
      fontSize: fontSize,
      letterSpacing: -fontSize * 0.055,
      height: .9,
    );
    final width = fontSize * 2.05;
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(fontSize * .08, fontSize * .14),
            child: Text(text, style: style.copyWith(color: depthColor)),
          ),
          Text(
            text,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = fontSize * .22
                ..strokeJoin = StrokeJoin.round
                ..color = Colors.white,
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
              stops: const [0, .55, 1],
            ).createShader(bounds),
            child: Text(text, style: style.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
