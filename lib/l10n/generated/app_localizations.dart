import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'POPPOP'**
  String get appTitle;

  /// No description provided for @pause.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In ko, this message translates to:
  /// **'계속하기'**
  String get resume;

  /// No description provided for @exit.
  ///
  /// In ko, this message translates to:
  /// **'끝내기'**
  String get exit;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @stage.
  ///
  /// In ko, this message translates to:
  /// **'Stage {stage}'**
  String stage(int stage);

  /// No description provided for @score.
  ///
  /// In ko, this message translates to:
  /// **'점수 {score}'**
  String score(int score);

  /// No description provided for @remaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 풍선 {count}'**
  String remaining(int count);

  /// No description provided for @timeSeconds.
  ///
  /// In ko, this message translates to:
  /// **'시간 {seconds}초'**
  String timeSeconds(int seconds);

  /// No description provided for @nicknameTitle.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 정해주세요 🎈'**
  String get nicknameTitle;

  /// No description provided for @nicknameSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'게임에서 사용할 이름이에요'**
  String get nicknameSubtitle;

  /// No description provided for @nicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 (2~10자)'**
  String get nicknameHint;

  /// No description provided for @nicknameValidation.
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 2자 이상 10자 이하로 입력해 주세요.'**
  String get nicknameValidation;

  /// No description provided for @start.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get start;

  /// No description provided for @rankingTitle.
  ///
  /// In ko, this message translates to:
  /// **'온라인 랭킹'**
  String get rankingTitle;

  /// No description provided for @stageChallenge.
  ///
  /// In ko, this message translates to:
  /// **'STAGE 도전'**
  String get stageChallenge;

  /// No description provided for @sixtySecondPop.
  ///
  /// In ko, this message translates to:
  /// **'60초 팝'**
  String get sixtySecondPop;

  /// No description provided for @challenge.
  ///
  /// In ko, this message translates to:
  /// **'도전하기'**
  String get challenge;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @rankingEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록된 기록이 없어요.'**
  String get rankingEmpty;

  /// No description provided for @rankingLoadError.
  ///
  /// In ko, this message translates to:
  /// **'랭킹을 불러오지 못했어요.'**
  String get rankingLoadError;

  /// No description provided for @rankingSaved.
  ///
  /// In ko, this message translates to:
  /// **'최고 기록을 온라인 랭킹에 반영했어요.'**
  String get rankingSaved;

  /// No description provided for @rankingPending.
  ///
  /// In ko, this message translates to:
  /// **'인터넷 연결 후 자동으로 다시 전송할게요.'**
  String get rankingPending;

  /// No description provided for @rankedStageExitTitle.
  ///
  /// In ko, this message translates to:
  /// **'랭킹 도전을 끝낼까요?'**
  String get rankedStageExitTitle;

  /// No description provided for @rankedStageExitBody.
  ///
  /// In ko, this message translates to:
  /// **'현재 점수와 도달 스테이지를 온라인 랭킹에 저장하고 종료할 수 있어요.'**
  String get rankedStageExitBody;

  /// No description provided for @rankedStageKeepPlaying.
  ///
  /// In ko, this message translates to:
  /// **'계속하기'**
  String get rankedStageKeepPlaying;

  /// No description provided for @rankedStageSaveExit.
  ///
  /// In ko, this message translates to:
  /// **'기록 저장하고 종료'**
  String get rankedStageSaveExit;

  /// No description provided for @rankedExitTitle.
  ///
  /// In ko, this message translates to:
  /// **'랭킹 도전 끝내기'**
  String get rankedExitTitle;

  /// No description provided for @rankedExitBody.
  ///
  /// In ko, this message translates to:
  /// **'중간에 끝내면 기록은 제출되지 않아요.'**
  String get rankedExitBody;

  /// No description provided for @gameExitTitle.
  ///
  /// In ko, this message translates to:
  /// **'게임 끝내기'**
  String get gameExitTitle;

  /// No description provided for @gameExitBody.
  ///
  /// In ko, this message translates to:
  /// **'현재 게임을 끝내고 홈으로 돌아갈까요?'**
  String get gameExitBody;

  /// No description provided for @endlessExitTitle.
  ///
  /// In ko, this message translates to:
  /// **'무한 팝 끝내기'**
  String get endlessExitTitle;

  /// No description provided for @endlessExitBody.
  ///
  /// In ko, this message translates to:
  /// **'현재 기록을 저장하고 도전을 끝낼까요?'**
  String get endlessExitBody;

  /// No description provided for @endlessInfo.
  ///
  /// In ko, this message translates to:
  /// **'무한 팝은 시간 제한 없이 원터치 풍선을 계속 터뜨리는 일반 모드예요. 온라인 랭킹에서는 STAGE 도전과 60초 팝 중 선택할 수 있으며, 랭킹 도전은 하단 랭킹 메뉴에서 시작해요.'**
  String get endlessInfo;

  /// No description provided for @allClear.
  ///
  /// In ko, this message translates to:
  /// **'ALL CLEAR'**
  String get allClear;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
