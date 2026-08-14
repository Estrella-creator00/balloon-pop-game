import 'package:flutter/material.dart';

import 'game_draw_geometry.dart';
import 'game_render_state.dart';
import 'game_sprite_cache.dart';

class GameScenePainter<T extends BasicBalloonRenderView> extends CustomPainter {
  GameScenePainter({
    required this.renderState,
    required this.spriteCache,
    required Listenable repaint,
  }) : super(repaint: Listenable.merge(<Listenable>[repaint, spriteCache]));

  final GameRenderState<T> renderState;
  final GameSpriteCache spriteCache;
  final Map<int, BasicBalloonDrawing> _drawings = <int, BasicBalloonDrawing>{};
  final Map<int, BossBalloonDrawing> _bossDrawings =
      <int, BossBalloonDrawing>{};
  final Map<int, SpriteBalloonDrawing> _spriteDrawings =
      <int, SpriteBalloonDrawing>{};

  @override
  void paint(Canvas canvas, Size size) {
    for (final balloon in renderState.basicBalloons) {
      final visualSize = Size(balloon.size, balloon.size + 26);
      final spritePath = balloon.spriteAssetPath;
      if (spritePath != null) {
        final sprite = spriteCache.spriteFor(spritePath);
        if (sprite == null) continue;
        final drawing = _spriteDrawingFor(
          balloon.id,
          spritePath,
          sprite,
          visualSize,
          balloon.spriteColorMatrix,
          balloon.spriteDetailColorMatrix,
          balloon.preserveMochiDetails,
          balloon.spriteOpacity,
        );
        final visualOffset = balloon.visualOffset;
        final visualRotation = balloon.visualRotation;
        final visualScale = balloon.visualScale;
        if (usesBooAnimatedSpriteFastPath(
          offset: visualOffset,
          scale: visualScale,
          forceAnimatedPath: balloon.useBooAnimatedSpritePath,
        )) {
          drawing.drawBooIdleAt(
            canvas,
            position: balloon.position,
            offset: visualOffset,
            rotation: visualRotation,
          );
          continue;
        }
        canvas
          ..save()
          ..translate(balloon.position.dx, balloon.position.dy);
        drawing.draw(
          canvas,
          offset: visualOffset,
          rotation: visualRotation,
          scale: visualScale,
        );
        canvas.restore();
        continue;
      }
      final displayColor = balloon.displayColor;
      final opacity = balloon.opacity;
      var drawing = _drawings[balloon.id];
      if (drawing == null ||
          !drawing.matches(
            visualSize,
            displayColor,
            opacity: opacity,
          )) {
        drawing = BasicBalloonDrawing.forBalloon(
          visualSize,
          displayColor,
          opacity: opacity,
        );
        _drawings[balloon.id] = drawing;
      }
      canvas
        ..save()
        ..translate(balloon.position.dx, balloon.position.dy);
      drawing.draw(canvas);
      canvas.restore();
    }
    for (final boss in renderState.bosses) {
      final visualSize = Size(boss.size, boss.size + 32);
      final spritePath = boss.spriteAssetPath;
      if (spritePath != null) {
        final sprite = spriteCache.spriteFor(
          spritePath,
          resolution: GameSpriteResolution.boss,
        );
        if (sprite == null) continue;
        final drawing = _spriteDrawingFor(
          -boss.id - 1,
          spritePath,
          sprite,
          Size(boss.size, boss.size),
          boss.spriteColorMatrix,
          boss.spriteDetailColorMatrix,
          boss.preserveMochiDetails,
          boss.spriteOpacity,
        );
        final visualOffset = boss.visualOffset;
        final visualRotation = boss.visualRotation;
        final visualScale = boss.visualScale;
        if (usesBooAnimatedSpriteFastPath(
          offset: visualOffset,
          scale: visualScale,
          forceAnimatedPath: boss.useBooAnimatedSpritePath,
        )) {
          drawing.drawBooIdleAt(
            canvas,
            position: boss.position,
            offset: visualOffset,
            rotation: visualRotation,
          );
          var bossDrawing = _bossDrawings[boss.id];
          if (bossDrawing == null ||
              !bossDrawing.matches(
                visualSize,
                Colors.transparent,
                opacity: boss.opacity,
                hp: boss.hp,
                maxHp: boss.maxHp,
                showHealthBar: boss.showHealthBar,
              )) {
            bossDrawing = BossBalloonDrawing(
              visualSize,
              Colors.transparent,
              opacity: boss.opacity,
              hp: boss.hp,
              maxHp: boss.maxHp,
              showHealthBar: boss.showHealthBar,
            );
            _bossDrawings[boss.id] = bossDrawing;
          }
          canvas
            ..save()
            ..translate(boss.position.dx, boss.position.dy);
          bossDrawing.drawHealthBar(canvas);
          canvas.restore();
          continue;
        }
        canvas
          ..save()
          ..translate(boss.position.dx, boss.position.dy);
        drawing.draw(
          canvas,
          offset: visualOffset,
          rotation: visualRotation,
          scale: visualScale,
        );
        var bossDrawing = _bossDrawings[boss.id];
        if (bossDrawing == null ||
            !bossDrawing.matches(
              visualSize,
              Colors.transparent,
              opacity: boss.opacity,
              hp: boss.hp,
              maxHp: boss.maxHp,
              showHealthBar: boss.showHealthBar,
            )) {
          bossDrawing = BossBalloonDrawing(
            visualSize,
            Colors.transparent,
            opacity: boss.opacity,
            hp: boss.hp,
            maxHp: boss.maxHp,
            showHealthBar: boss.showHealthBar,
          );
          _bossDrawings[boss.id] = bossDrawing;
        }
        bossDrawing.drawHealthBar(canvas);
        canvas.restore();
        continue;
      }
      final displayColor = boss.displayColor;
      final opacity = boss.opacity;
      var drawing = _bossDrawings[boss.id];
      if (drawing == null ||
          !drawing.matches(
            visualSize,
            displayColor,
            opacity: opacity,
            hp: boss.hp,
            maxHp: boss.maxHp,
            showHealthBar: boss.showHealthBar,
          )) {
        drawing = BossBalloonDrawing(
          visualSize,
          displayColor,
          opacity: opacity,
          hp: boss.hp,
          maxHp: boss.maxHp,
          showHealthBar: boss.showHealthBar,
        );
        _bossDrawings[boss.id] = drawing;
      }
      canvas
        ..save()
        ..translate(boss.position.dx, boss.position.dy);
      drawing.draw(canvas);
      canvas.restore();
    }
  }

  SpriteBalloonDrawing _spriteDrawingFor(
    int id,
    String path,
    CachedGameSprite sprite,
    Size size,
    List<double>? colorMatrix,
    List<double>? detailColorMatrix,
    bool preserveMochiDetails,
    double opacity,
  ) {
    var drawing = _spriteDrawings[id];
    if (drawing == null ||
        !drawing.matches(
          path,
          sprite,
          size,
          colorMatrix,
          detailColorMatrix,
          preserveMochiDetails,
          opacity,
        )) {
      drawing = SpriteBalloonDrawing(
        path: path,
        sprite: sprite,
        size: size,
        colorMatrix: colorMatrix,
        detailColorMatrix: detailColorMatrix,
        preserveMochiDetails: preserveMochiDetails,
        opacity: opacity,
      );
      _spriteDrawings[id] = drawing;
    }
    return drawing;
  }

  @override
  bool shouldRepaint(covariant GameScenePainter<T> oldDelegate) =>
      !identical(oldDelegate.renderState, renderState);
}
