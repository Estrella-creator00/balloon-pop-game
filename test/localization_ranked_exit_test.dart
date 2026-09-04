import 'package:balloon_pop_game/game_engine/integration/flame_integration_contract.dart';
import 'package:balloon_pop_game/game_engine/integration/flame_integration_game_page.dart';
import 'package:balloon_pop_game/game_engine/legendary/flame_preview_skin.dart';
import 'package:balloon_pop_game/game_engine/poppop_game.dart';
import 'package:balloon_pop_game/game_engine/session/game_session_snapshot.dart';
import 'package:balloon_pop_game/l10n/generated/app_localizations.dart';
import 'package:balloon_pop_game/l10n/l10n.dart';
import 'package:balloon_pop_game/ranking/online_ranking_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('locale resolution uses Korean, English, then English fallback', () {
    expect(poppopLocaleResolution(const [Locale('ko')], const []),
        const Locale('ko'));
    expect(poppopLocaleResolution(const [Locale('en')], const []),
        const Locale('en'));
    expect(poppopLocaleResolution(const [Locale('ja')], const []),
        const Locale('en'));
  });

  for (final locale in const [Locale('ko'), Locale('en')]) {
    testWidgets('ranked Stage exit saves once in ${locale.languageCode}',
        (tester) async {
      late PoppopGame game;
      FlameIntegrationResult? result;
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          return FilledButton(
            key: const ValueKey('launch-ranked-stage'),
            onPressed: () async {
              result = await Navigator.of(context).push<FlameIntegrationResult>(
                MaterialPageRoute(
                  builder: (_) => FlameIntegrationGamePage(
                    initialStage: 1,
                    skin: FlamePreviewSkin.basic,
                    sessionId: 1,
                    rankedRunMode: FlameRankedRunMode.stage,
                    onFeedback: (_) {},
                    onStageCompleted: (_) {},
                    gameFactory: (session, skin, stage, feedback) => game =
                        PoppopGame(session,
                            initialStage: stage,
                            initialSkin: skin,
                            showDiagnostics: false,
                            onGameplayFeedback: feedback),
                  ),
                ),
              );
            },
            child: const Text('launch'),
          );
        }),
      ));
      await tester.tap(find.byKey(const ValueKey('launch-ranked-stage')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await game.loaded;
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('end-button')));
      await tester.pumpAndSettle();
      final strings = await AppLocalizations.delegate.load(locale);
      expect(find.text(strings.rankedStageExitTitle), findsOneWidget);
      expect(find.text(strings.rankedStageExitBody), findsOneWidget);

      await tester.tap(find.text(strings.rankedStageKeepPlaying));
      await tester.pump();
      expect(result, isNull);
      expect(game.sessionState.phase, isNot(GameSessionPhase.paused));

      await tester.tap(find.byKey(const ValueKey('end-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.rankedStageSaveExit));
      await tester.pumpAndSettle();
      expect(result?.outcome, FlameIntegrationOutcome.savedAndExited);
      expect(result?.stage, 1);
      expect(result?.score, 0);
    });
  }

  test('only saved ranked Stage exits are submitted by the shell contract', () {
    expect(FlameIntegrationOutcome.savedAndExited,
        isNot(FlameIntegrationOutcome.exited));
    expect(
      const RankedRunResult(
        category: RankingCategory.stage,
        score: 4,
        reachedStage: 3,
        cleared: false,
      ).cleared,
      isFalse,
    );
  });
}
