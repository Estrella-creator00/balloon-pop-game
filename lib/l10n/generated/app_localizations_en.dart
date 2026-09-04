// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'POPPOP';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Keep Playing';

  @override
  String get exit => 'Exit';

  @override
  String get cancel => 'Cancel';

  @override
  String stage(int stage) {
    return 'Stage $stage';
  }

  @override
  String score(int score) {
    return 'Score $score';
  }

  @override
  String remaining(int count) {
    return 'Balloons $count';
  }

  @override
  String timeSeconds(int seconds) {
    return 'Time ${seconds}s';
  }

  @override
  String get nicknameTitle => 'Choose a nickname 🎈';

  @override
  String get nicknameSubtitle => 'This name will appear in the game';

  @override
  String get nicknameHint => 'Nickname (2–10 characters)';

  @override
  String get nicknameValidation =>
      'Enter a nickname between 2 and 10 characters.';

  @override
  String get start => 'Start';

  @override
  String get rankingTitle => 'Online Ranking';

  @override
  String get stageChallenge => 'Stage Challenge';

  @override
  String get sixtySecondPop => '60-Second Pop';

  @override
  String get challenge => 'Play Challenge';

  @override
  String get retry => 'Try Again';

  @override
  String get rankingEmpty => 'No scores yet.';

  @override
  String get rankingLoadError => 'Could not load the ranking.';

  @override
  String get rankingSaved => 'Your best score is now on the online ranking.';

  @override
  String get rankingPending => 'We’ll send it again when you’re back online.';

  @override
  String get rankedStageExitTitle => 'End the ranked challenge?';

  @override
  String get rankedStageExitBody =>
      'You can save your current score and reached stage before leaving.';

  @override
  String get rankedStageKeepPlaying => 'Keep Playing';

  @override
  String get rankedStageSaveExit => 'Save & Exit';

  @override
  String get rankedExitTitle => 'End the ranked challenge?';

  @override
  String get rankedExitBody => 'Leaving early will not submit your score.';

  @override
  String get gameExitTitle => 'Exit the game?';

  @override
  String get gameExitBody => 'End this game and return home?';

  @override
  String get endlessExitTitle => 'End Endless Pop?';

  @override
  String get endlessExitBody => 'Save your score and end this run?';

  @override
  String get endlessInfo =>
      'Endless Pop is a relaxed mode with unlimited one-hit balloons. Online ranking offers Stage Challenge and 60-Second Pop. Ranked challenges start from the Ranking menu.';

  @override
  String get allClear => 'ALL CLEAR';
}
