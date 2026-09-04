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
  String get supportId => 'Support ID';

  @override
  String get supportIdDescription =>
      'Include this ID when requesting deletion of your online ranking data. Do not post it publicly.';

  @override
  String get copySupportId => 'Copy Support ID';

  @override
  String get supportIdCopied => 'Support ID copied.';

  @override
  String get supportIdError =>
      'Could not load your Support ID. Check your connection and try again.';

  @override
  String get linkOpenError => 'Could not open the page.';

  @override
  String get view => 'View';

  @override
  String get support => 'Customer Support';

  @override
  String get viewOnWeb => 'View on the Web';

  @override
  String get emailSupport => 'Email Support';

  @override
  String get supportEmailSubject => 'POPPOP Support Request';

  @override
  String get privacyIntroduction =>
      'Effective date: September 4, 2026. OOPSIDE STUDIO processes only the information needed to operate POPPOP.';

  @override
  String get privacyOperatorTitle => 'Operator and contact';

  @override
  String get privacyOperatorBody =>
      'Operator: OOPSIDE STUDIO (웁사이드 스튜디오)\nEmail: oopsidestudio@gmail.com';

  @override
  String get privacyOnlineTitle => 'Information sent online';

  @override
  String get privacyOnlineBody =>
      'When you open an online leaderboard or submit a record, we process the anonymous Firebase UID (Support ID), nickname, score, server submission time, and schema version. Stage Challenge also includes the reached stage and whether it was cleared. Categories are separated into the Stage and 60-second leaderboard collections.';

  @override
  String get privacyLocalTitle => 'Information stored only on your device';

  @override
  String get privacyLocalBody =>
      'Stage progress and unlocks, recent and best scores, Endless Pop records and intro state, coins, purchased and equipped items, nickname and onboarding state, sound and haptic settings are stored in browser localStorage or app-local storage. A best leaderboard result may be stored temporarily while waiting to retry after a network error.';

  @override
  String get privacyFirebaseTitle => 'Firebase and purpose';

  @override
  String get privacyFirebaseBody =>
      'Online ranking uses Google Firebase Authentication with anonymous sign-in and Cloud Firestore. We use this information to provide rankings, update best records, prevent duplicate or invalid submissions, and handle support and deletion requests. Firebase may process technical information such as IP addresses and user-agent data for authentication security and abuse prevention. The web app is served through GitHub Pages. We do not use Analytics, Crashlytics, or advertising SDKs, and we do not sell personal information or share it for targeted advertising.';

  @override
  String get privacyNotCollectedTitle => 'Information we do not collect';

  @override
  String get privacyNotCollectedBody =>
      'We do not collect precise location, camera, microphone, photos, contacts, advertising identifiers, payment-card information, or email-and-password accounts.';

  @override
  String get privacyRetentionTitle => 'Retention and deletion';

  @override
  String get privacyRetentionBody =>
      'Online leaderboard records and the anonymous authentication identifier remain until replaced, deletion is requested, or they are no longer needed to operate the service. Verifiable deletion requests are normally handled within 30 days. Device-local information can be removed with Reset Data, by clearing browser site data, or by uninstalling the app. We cannot remotely view or erase information stored only on your device.';

  @override
  String get privacyChildrenTitle => 'Children and safe nicknames';

  @override
  String get privacyChildrenBody =>
      'Do not use a real name, school, phone number, email, address, or other identifying details in a nickname. Parents and guardians should guide a child\'s use of online ranking and may request deletion where appropriate.';

  @override
  String get privacySecurityTitle => 'Security';

  @override
  String get privacySecurityBody =>
      'We use anonymous authentication, Firestore security rules, and limits on submitted fields and scores. No internet transmission or storage system can be guaranteed completely secure. Do not post your Support ID publicly.';

  @override
  String get privacyContactTitle => 'Questions and policy changes';

  @override
  String get privacyContactBody =>
      'We may update this policy when the service or legal requirements change and will update its effective date. Contact oopsidestudio@gmail.com for privacy or deletion questions.';

  @override
  String get supportIntroduction =>
      'Contact OOPSIDE STUDIO if you have a problem using POPPOP or need to request data deletion.';

  @override
  String get supportContactTitle => 'Game and error support';

  @override
  String get supportContactBody =>
      'Email oopsidestudio@gmail.com with your device model, OS and version, the affected screen, and steps to reproduce the problem. If possible, attach a screenshot that does not show personal information.';

  @override
  String get supportResetTitle => 'Reset local progress';

  @override
  String get supportResetBody =>
      'Choose Reset Data in POPPOP Settings to erase Stage progress, scores, Endless Pop records, coins, purchased and equipped items, nickname, and settings on that device. On the web, you can also clear the browser\'s site data. A local reset does not delete online leaderboard records.';

  @override
  String get supportRankingTitle => 'Online ranking issues';

  @override
  String get supportRankingBody =>
      'Check your network connection and use Refresh on the ranking screen. A best record that could not be sent may remain on the device and retry later. If the issue continues, include the category (Stage Challenge or 60-Second Pop), time, and affected screen in your email.';

  @override
  String get supportNicknameTitle => 'Safe nicknames';

  @override
  String get supportNicknameBody =>
      'Do not include a real name, school, phone number, email, address, or other identifying information in your nickname.';

  @override
  String get supportDeletionTitle => 'Request deletion of online data';

  @override
  String get supportDeletionBody =>
      'Copy the Support ID shown below. Email oopsidestudio@gmail.com with the subject ‘POPPOP Data Deletion Request’ and include the Support ID in the message. The Support ID is your anonymous Firebase UID and lets us distinguish the records to delete. Do not post it publicly. Without it, we may be unable to safely identify and delete the requested records.';

  @override
  String get supportDataDifferenceTitle => 'Server data and device data';

  @override
  String get supportDataDifferenceBody =>
      'A verified request deletes the Stage and 60-second leaderboard documents for that Support ID and the linked anonymous Firebase Authentication account identifier. Progress, coins, items, nickname, and settings stored on your device are not erased by an email request; use Reset Data or remove the app or site data yourself.';

  @override
  String get supportTimingTitle => 'Processing time';

  @override
  String get supportTimingBody =>
      'Verifiable requests are normally completed within 30 days. Deleted online data cannot be recovered.';

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
