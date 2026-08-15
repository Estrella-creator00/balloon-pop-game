import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game_session_state.dart';
import 'poppop_game.dart';

typedef PoppopGameFactory = PoppopGame Function(
  GameSessionState sessionState,
);

class FlameGamePage extends StatefulWidget {
  const FlameGamePage({
    super.key,
    required this.onExit,
    this.gameFactory,
  });

  final VoidCallback onExit;
  final PoppopGameFactory? gameFactory;

  @override
  State<FlameGamePage> createState() => _FlameGamePageState();
}

class _FlameGamePageState extends State<FlameGamePage>
    with WidgetsBindingObserver {
  late final GameSessionState _sessionState;
  late final PoppopGame _game;
  bool _manuallyPaused = false;
  bool _lifecyclePaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionState = GameSessionState();
    _game =
        widget.gameFactory?.call(_sessionState) ?? PoppopGame(_sessionState);
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null &&
        lifecycleState != AppLifecycleState.resumed) {
      _lifecyclePaused = true;
      _game.pausePreview();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _lifecyclePaused = false;
        if (!_manuallyPaused) _game.resumePreview();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _lifecyclePaused = true;
        _game.pausePreview();
    }
  }

  void _togglePause() {
    setState(() {
      _manuallyPaused = !_manuallyPaused;
      if (_manuallyPaused) {
        _game.pausePreview();
      } else if (!_lifecyclePaused) {
        _game.resumePreview();
      }
    });
  }

  void _exitPreview() {
    _game.shutdown();
    widget.onExit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.shutdown();
    _sessionState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1726),
      body: SafeArea(
        child: Column(
          children: [
            _PreviewHud(
              sessionState: _sessionState,
              manuallyPaused: _manuallyPaused,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: GameWidget<PoppopGame>(
                    key: const ValueKey('flame-preview-game-widget'),
                    game: _game,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('flame-preview-pause-button'),
                      onPressed: _togglePause,
                      icon: Icon(
                        _manuallyPaused ? Icons.play_arrow : Icons.pause,
                      ),
                      label: Text(_manuallyPaused ? 'RESUME' : 'PAUSE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('flame-preview-exit-button'),
                      onPressed: _exitPreview,
                      icon: const Icon(Icons.close),
                      label: const Text('EXIT'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewHud extends StatelessWidget {
  const _PreviewHud({
    required this.sessionState,
    required this.manuallyPaused,
  });

  final GameSessionState sessionState;
  final bool manuallyPaused;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'FLAME PREVIEW',
              key: ValueKey('flame-preview-title'),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: sessionState,
            builder: (context, child) => Text(
              '${manuallyPaused || !sessionState.isRunning ? 'PAUSED' : 'RUNNING'}'
              '  •  ${sessionState.updateCount}',
              key: const ValueKey('flame-preview-status'),
              style: const TextStyle(
                color: Color(0xFFB8E6FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
