import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'poppop_logo.dart';

class GameHeaderData {
  const GameHeaderData({
    required this.stage,
    required this.score,
    required this.remaining,
    required this.secondsLeft,
    required this.controlsEnabled,
    this.stageLabel,
    this.scoreText,
    this.remainingText,
    this.timeText,
  });

  final int stage;
  final int score;
  final int remaining;
  final int secondsLeft;
  final bool controlsEnabled;
  final String? stageLabel;
  final String? scoreText;
  final String? remainingText;
  final String? timeText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameHeaderData &&
          stage == other.stage &&
          score == other.score &&
          remaining == other.remaining &&
          secondsLeft == other.secondsLeft &&
          controlsEnabled == other.controlsEnabled &&
          stageLabel == other.stageLabel &&
          scoreText == other.scoreText &&
          remainingText == other.remainingText &&
          timeText == other.timeText;

  @override
  int get hashCode => Object.hash(stage, score, remaining, secondsLeft,
      controlsEnabled, stageLabel, scoreText, remainingText, timeText);
}

class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.data,
    required this.onPause,
    required this.onEnd,
  });

  final ValueListenable<GameHeaderData> data;
  final VoidCallback onPause;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        key: const ValueKey('game-header-boundary'),
        child: ValueListenableBuilder<GameHeaderData>(
          valueListenable: data,
          builder: (context, value, _) => Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 92,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: PoppopCompactLogo(),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              value.stageLabel ??
                                  'STAGE ${value.stage.toString().padLeft(2, '0')}',
                              key: const ValueKey('game-stage-label'),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: const TextStyle(
                                color: Color(0xFF25385F),
                                fontSize: 20,
                                letterSpacing: 0.9,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Color(0xCCFFFFFF),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 92,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _controlButton(
                                  key: const ValueKey('pause-button'),
                                  label: '일시정지',
                                  icon: Icons.pause_rounded,
                                  onPressed:
                                      value.controlsEnabled ? onPause : null,
                                ),
                                const SizedBox(width: 4),
                                _controlButton(
                                  key: const ValueKey('end-button'),
                                  label: '끝내기',
                                  icon: Icons.logout_rounded,
                                  onPressed:
                                      value.controlsEnabled ? onEnd : null,
                                  isExit: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      key: const ValueKey('game-hud-panel'),
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xEFFFFFFF), Color(0xDDF4F1FF)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xE6FFFFFF),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x240D2940),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _HudMetric(
                            key: const ValueKey('hud-score'),
                            icon: Icons.star_rounded,
                            text: value.scoreText ?? '점수  ${value.score}',
                            color: const Color(0xFFE59A00),
                          ),
                          const _HudDivider(),
                          if (value.remainingText != '') ...[
                            _HudMetric(
                              key: const ValueKey('hud-remaining'),
                              icon: Icons.bubble_chart_rounded,
                              text: value.remainingText ??
                                  '남은 풍선  ${value.remaining}',
                              color: const Color(0xFF7354E8),
                            ),
                            const _HudDivider(),
                          ],
                          _HudMetric(
                            key: const ValueKey('hud-time'),
                            icon: Icons.timer_rounded,
                            text: value.timeText ?? '시간  ${value.secondsLeft}',
                            color: value.secondsLeft <= 5
                                ? const Color(0xFFE53E62)
                                : const Color(0xFF236B9A),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  static Widget _controlButton({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isExit = false,
  }) =>
      Semantics(
        label: label,
        button: true,
        enabled: onPressed != null,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: FilledButton(
            key: key,
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              fixedSize: const Size(44, 44),
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
              elevation: 0,
              backgroundColor:
                  isExit ? const Color(0xD9FF5C88) : const Color(0xE625385F),
              disabledBackgroundColor: const Color(0x668798A8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Color(0xB3FFFFFF), width: 1),
              ),
            ),
            child: Icon(icon, size: 22),
          ),
        ),
      );
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
                Text(
                  text,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _HudDivider extends StatelessWidget {
  const _HudDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 30,
        color: const Color(0x247354E8),
      );
}
