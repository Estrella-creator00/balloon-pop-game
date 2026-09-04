import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../audio/pop_sound.dart';
import '../../balloon_background.dart';
import '../../balloon_skin_catalog.dart';
import '../../widgets/game_header.dart';
import '../../l10n/l10n.dart';
import '../../gameplay/stage_intro_definition.dart';
import '../game_session_state.dart';
import '../legendary/flame_preview_skin.dart';
import '../poppop_game.dart';
import '../session/game_session_snapshot.dart';
import 'flame_integration_contract.dart';
import 'flame_integration_debug.dart';

typedef FlameIntegrationGameFactory = PoppopGame Function(
  GameSessionState session,
  FlamePreviewSkin skin,
  int initialStage,
  FlameGameplayFeedbackCallback onFeedback,
);

class FlameIntegrationGamePage extends StatefulWidget {
  const FlameIntegrationGamePage({
    super.key,
    required this.initialStage,
    required this.skin,
    required this.sessionId,
    required this.onFeedback,
    required this.onStageCompleted,
    this.onAudioPause,
    this.gameFactory,
    this.debugConfig = const FlameIntegrationDebugConfig(),
    this.metrics,
    this.endlessMode = false,
    this.rankedRunMode = FlameRankedRunMode.none,
    this.onEndlessFinished,
  });

  final int initialStage;
  final FlamePreviewSkin skin;
  final int sessionId;
  final FlameGameplayFeedbackCallback onFeedback;
  final FlameStageCompletionCallback onStageCompleted;
  final VoidCallback? onAudioPause;
  final FlameIntegrationGameFactory? gameFactory;
  final FlameIntegrationDebugConfig debugConfig;

  @visibleForTesting
  final FlameIntegrationMetrics? metrics;
  final bool endlessMode;
  final FlameRankedRunMode rankedRunMode;
  final EndlessRecordCallback? onEndlessFinished;

  @override
  State<FlameIntegrationGamePage> createState() =>
      _FlameIntegrationGamePageState();
}

class _FlameIntegrationGamePageState extends State<FlameIntegrationGamePage>
    with WidgetsBindingObserver {
  late final GameSessionState _session;
  late final PoppopGame _game;
  late final ValueNotifier<GameHeaderData> _header;
  late final FlameIntegrationMetrics _metrics;
  final Set<String> _reportedStageCompletions = <String>{};
  GameSessionPhase _lastPhase = GameSessionPhase.ready;
  bool _manualPause = false;
  bool _backgroundPause = false;
  bool _resultReturned = false;
  bool _sectionIntroVisible = false;
  final Set<int> _shownSectionIntroGenerations = <int>{};
  EndlessRecordResult? _endlessResult;
  EndlessRecordResult? _reportedEndlessRecord;

  @override
  void initState() {
    super.initState();
    _metrics = widget.metrics ?? FlameIntegrationMetrics();
    WidgetsBinding.instance.addObserver(this);
    _metrics.lifecycleObserverCount++;
    _metrics.lifecycleState =
        (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed)
            .name;
    _session = GameSessionState()..addListener(_onSessionChanged);
    _header = ValueNotifier(_headerFor(_session));
    _game = widget.gameFactory?.call(
          _session,
          widget.skin,
          widget.initialStage,
          widget.onFeedback,
        ) ??
        PoppopGame(
          _session,
          initialStage: widget.initialStage,
          initialSkin: widget.skin,
          onGameplayFeedback: widget.onFeedback,
          renderLegendaryBackground: false,
          showDiagnostics: widget.debugConfig.enabled,
          diagnosticsTextProvider:
              widget.debugConfig.enabled ? _diagnosticsText : null,
          endlessMode: widget.endlessMode,
          rankedSixtySecondMode:
              widget.rankedRunMode == FlameRankedRunMode.sixtySeconds,
        );
    _metrics.activeGameInstances++;
  }

  String _diagnosticsText(double fps, double milliseconds) {
    final running = _game.hostWantsRunning &&
        !_game.isShutdown &&
        _session.phase == GameSessionPhase.playing;
    return 'INTEGRATION DEBUG  FPS ${fps.toStringAsFixed(0)}  '
        '${milliseconds.toStringAsFixed(1)}ms\n'
        'GAME ${_metrics.activeGameInstances}  '
        'WIDGET ${_metrics.activeGameWidgetInstances}  '
        'COMP ${_game.activeGameplayComponentCount}\n'
        'EFFECT ${_game.activeEffectCount}  '
        'PARTICLE ${_game.activeParticleCount}\n'
        'AUDIO ${PopSound.playingGameplayVoiceCount}/'
        '${PopSound.activeGameplayVoiceCount}  '
        'READY ${PopSound.readyGameplayAssetCount}  '
        'PENDING ${PopSound.gameplayPendingPrepareCount}\n'
        'AUDIO-LISTENER ${PopSound.gameplayListenerCount}  '
        'CACHE ${_game.activeCacheImageCount}  '
        'BG 1\n'
        'HUD ${_metrics.hudRebuildCount}  '
        'SESSION ${_metrics.sessionNotificationCount}  '
        'SHELL ${_metrics.shellRebuildCount}\n'
        'LIFE ${_metrics.lifecycleState}  '
        '${running ? 'RUNNING' : 'PAUSED'}  '
        'OBS ${_metrics.lifecycleObserverCount}\n'
        'SHUTDOWN ${_game.isShutdown ? 'YES' : 'NO'}  '
        'POST-UPDATE ${_metrics.updateAdvancedAfterShutdown ? 'YES' : 'NO'}';
  }

  GameHeaderData _headerFor(GameSessionState session) => GameHeaderData(
        stage: session.stage == 0 ? widget.initialStage : session.stage,
        score: session.score,
        remaining: session.activeBossCount > 0
            ? session.activeBossCount
            : session.remainingBalloons,
        secondsLeft: session.secondsLeft,
        controlsEnabled: session.phase == GameSessionPhase.playing,
        stageLabel: widget.endlessMode
            ? poppopLocalizationsForLocale(
                    WidgetsBinding.instance.platformDispatcher.locale)
                .endlessPop
            : widget.rankedRunMode == FlameRankedRunMode.sixtySeconds
                ? poppopLocalizationsForLocale(
                        WidgetsBinding.instance.platformDispatcher.locale)
                    .sixtySecondPop
                : widget.rankedRunMode == FlameRankedRunMode.stage
                    ? poppopLocalizationsForLocale(
                            WidgetsBinding.instance.platformDispatcher.locale)
                        .stageChallenge
                    : null,
        scoreText: widget.endlessMode ||
                widget.rankedRunMode == FlameRankedRunMode.sixtySeconds
            ? poppopLocalizationsForLocale(
                    WidgetsBinding.instance.platformDispatcher.locale)
                .currentRecord(session.score)
            : null,
        remainingText: widget.endlessMode ||
                widget.rankedRunMode == FlameRankedRunMode.sixtySeconds
            ? ''
            : null,
        timeText: widget.endlessMode
            ? poppopLocalizationsForLocale(
                    WidgetsBinding.instance.platformDispatcher.locale)
                .timeInfinite
            : null,
      );

  void _onSessionChanged() {
    if (!mounted || _resultReturned) return;
    _metrics.sessionNotificationCount++;
    final nextHeader = _headerFor(_session);
    if (_header.value != nextHeader) {
      _metrics.hudRebuildCount++;
      _header.value = nextHeader;
    }

    final phase = _session.phase;
    final phaseChanged = phase != _lastPhase;
    if (phase == GameSessionPhase.playing &&
        stageIntroDefinitions.containsKey(_session.stage) &&
        _shownSectionIntroGenerations.add(_session.generation)) {
      _sectionIntroVisible = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_sectionIntroVisible) return;
        _game.pausePreview();
      });
    }
    if ((phase == GameSessionPhase.stageClear ||
            phase == GameSessionPhase.bossClear) &&
        phaseChanged) {
      final key = '${_session.stage}:${_session.generation}:${phase.name}';
      if (_reportedStageCompletions.add(key)) {
        widget.onStageCompleted(FlameStageCompletionEvent(
          stage: _session.stage,
          phase: phase,
          generation: _session.generation,
        ));
      }
    }
    _lastPhase = phase;

    if (phase == GameSessionPhase.endlessComplete && phaseChanged) {
      _endlessResult = _reportEndlessRunOnce();
      widget.onAudioPause?.call();
      _game.pausePreview();
      setState(() {});
      return;
    }

    if (phase == GameSessionPhase.rankedSixtySecondComplete && phaseChanged) {
      _returnResult(FlameIntegrationOutcome.completed);
      return;
    }

    if (phase == GameSessionPhase.coreClear ||
        phase == GameSessionPhase.failed) {
      _returnResult(phase == GameSessionPhase.coreClear
          ? FlameIntegrationOutcome.completed
          : FlameIntegrationOutcome.failed);
      return;
    }
    if (phaseChanged) setState(() {});
  }

  void _returnResult(FlameIntegrationOutcome outcome) {
    if (_resultReturned) return;
    _resultReturned = true;
    final result = FlameIntegrationResult(
      outcome: outcome,
      stage: _session.stage,
      score: _session.score,
      sessionId: widget.sessionId,
    );
    _metrics.recordShutdown(_game.updateCallCount);
    widget.onAudioPause?.call();
    _game.shutdown();
    _metrics.observePostShutdownUpdateCount(_game.updateCallCount);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(result);
    });
  }

  void _pause() {
    if (_manualPause || _session.phase != GameSessionPhase.playing) return;
    setState(() => _manualPause = true);
    widget.onAudioPause?.call();
    _game.pausePreview();
  }

  void _resume() {
    if (!_manualPause) return;
    setState(() => _manualPause = false);
    if (!_backgroundPause) _game.resumePreview();
  }

  Future<void> _restartEndless() async {
    if (!widget.endlessMode || _endlessResult == null) return;
    setState(() {
      _endlessResult = null;
      _reportedEndlessRecord = null;
    });
    await _game.restartEndless();
  }

  EndlessRecordResult _reportEndlessRunOnce() {
    if (_reportedEndlessRecord case final result?) return result;
    final callback = widget.onEndlessFinished;
    return _reportedEndlessRecord = callback?.call(_session.score) ??
        EndlessRecordResult(
          score: _session.score,
          bestScore: _session.score,
          isNewBest: true,
        );
  }

  void _finishEndless() {
    _returnResult(FlameIntegrationOutcome.endlessFinished);
  }

  void _dismissSectionIntro() {
    if (!_sectionIntroVisible) return;
    setState(() => _sectionIntroVisible = false);
    if (!_backgroundPause) _game.resumePreview();
  }

  Future<void> _confirmExit() async {
    final strings = context.l10n;
    final saveRankedStage = widget.rankedRunMode == FlameRankedRunMode.stage;
    final wasPaused = _manualPause;
    if (!wasPaused) {
      widget.onAudioPause?.call();
      _game.pausePreview();
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(saveRankedStage
            ? strings.rankedStageExitTitle
            : widget.endlessMode
                ? strings.endlessExitTitle
                : widget.rankedRunMode != FlameRankedRunMode.none
                    ? strings.rankedExitTitle
                    : strings.gameExitTitle),
        content: Text(saveRankedStage
            ? strings.rankedStageExitBody
            : widget.endlessMode
                ? strings.endlessExitBody
                : widget.rankedRunMode != FlameRankedRunMode.none
                    ? strings.rankedExitBody
                    : strings.gameExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(saveRankedStage
                ? strings.rankedStageKeepPlaying
                : strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
                saveRankedStage ? strings.rankedStageSaveExit : strings.exit),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      if (widget.endlessMode) {
        _game.finishEndless();
      } else {
        _returnResult(saveRankedStage
            ? FlameIntegrationOutcome.savedAndExited
            : FlameIntegrationOutcome.exited);
      }
    } else if (!wasPaused && !_backgroundPause) {
      _game.resumePreview();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _metrics.lifecycleState = state.name;
    final backgrounded = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused;
    if (backgrounded) {
      _backgroundPause = true;
      widget.onAudioPause?.call();
      _game.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      _backgroundPause = false;
      if (!_manualPause && !_sectionIntroVisible) _game.resumePreview();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _metrics.lifecycleObserverCount--;
    _session.removeListener(_onSessionChanged);
    _metrics.recordShutdown(_game.updateCallCount);
    _game.shutdown();
    _metrics.observePostShutdownUpdateCount(_game.updateCallCount);
    _metrics.activeGameInstances--;
    _session.dispose();
    _header.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _metrics.shellRebuildCount++;
    final phase = _session.phase;
    return Scaffold(
      key: const ValueKey('flame-integration-gameplay'),
      backgroundColor: const Color(0xFFAEE7FF),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            key: const ValueKey(
              'flame-integration-fullscreen-background',
            ),
            child: IgnorePointer(
              child: FlameIntegrationBackground(skin: widget.skin),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                GameHeader(
                  key: const ValueKey('flame-integration-hud-layer'),
                  data: _header,
                  onPause: _pause,
                  onEnd: _confirmExit,
                ),
                Expanded(
                  child: ClipRect(
                    key: const ValueKey('flame-integration-playfield-clip'),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _IntegrationGameWidget(
                            game: _game,
                            metrics: _metrics,
                          ),
                        ),
                        if (phase == GameSessionPhase.loading)
                          _StatusOverlay(title: context.l10n.preparing),
                        if (phase == GameSessionPhase.bossReady)
                          _BossReadyOverlay(
                            stage: _session.stage,
                            onStart: _game.startBossStage,
                          ),
                        if (_sectionIntroVisible)
                          _SectionIntroOverlay(
                            definition: stageIntroDefinitions[_session.stage]!,
                            onStart: _dismissSectionIntro,
                          ),
                        if (_manualPause)
                          _PauseOverlay(
                            onResume: _resume,
                            onExit: _confirmExit,
                          ),
                        if (_endlessResult case final result?)
                          _EndlessResultOverlay(
                            result: result,
                            onRestart: _restartEndless,
                            onHome: _finishEndless,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FlameIntegrationBackground extends StatelessWidget {
  const FlameIntegrationBackground({super.key, required this.skin});

  final FlamePreviewSkin skin;

  bool get usesLegendaryBackground =>
      skin.catalogDefinition.rarity == BalloonRarity.legendary;

  @override
  Widget build(BuildContext context) {
    if (!usesLegendaryBackground) {
      return const GameplaySkyBackground(
        key: ValueKey('flame-integration-sky-background'),
      );
    }
    final background = skin.catalogDefinition.background;
    return BalloonBackgroundRenderer(
      key: const ValueKey('flame-integration-legendary-background'),
      background: background,
      assetPathOverride: BalloonBackgroundRegistry.gameplayAssetPathFor(
        background,
      ),
      fallback: const ColoredBox(color: Color(0xFFAEE7FF)),
    );
  }
}

class _IntegrationGameWidget extends StatefulWidget {
  const _IntegrationGameWidget({required this.game, required this.metrics});

  final PoppopGame game;
  final FlameIntegrationMetrics metrics;

  @override
  State<_IntegrationGameWidget> createState() => _IntegrationGameWidgetState();
}

class _IntegrationGameWidgetState extends State<_IntegrationGameWidget> {
  @override
  void initState() {
    super.initState();
    widget.metrics.activeGameWidgetInstances++;
  }

  @override
  void dispose() {
    widget.metrics.activeGameWidgetInstances--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GameWidget<PoppopGame>(
        key: const ValueKey('flame-integration-game-widget'),
        game: widget.game,
      );
}

class _SectionIntroOverlay extends StatelessWidget {
  const _SectionIntroOverlay({required this.definition, required this.onStart});

  final StageIntroDefinition definition;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: ColoredBox(
          color: const Color(0x660D2940),
          child: Center(
            child: Container(
              key: const ValueKey('flame-integration-stage-intro'),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    definition.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF7354E8),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    definition.title.contains('11')
                        ? context.l10n.sectionMultiHitHeadline
                        : definition.title.contains('21')
                            ? context.l10n.sectionFakeHeadline
                            : definition.headline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFF4F7B),
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (var index = 0; index < definition.rules.length; index++)
                    Text(
                      '• ${definition.title.contains('11') ? (index == 0 ? context.l10n.sectionMultiHitRule1 : context.l10n.sectionMultiHitRule2) : definition.title.contains('21') ? (index == 0 ? context.l10n.sectionFakeRule1 : context.l10n.sectionFakeRule2) : definition.rules[index]}',
                      style: const TextStyle(
                        color: Color(0xFF3F5F70),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 13),
                  FilledButton(
                    key: const ValueKey('flame-integration-stage-intro-next'),
                    onPressed: onStart,
                    child: Text(context.l10n.nextStep),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _BossReadyOverlay extends StatelessWidget {
  const _BossReadyOverlay({required this.stage, required this.onStart});

  final int stage;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => _StatusOverlay(
        title: 'BOSS STAGE $stage',
        action: FilledButton(
          key: const ValueKey('flame-integration-boss-start'),
          onPressed: onStart,
          child: Text(context.l10n.startShort),
        ),
      );
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onExit});

  final VoidCallback onResume;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => _StatusOverlay(
        title: context.l10n.pause,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              key: const ValueKey('flame-integration-resume'),
              onPressed: onResume,
              child: Text(context.l10n.resume),
            ),
            TextButton(
                onPressed: onExit, child: Text(context.l10n.startScreen)),
          ],
        ),
      );
}

class _EndlessResultOverlay extends StatelessWidget {
  const _EndlessResultOverlay({
    required this.result,
    required this.onRestart,
    required this.onHome,
  });

  final EndlessRecordResult result;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => _StatusOverlay(
        title: context.l10n.endlessFinished,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.currentRecord(result.score),
              key: const ValueKey('endless-current-score'),
              style: const TextStyle(
                color: Color(0xFF25385F),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'BEST ${result.bestScore}',
              key: const ValueKey('endless-best-score'),
              style: const TextStyle(
                color: Color(0xFFFF4F7B),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (result.isNewBest)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'NEW BEST!',
                  key: ValueKey('endless-new-best'),
                  style: TextStyle(
                    color: Color(0xFFE59A00),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            FilledButton(
              key: const ValueKey('endless-restart'),
              onPressed: onRestart,
              child: Text(context.l10n.tryAgain),
            ),
            TextButton(
              key: const ValueKey('endless-home'),
              onPressed: onHome,
              child: Text(context.l10n.goHome),
            ),
          ],
        ),
      );
}

class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: ColoredBox(
          color: const Color(0x88004D73),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF7E57C2),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 18),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
