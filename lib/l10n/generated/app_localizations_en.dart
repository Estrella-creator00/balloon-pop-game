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
  String get fakePenalty => '-2s';

  @override
  String get allClear => 'ALL CLEAR';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'OK';

  @override
  String get save => 'Save';

  @override
  String get reset => 'Reset';

  @override
  String get home => 'Home';

  @override
  String get shop => 'Shop';

  @override
  String get event => 'Events';

  @override
  String get ranking => 'Ranking';

  @override
  String get settings => 'Settings';

  @override
  String get help => 'Help';

  @override
  String get achievements => 'Achievements';

  @override
  String get bestScore => 'Best';

  @override
  String get lastScore => 'Recent';

  @override
  String get record => 'Score';

  @override
  String get rank => 'Rank';

  @override
  String get nickname => 'Nickname';

  @override
  String get notSet => 'Not set';

  @override
  String get locked => 'Locked';

  @override
  String get inUse => 'Equipped';

  @override
  String get use => 'Equip';

  @override
  String get playNow => 'Play Now';

  @override
  String get goHome => 'Home';

  @override
  String get coinPurchase => 'Get Coins';

  @override
  String get ownedCoins => 'Your Coins';

  @override
  String coins(String count) {
    return '$count Coins';
  }

  @override
  String get purchaseComingSoon => 'Purchases are coming soon.';

  @override
  String get productsEmpty => 'No products to show';

  @override
  String get previewClose => 'Close balloon preview';

  @override
  String productInUse(String name) {
    return '$name equipped';
  }

  @override
  String productPurchased(String name) {
    return 'Purchased $name!';
  }

  @override
  String get productNotOwned => 'You do not own this item.';

  @override
  String get coinsInsufficient => 'Not enough coins!';

  @override
  String get productAlreadyOwned => 'You already own this item.';

  @override
  String get productUnavailable => 'This item is not available right now.';

  @override
  String get equippedDone => 'Equipped!';

  @override
  String buyPrice(int price) {
    return 'Buy for $price';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterOwned => 'Owned';

  @override
  String get filterUnowned => 'Not Owned';

  @override
  String get filterLimited => 'Limited';

  @override
  String get rarityCommon => 'Common';

  @override
  String get rarityRare => 'Rare';

  @override
  String get rarityHeroic => 'Heroic';

  @override
  String get rarityLegendary => 'Legendary';

  @override
  String get recommended => 'Pick';

  @override
  String get basicOwned => 'Free';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get haptics => 'Haptics';

  @override
  String get player => 'Player';

  @override
  String get gameSettings => 'Game Settings';

  @override
  String get information => 'Information';

  @override
  String get terms => 'Terms of Use';

  @override
  String get privacy => 'Privacy Policy';

  @override
  String get contact => 'Contact Us';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get termsPending =>
      'The Terms of Use will be available before launch.';

  @override
  String get privacyPending =>
      'The Privacy Policy will be available before launch.';

  @override
  String get contactPending =>
      'Contact details will be available before launch.';

  @override
  String get dataReset => 'Reset Data';

  @override
  String get dataResetDone => 'Game data has been reset.';

  @override
  String get dataResetTitle => 'Reset all game data?';

  @override
  String get dataResetBody =>
      'Coins, balloons, equipment, nickname, and settings will all be reset.';

  @override
  String get nicknameChange => 'Change Nickname';

  @override
  String get progressReset => 'Reset Progress';

  @override
  String get progressResetBody => 'Reset your saved progress?';

  @override
  String get endlessPop => 'Endless Pop';

  @override
  String get endlessStart => 'Start Challenge';

  @override
  String get endlessRuleOneHit => 'Every balloon pops with one tap.';

  @override
  String get endlessRuleNoLimit =>
      'Keep popping with no time limit or game over.';

  @override
  String get endlessRuleScore => 'Each balloon adds 1 to your score.';

  @override
  String get endlessRuleSave =>
      'Tap Exit to save your current and best scores.';

  @override
  String get endlessRankingInfo =>
      'Online ranking offers Stage Challenge and 60-Second Pop. Start ranked challenges from the Ranking menu.';

  @override
  String get endlessLocked => 'Complete Stage 30 to unlock this mode.';

  @override
  String get endlessTitle => '∞ (Endless Pop)';

  @override
  String get endlessStartSemantic => 'Start Endless Pop';

  @override
  String get endlessLockedSemantic => 'Endless Pop locked';

  @override
  String get endlessInfoSemantic => 'About Endless Pop';

  @override
  String get preparing => 'Getting ready...';

  @override
  String get nextStep => 'Next ▶';

  @override
  String get startShort => 'Start';

  @override
  String get startScreen => 'Start Screen';

  @override
  String get endlessFinished => 'Endless Pop Complete';

  @override
  String currentRecord(int score) {
    return 'Current Score  $score';
  }

  @override
  String get tryAgain => 'Try Again';

  @override
  String get timeUp => 'TIME UP';

  @override
  String get gameComplete => 'Game Complete!';

  @override
  String get finalScore => 'Final Score';

  @override
  String points(int score) {
    return '$score pts';
  }

  @override
  String get again => 'Again';

  @override
  String stageLockedSemantic(String title) {
    return '$title stages locked';
  }

  @override
  String stageStartSemantic(String title) {
    return 'Start $title stages';
  }

  @override
  String get stageOneDescription => 'Classic balloons · Boss challenge!';

  @override
  String get stageTwoDescription => 'Two-hit balloons · Double boss!';

  @override
  String get stageFakeDescription => 'Do not pop the fake balloons!';

  @override
  String get modeEndless => '∞ Endless';

  @override
  String get ribbonText => 'Tap & Burst!';

  @override
  String get rankingColumnRank => 'Rank';

  @override
  String get rankingColumnNickname => 'Nickname';

  @override
  String get rankingColumnRecord => 'Score';

  @override
  String get myBestNone => 'My Best  -';

  @override
  String myBest(int score, String rank) {
    return 'My Best  $score · $rank';
  }

  @override
  String get outsideTop100 => 'Outside Top 100';

  @override
  String rankPosition(int rank) {
    return '#$rank';
  }

  @override
  String get skinBasic => 'Basic Balloon';

  @override
  String get skinHeart => 'Heart Balloon';

  @override
  String get skinStar => 'Star Balloon';

  @override
  String get skinFlower => 'Flower Balloon';

  @override
  String get skinMochi => 'MOCHI';

  @override
  String get skinWari => 'WARI';

  @override
  String get skinKicks => 'KICKS';

  @override
  String get skinBoo => 'BOO';

  @override
  String get skinMugi => 'MUGI';

  @override
  String get skinGemi => 'GEMI';

  @override
  String get skinShushu => 'SHUSHU';

  @override
  String get skinStarDescription => 'Quiet, but loves to stand out';

  @override
  String get skinFlowerDescription => 'Bright and cheerful';

  @override
  String get skinMochiDescription => 'Timid and curious';

  @override
  String get skinWariDescription => 'Cool and free-spirited';

  @override
  String get skinKicksDescription => 'Energetic and competitive';

  @override
  String get skinBooDescription => 'Playful and a little timid';

  @override
  String get skinMugiDescription => 'Sensitive and prickly';

  @override
  String get skinGemiDescription => 'Cool and tough';

  @override
  String get skinShushuDescription => 'Sweet and quirky';

  @override
  String get sectionMultiHitHeadline => 'Tough Balloons!';

  @override
  String get sectionMultiHitRule1 => 'Tap each balloon twice';

  @override
  String get sectionMultiHitRule2 => 'Pop them all quickly';

  @override
  String get sectionFakeHeadline => 'Fake Balloons!';

  @override
  String get sectionFakeRule1 => 'Do not tap fake balloons';

  @override
  String get sectionFakeRule2 => 'Pop only the real balloons';

  @override
  String get timeInfinite => 'Time  ∞';

  @override
  String get refresh => 'Refresh';

  @override
  String rankingScore(int score, String detail) {
    return '$score · $detail';
  }

  @override
  String reachedStage(int stage) {
    return 'STAGE $stage';
  }
}
