import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GameHeaderData {
  const GameHeaderData({
    required this.stage,
    required this.score,
    required this.remaining,
    required this.secondsLeft,
    required this.controlsEnabled,
  });

  final int stage;
  final int score;
  final int remaining;
  final int secondsLeft;
  final bool controlsEnabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameHeaderData &&
          stage == other.stage &&
          score == other.score &&
          remaining == other.remaining &&
          secondsLeft == other.secondsLeft &&
          controlsEnabled == other.controlsEnabled;

  @override
  int get hashCode =>
      Object.hash(stage, score, remaining, secondsLeft, controlsEnabled);
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(
              children: [
                const Text(
                  'POPPOP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Color(0x55006699),
                        offset: Offset(0, 3),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${value.stage} STAGE',
                  style: const TextStyle(
                    color: Color(0xFF5E35B1),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _infoPill('점수', '${value.score}', const Color(0xFFFFB300)),
                    const SizedBox(width: 10),
                    _infoPill(
                      '남은 풍선',
                      '${value.remaining}',
                      const Color(0xFF7E57C2),
                    ),
                    const SizedBox(width: 10),
                    _infoPill(
                      '시간',
                      '${value.secondsLeft}',
                      value.secondsLeft <= 5
                          ? Colors.redAccent
                          : const Color(0xFF26A69A),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('pause-button'),
                      onPressed: value.controlsEnabled ? onPause : null,
                      icon: const Icon(Icons.pause_rounded, size: 25),
                      label: const Text('일시정지'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(132, 50),
                        backgroundColor: const Color(0xFF7E57C2),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      key: const ValueKey('end-button'),
                      onPressed: value.controlsEnabled ? onEnd : null,
                      icon: const Icon(Icons.stop_circle_rounded, size: 25),
                      label: const Text('끝내기'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(120, 50),
                        backgroundColor: const Color(0xFFFF7043),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  static Widget _infoPill(String label, String value, Color color) => Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22004666),
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$label  $value',
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
}
