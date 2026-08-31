import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game_session_state.dart';
import 'legendary/flame_preview_skin.dart';
import 'poppop_game.dart';
import 'poppop_engine_mode.dart';
import 'session/game_session_snapshot.dart';

typedef PoppopGameFactory = PoppopGame Function(
  GameSessionState sessionState,
);

class FlameGamePage extends StatefulWidget {
  const FlameGamePage({
    super.key,
    required this.onExit,
    this.gameFactory,
    this.onHudBuild,
    this.initialStage,
    this.initialSkin,
  });

  final VoidCallback onExit;
  final PoppopGameFactory? gameFactory;
  final int? initialStage;
  final FlamePreviewSkin? initialSkin;

  @visibleForTesting
  final VoidCallback? onHudBuild;

  @override
  State<FlameGamePage> createState() => _FlameGamePageState();
}

class _FlameGamePageState extends State<FlameGamePage>
    with WidgetsBindingObserver {
  late final GameSessionState _sessionState;
  late final PoppopGame _game;
  bool _manuallyPaused = false;
  bool _lifecyclePaused = false;
  late FlamePreviewSkin _selectedSkin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionState = GameSessionState();
    _selectedSkin = widget.initialSkin ?? flamePreviewSkinFromUri(Uri.base);
    _game = widget.gameFactory?.call(_sessionState) ??
        PoppopGame(
          _sessionState,
          initialStage:
              widget.initialStage ?? flamePreviewStageFromUri(Uri.base),
          initialSkin: _selectedSkin,
        );
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null && lifecycleState != AppLifecycleState.resumed) {
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

  void _restartGame() {
    setState(() => _manuallyPaused = false);
    unawaited(_game.restartGame(resume: !_lifecyclePaused));
  }

  void _startBoss() {
    _game.startBossStage();
  }

  void _jumpToStage(int stage) {
    setState(() => _manuallyPaused = false);
    unawaited(_game.jumpToStage(stage, resume: !_lifecyclePaused));
  }

  void _switchSkin(FlamePreviewSkin skin) {
    if (_selectedSkin == skin) return;
    setState(() {
      _selectedSkin = skin;
      _manuallyPaused = false;
    });
    unawaited(_game.switchSkin(skin, resume: !_lifecyclePaused));
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
              onBuild: widget.onHudBuild,
              onStartBoss: _startBoss,
              selectedSkin: _selectedSkin,
              onSkinChanged: _switchSkin,
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
                    child: FilledButton.tonal(
                      key: const ValueKey('flame-preview-pause-button'),
                      onPressed: _togglePause,
                      style: _previewButtonStyle(),
                      child: Text(_manuallyPaused ? 'RESUME' : 'PAUSE'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<int>(
                    key: const ValueKey('flame-preview-stage-menu'),
                    tooltip: 'Jump to stage',
                    onSelected: _jumpToStage,
                    itemBuilder: (context) => const <int>[
                      1,
                      9,
                      10,
                      11,
                      19,
                      20,
                      21,
                      29,
                      30,
                    ]
                        .map((stage) => PopupMenuItem<int>(
                              value: stage,
                              child: Text('STAGE $stage'),
                            ))
                        .toList(),
                    child: const SizedBox(
                      width: 52,
                      height: 44,
                      child: Icon(Icons.list_alt),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      key: const ValueKey('flame-preview-restart-button'),
                      onPressed: _restartGame,
                      style: _previewButtonStyle(),
                      child: const Text('RESTART'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('flame-preview-exit-button'),
                      onPressed: _exitPreview,
                      style: _previewButtonStyle(),
                      child: const Text('EXIT'),
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

  ButtonStyle _previewButtonStyle() => FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      );
}

class _PreviewHud extends StatelessWidget {
  const _PreviewHud({
    required this.sessionState,
    required this.manuallyPaused,
    this.onBuild,
    required this.onStartBoss,
    required this.selectedSkin,
    required this.onSkinChanged,
  });

  final GameSessionState sessionState;
  final bool manuallyPaused;
  final VoidCallback? onBuild;
  final VoidCallback onStartBoss;
  final FlamePreviewSkin selectedSkin;
  final ValueChanged<FlamePreviewSkin> onSkinChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'FLAME PREVIEW',
            key: ValueKey('flame-preview-title'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text(
                'SKIN',
                style: TextStyle(
                  color: Color(0xFFB8E6FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<FlamePreviewSkin>(
                key: const ValueKey('flame-preview-skin-selector'),
                value: selectedSkin,
                dropdownColor: const Color(0xFF172A42),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                isDense: true,
                underline: const SizedBox.shrink(),
                items: FlamePreviewSkin.values
                    .map((skin) => DropdownMenuItem(
                          value: skin,
                          child: Text(skin.label),
                        ))
                    .toList(growable: false),
                onChanged: (skin) {
                  if (skin != null) onSkinChanged(skin);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: sessionState,
            builder: (context, child) {
              onBuild?.call();
              final snapshot = sessionState.snapshot;
              final bossStatus = snapshot.bossMaxHp > 0
                  ? '  •  BOSS HP ${snapshot.bossHp}/${snapshot.bossMaxHp}'
                  : '';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'STAGE ${snapshot.stage}  •  SCORE ${snapshot.score}  •  '
                    'LEFT ${snapshot.remainingBalloons}  •  '
                    'TIME ${snapshot.secondsLeft}  •  '
                    '${_phaseLabel(snapshot.phase, manuallyPaused)}$bossStatus',
                    key: const ValueKey('flame-preview-status'),
                    style: const TextStyle(
                      color: Color(0xFFB8E6FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (snapshot.phase == GameSessionPhase.bossReady)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: FilledButton.tonal(
                        key: const ValueKey('flame-preview-boss-start-button'),
                        onPressed: onStartBoss,
                        child: Text('STAGE ${snapshot.stage} BOSS START'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _phaseLabel(GameSessionPhase phase, bool manuallyPaused) {
    if (manuallyPaused || phase == GameSessionPhase.paused) return 'PAUSED';
    return switch (phase) {
      GameSessionPhase.ready => 'READY',
      GameSessionPhase.loading => 'LOADING',
      GameSessionPhase.bossReady => 'BOSS READY',
      GameSessionPhase.playing => 'PLAYING',
      GameSessionPhase.stageClear => 'STAGE CLEAR',
      GameSessionPhase.bossClear => 'BOSS CLEAR',
      GameSessionPhase.coreClear => 'CORE CLEAR',
      GameSessionPhase.endlessComplete => 'ENDLESS COMPLETE',
      GameSessionPhase.failed => 'TIME UP',
      GameSessionPhase.paused => 'PAUSED',
      GameSessionPhase.disposed => 'STOPPED',
    };
  }
}
