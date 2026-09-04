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

  /// No description provided for @fakePenalty.
  ///
  /// In ko, this message translates to:
  /// **'-2초'**
  String get fakePenalty;

  /// No description provided for @allClear.
  ///
  /// In ko, this message translates to:
  /// **'ALL CLEAR'**
  String get allClear;

  /// No description provided for @back.
  ///
  /// In ko, this message translates to:
  /// **'뒤로가기'**
  String get back;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @reset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get reset;

  /// No description provided for @home.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get home;

  /// No description provided for @shop.
  ///
  /// In ko, this message translates to:
  /// **'상점'**
  String get shop;

  /// No description provided for @event.
  ///
  /// In ko, this message translates to:
  /// **'이벤트'**
  String get event;

  /// No description provided for @ranking.
  ///
  /// In ko, this message translates to:
  /// **'랭킹'**
  String get ranking;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In ko, this message translates to:
  /// **'도움말'**
  String get help;

  /// No description provided for @achievements.
  ///
  /// In ko, this message translates to:
  /// **'업적'**
  String get achievements;

  /// No description provided for @bestScore.
  ///
  /// In ko, this message translates to:
  /// **'최고 기록'**
  String get bestScore;

  /// No description provided for @lastScore.
  ///
  /// In ko, this message translates to:
  /// **'최근 기록'**
  String get lastScore;

  /// No description provided for @record.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get record;

  /// No description provided for @rank.
  ///
  /// In ko, this message translates to:
  /// **'순위'**
  String get rank;

  /// No description provided for @nickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nickname;

  /// No description provided for @notSet.
  ///
  /// In ko, this message translates to:
  /// **'설정 안 됨'**
  String get notSet;

  /// No description provided for @locked.
  ///
  /// In ko, this message translates to:
  /// **'잠김'**
  String get locked;

  /// No description provided for @inUse.
  ///
  /// In ko, this message translates to:
  /// **'사용 중'**
  String get inUse;

  /// No description provided for @use.
  ///
  /// In ko, this message translates to:
  /// **'사용하기'**
  String get use;

  /// No description provided for @playNow.
  ///
  /// In ko, this message translates to:
  /// **'바로 플레이'**
  String get playNow;

  /// No description provided for @goHome.
  ///
  /// In ko, this message translates to:
  /// **'홈으로'**
  String get goHome;

  /// No description provided for @coinPurchase.
  ///
  /// In ko, this message translates to:
  /// **'코인 충전'**
  String get coinPurchase;

  /// No description provided for @ownedCoins.
  ///
  /// In ko, this message translates to:
  /// **'보유 코인'**
  String get ownedCoins;

  /// No description provided for @coins.
  ///
  /// In ko, this message translates to:
  /// **'{count} 코인'**
  String coins(String count);

  /// No description provided for @purchaseComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'결제 기능 준비 중입니다.'**
  String get purchaseComingSoon;

  /// No description provided for @productsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'표시할 상품이 없습니다'**
  String get productsEmpty;

  /// No description provided for @previewClose.
  ///
  /// In ko, this message translates to:
  /// **'풍선 미리보기 닫기'**
  String get previewClose;

  /// No description provided for @productInUse.
  ///
  /// In ko, this message translates to:
  /// **'{name} 사용 중'**
  String productInUse(String name);

  /// No description provided for @productPurchased.
  ///
  /// In ko, this message translates to:
  /// **'{name} 구매 완료!'**
  String productPurchased(String name);

  /// No description provided for @productNotOwned.
  ///
  /// In ko, this message translates to:
  /// **'보유하지 않은 상품입니다.'**
  String get productNotOwned;

  /// No description provided for @coinsInsufficient.
  ///
  /// In ko, this message translates to:
  /// **'코인이 부족해요!'**
  String get coinsInsufficient;

  /// No description provided for @productAlreadyOwned.
  ///
  /// In ko, this message translates to:
  /// **'이미 보유한 상품입니다.'**
  String get productAlreadyOwned;

  /// No description provided for @productUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'현재 구매할 수 없는 상품입니다.'**
  String get productUnavailable;

  /// No description provided for @equippedDone.
  ///
  /// In ko, this message translates to:
  /// **'착용 완료!'**
  String get equippedDone;

  /// No description provided for @buyPrice.
  ///
  /// In ko, this message translates to:
  /// **'{price} 구매'**
  String buyPrice(int price);

  /// No description provided for @filterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get filterAll;

  /// No description provided for @filterOwned.
  ///
  /// In ko, this message translates to:
  /// **'보유'**
  String get filterOwned;

  /// No description provided for @filterUnowned.
  ///
  /// In ko, this message translates to:
  /// **'미보유'**
  String get filterUnowned;

  /// No description provided for @filterLimited.
  ///
  /// In ko, this message translates to:
  /// **'한정'**
  String get filterLimited;

  /// No description provided for @rarityCommon.
  ///
  /// In ko, this message translates to:
  /// **'일반'**
  String get rarityCommon;

  /// No description provided for @rarityRare.
  ///
  /// In ko, this message translates to:
  /// **'희귀'**
  String get rarityRare;

  /// No description provided for @rarityHeroic.
  ///
  /// In ko, this message translates to:
  /// **'영웅'**
  String get rarityHeroic;

  /// No description provided for @rarityLegendary.
  ///
  /// In ko, this message translates to:
  /// **'전설'**
  String get rarityLegendary;

  /// No description provided for @recommended.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get recommended;

  /// No description provided for @basicOwned.
  ///
  /// In ko, this message translates to:
  /// **'기본 보유'**
  String get basicOwned;

  /// No description provided for @soundEffects.
  ///
  /// In ko, this message translates to:
  /// **'효과음'**
  String get soundEffects;

  /// No description provided for @haptics.
  ///
  /// In ko, this message translates to:
  /// **'진동'**
  String get haptics;

  /// No description provided for @player.
  ///
  /// In ko, this message translates to:
  /// **'플레이어'**
  String get player;

  /// No description provided for @gameSettings.
  ///
  /// In ko, this message translates to:
  /// **'게임 설정'**
  String get gameSettings;

  /// No description provided for @information.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get information;

  /// No description provided for @terms.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get terms;

  /// No description provided for @privacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get privacy;

  /// No description provided for @contact.
  ///
  /// In ko, this message translates to:
  /// **'문의하기'**
  String get contact;

  /// No description provided for @version.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version}'**
  String version(String version);

  /// No description provided for @termsPending.
  ///
  /// In ko, this message translates to:
  /// **'정식 서비스 출시 전 이용약관이 제공될 예정입니다.'**
  String get termsPending;

  /// No description provided for @privacyPending.
  ///
  /// In ko, this message translates to:
  /// **'정식 서비스 출시 전 개인정보처리방침이 제공될 예정입니다.'**
  String get privacyPending;

  /// No description provided for @contactPending.
  ///
  /// In ko, this message translates to:
  /// **'문의 채널은 정식 출시 전 안내될 예정입니다.'**
  String get contactPending;

  /// No description provided for @dataReset.
  ///
  /// In ko, this message translates to:
  /// **'데이터 초기화'**
  String get dataReset;

  /// No description provided for @dataResetDone.
  ///
  /// In ko, this message translates to:
  /// **'게임 데이터가 초기화되었습니다.'**
  String get dataResetDone;

  /// No description provided for @dataResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'모든 게임 데이터를 초기화할까요?'**
  String get dataResetTitle;

  /// No description provided for @dataResetBody.
  ///
  /// In ko, this message translates to:
  /// **'코인, 구매한 풍선, 장착 상태, 닉네임 및 설정이 모두 초기화됩니다.'**
  String get dataResetBody;

  /// No description provided for @nicknameChange.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 변경'**
  String get nicknameChange;

  /// No description provided for @progressReset.
  ///
  /// In ko, this message translates to:
  /// **'진행 초기화'**
  String get progressReset;

  /// No description provided for @progressResetBody.
  ///
  /// In ko, this message translates to:
  /// **'저장된 진행 상태를 초기화할까요?'**
  String get progressResetBody;

  /// No description provided for @endlessPop.
  ///
  /// In ko, this message translates to:
  /// **'무한 팝'**
  String get endlessPop;

  /// No description provided for @endlessStart.
  ///
  /// In ko, this message translates to:
  /// **'도전 시작'**
  String get endlessStart;

  /// No description provided for @endlessRuleOneHit.
  ///
  /// In ko, this message translates to:
  /// **'모든 풍선은 한 번 터치하면 터져요.'**
  String get endlessRuleOneHit;

  /// No description provided for @endlessRuleNoLimit.
  ///
  /// In ko, this message translates to:
  /// **'시간 제한과 게임오버 없이 계속 터뜨릴 수 있어요.'**
  String get endlessRuleNoLimit;

  /// No description provided for @endlessRuleScore.
  ///
  /// In ko, this message translates to:
  /// **'풍선 1개마다 기록이 1 올라가요.'**
  String get endlessRuleScore;

  /// No description provided for @endlessRuleSave.
  ///
  /// In ko, this message translates to:
  /// **'끝내기를 누르면 현재 기록과 BEST가 저장돼요.'**
  String get endlessRuleSave;

  /// No description provided for @endlessRankingInfo.
  ///
  /// In ko, this message translates to:
  /// **'온라인 랭킹에서는 STAGE 도전 또는 60초 팝을 선택할 수 있어요. 하단 랭킹 메뉴에서 시작해 보세요.'**
  String get endlessRankingInfo;

  /// No description provided for @endlessLocked.
  ///
  /// In ko, this message translates to:
  /// **'Stage 30 완료 후 이용할 수 있어요.'**
  String get endlessLocked;

  /// No description provided for @endlessTitle.
  ///
  /// In ko, this message translates to:
  /// **'∞ (무한 팝)'**
  String get endlessTitle;

  /// No description provided for @endlessStartSemantic.
  ///
  /// In ko, this message translates to:
  /// **'무한 팝 시작'**
  String get endlessStartSemantic;

  /// No description provided for @endlessLockedSemantic.
  ///
  /// In ko, this message translates to:
  /// **'무한 팝 잠김'**
  String get endlessLockedSemantic;

  /// No description provided for @endlessInfoSemantic.
  ///
  /// In ko, this message translates to:
  /// **'무한 팝 설명'**
  String get endlessInfoSemantic;

  /// No description provided for @preparing.
  ///
  /// In ko, this message translates to:
  /// **'준비 중...'**
  String get preparing;

  /// No description provided for @nextStep.
  ///
  /// In ko, this message translates to:
  /// **'다음 단계 ▶'**
  String get nextStep;

  /// No description provided for @startShort.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get startShort;

  /// No description provided for @startScreen.
  ///
  /// In ko, this message translates to:
  /// **'시작 화면으로'**
  String get startScreen;

  /// No description provided for @endlessFinished.
  ///
  /// In ko, this message translates to:
  /// **'무한 팝 종료'**
  String get endlessFinished;

  /// No description provided for @currentRecord.
  ///
  /// In ko, this message translates to:
  /// **'현재 기록  {score}'**
  String currentRecord(int score);

  /// No description provided for @tryAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 도전'**
  String get tryAgain;

  /// No description provided for @timeUp.
  ///
  /// In ko, this message translates to:
  /// **'시간 끝!'**
  String get timeUp;

  /// No description provided for @gameComplete.
  ///
  /// In ko, this message translates to:
  /// **'게임 완료!'**
  String get gameComplete;

  /// No description provided for @finalScore.
  ///
  /// In ko, this message translates to:
  /// **'최종 점수'**
  String get finalScore;

  /// No description provided for @points.
  ///
  /// In ko, this message translates to:
  /// **'{score}점'**
  String points(int score);

  /// No description provided for @again.
  ///
  /// In ko, this message translates to:
  /// **'다시'**
  String get again;

  /// No description provided for @stageLockedSemantic.
  ///
  /// In ko, this message translates to:
  /// **'{title} STAGE 잠김'**
  String stageLockedSemantic(String title);

  /// No description provided for @stageStartSemantic.
  ///
  /// In ko, this message translates to:
  /// **'{title} STAGE 시작'**
  String stageStartSemantic(String title);

  /// No description provided for @stageOneDescription.
  ///
  /// In ko, this message translates to:
  /// **'기본 풍선 · 보스 도전!'**
  String get stageOneDescription;

  /// No description provided for @stageTwoDescription.
  ///
  /// In ko, this message translates to:
  /// **'2회 터치 풍선 · 더블 보스!'**
  String get stageTwoDescription;

  /// No description provided for @stageFakeDescription.
  ///
  /// In ko, this message translates to:
  /// **'가짜 풍선을 터뜨리지 마세요!'**
  String get stageFakeDescription;

  /// No description provided for @modeEndless.
  ///
  /// In ko, this message translates to:
  /// **'∞ 무한'**
  String get modeEndless;

  /// No description provided for @ribbonText.
  ///
  /// In ko, this message translates to:
  /// **'터치해서 터뜨려!'**
  String get ribbonText;

  /// No description provided for @rankingColumnRank.
  ///
  /// In ko, this message translates to:
  /// **'순위'**
  String get rankingColumnRank;

  /// No description provided for @rankingColumnNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get rankingColumnNickname;

  /// No description provided for @rankingColumnRecord.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get rankingColumnRecord;

  /// No description provided for @myBestNone.
  ///
  /// In ko, this message translates to:
  /// **'내 최고 기록  -'**
  String get myBestNone;

  /// No description provided for @myBest.
  ///
  /// In ko, this message translates to:
  /// **'내 최고 기록  {score}점 · {rank}'**
  String myBest(int score, String rank);

  /// No description provided for @outsideTop100.
  ///
  /// In ko, this message translates to:
  /// **'100위 밖'**
  String get outsideTop100;

  /// No description provided for @rankPosition.
  ///
  /// In ko, this message translates to:
  /// **'{rank}위'**
  String rankPosition(int rank);

  /// No description provided for @skinBasic.
  ///
  /// In ko, this message translates to:
  /// **'기본 풍선'**
  String get skinBasic;

  /// No description provided for @skinHeart.
  ///
  /// In ko, this message translates to:
  /// **'하트 풍선'**
  String get skinHeart;

  /// No description provided for @skinStar.
  ///
  /// In ko, this message translates to:
  /// **'별 풍선'**
  String get skinStar;

  /// No description provided for @skinFlower.
  ///
  /// In ko, this message translates to:
  /// **'꽃 풍선'**
  String get skinFlower;

  /// No description provided for @skinMochi.
  ///
  /// In ko, this message translates to:
  /// **'모찌'**
  String get skinMochi;

  /// No description provided for @skinWari.
  ///
  /// In ko, this message translates to:
  /// **'와리'**
  String get skinWari;

  /// No description provided for @skinKicks.
  ///
  /// In ko, this message translates to:
  /// **'KICKS'**
  String get skinKicks;

  /// No description provided for @skinBoo.
  ///
  /// In ko, this message translates to:
  /// **'BOO'**
  String get skinBoo;

  /// No description provided for @skinMugi.
  ///
  /// In ko, this message translates to:
  /// **'무기'**
  String get skinMugi;

  /// No description provided for @skinGemi.
  ///
  /// In ko, this message translates to:
  /// **'제미'**
  String get skinGemi;

  /// No description provided for @skinShushu.
  ///
  /// In ko, this message translates to:
  /// **'슈슈'**
  String get skinShushu;

  /// No description provided for @skinStarDescription.
  ///
  /// In ko, this message translates to:
  /// **'조용하지만 은근 튀는 편'**
  String get skinStarDescription;

  /// No description provided for @skinFlowerDescription.
  ///
  /// In ko, this message translates to:
  /// **'화사하고 기분파'**
  String get skinFlowerDescription;

  /// No description provided for @skinMochiDescription.
  ///
  /// In ko, this message translates to:
  /// **'겁 많고 호기심 많음'**
  String get skinMochiDescription;

  /// No description provided for @skinWariDescription.
  ///
  /// In ko, this message translates to:
  /// **'시원하고 자유분방함'**
  String get skinWariDescription;

  /// No description provided for @skinKicksDescription.
  ///
  /// In ko, this message translates to:
  /// **'활발하고 승부욕 강함'**
  String get skinKicksDescription;

  /// No description provided for @skinBooDescription.
  ///
  /// In ko, this message translates to:
  /// **'장난기 많고 살짝 겁쟁이'**
  String get skinBooDescription;

  /// No description provided for @skinMugiDescription.
  ///
  /// In ko, this message translates to:
  /// **'예민하고 까칠함'**
  String get skinMugiDescription;

  /// No description provided for @skinGemiDescription.
  ///
  /// In ko, this message translates to:
  /// **'차갑고 단단함'**
  String get skinGemiDescription;

  /// No description provided for @skinShushuDescription.
  ///
  /// In ko, this message translates to:
  /// **'달콤하고 엉뚱함'**
  String get skinShushuDescription;

  /// No description provided for @sectionMultiHitHeadline.
  ///
  /// In ko, this message translates to:
  /// **'단단한 풍선 등장!'**
  String get sectionMultiHitHeadline;

  /// No description provided for @sectionMultiHitRule1.
  ///
  /// In ko, this message translates to:
  /// **'풍선마다 2번 터치'**
  String get sectionMultiHitRule1;

  /// No description provided for @sectionMultiHitRule2.
  ///
  /// In ko, this message translates to:
  /// **'빠르게 모두 터뜨리기'**
  String get sectionMultiHitRule2;

  /// No description provided for @sectionFakeHeadline.
  ///
  /// In ko, this message translates to:
  /// **'가짜 풍선 등장!'**
  String get sectionFakeHeadline;

  /// No description provided for @sectionFakeRule1.
  ///
  /// In ko, this message translates to:
  /// **'가짜 풍선 터치 금지'**
  String get sectionFakeRule1;

  /// No description provided for @sectionFakeRule2.
  ///
  /// In ko, this message translates to:
  /// **'진짜 풍선만 터뜨리기'**
  String get sectionFakeRule2;

  /// No description provided for @timeInfinite.
  ///
  /// In ko, this message translates to:
  /// **'시간  ∞'**
  String get timeInfinite;

  /// No description provided for @refresh.
  ///
  /// In ko, this message translates to:
  /// **'새로고침'**
  String get refresh;

  /// No description provided for @rankingScore.
  ///
  /// In ko, this message translates to:
  /// **'{score} · {detail}'**
  String rankingScore(int score, String detail);

  /// No description provided for @reachedStage.
  ///
  /// In ko, this message translates to:
  /// **'STAGE {stage}'**
  String reachedStage(int stage);
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
