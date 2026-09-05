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

  /// No description provided for @supportId.
  ///
  /// In ko, this message translates to:
  /// **'Support ID'**
  String get supportId;

  /// No description provided for @supportIdDescription.
  ///
  /// In ko, this message translates to:
  /// **'온라인 랭킹 데이터 삭제를 요청할 때 이 ID를 함께 보내 주세요. 공개된 곳에는 게시하지 마세요.'**
  String get supportIdDescription;

  /// No description provided for @copySupportId.
  ///
  /// In ko, this message translates to:
  /// **'Support ID 복사'**
  String get copySupportId;

  /// No description provided for @supportIdCopied.
  ///
  /// In ko, this message translates to:
  /// **'Support ID를 복사했습니다.'**
  String get supportIdCopied;

  /// No description provided for @supportIdError.
  ///
  /// In ko, this message translates to:
  /// **'Support ID를 불러오지 못했습니다. 네트워크 연결 후 다시 시도해 주세요.'**
  String get supportIdError;

  /// No description provided for @linkOpenError.
  ///
  /// In ko, this message translates to:
  /// **'페이지를 열지 못했습니다.'**
  String get linkOpenError;

  /// No description provided for @view.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get view;

  /// No description provided for @support.
  ///
  /// In ko, this message translates to:
  /// **'고객지원'**
  String get support;

  /// No description provided for @viewOnWeb.
  ///
  /// In ko, this message translates to:
  /// **'웹에서 보기'**
  String get viewOnWeb;

  /// No description provided for @emailSupport.
  ///
  /// In ko, this message translates to:
  /// **'이메일 문의'**
  String get emailSupport;

  /// No description provided for @supportEmailSubject.
  ///
  /// In ko, this message translates to:
  /// **'POPPOP 문의'**
  String get supportEmailSubject;

  /// No description provided for @deleteOnlineData.
  ///
  /// In ko, this message translates to:
  /// **'온라인 데이터 삭제'**
  String get deleteOnlineData;

  /// No description provided for @deleteOnlineDataSemanticLabel.
  ///
  /// In ko, this message translates to:
  /// **'온라인 랭킹 기록과 익명 온라인 계정 삭제'**
  String get deleteOnlineDataSemanticLabel;

  /// No description provided for @onlineDataDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'온라인 데이터를 삭제할까요?'**
  String get onlineDataDeleteConfirmTitle;

  /// No description provided for @onlineDataDeleteConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'STAGE·60초 온라인 랭킹 기록과 익명 온라인 계정이 삭제됩니다. 기기에 저장된 Stage 진행도, 코인과 아이템은 삭제되지 않습니다. 삭제한 온라인 기록은 복구할 수 없습니다. 다시 랭킹을 사용하면 새로운 익명 계정으로 시작합니다.'**
  String get onlineDataDeleteConfirmBody;

  /// No description provided for @onlineDataDeleting.
  ///
  /// In ko, this message translates to:
  /// **'온라인 데이터 삭제 중…'**
  String get onlineDataDeleting;

  /// No description provided for @onlineDataDeleted.
  ///
  /// In ko, this message translates to:
  /// **'온라인 데이터 삭제 완료'**
  String get onlineDataDeleted;

  /// No description provided for @onlineDataDeletedDescription.
  ///
  /// In ko, this message translates to:
  /// **'온라인 랭킹 기록과 익명 온라인 계정을 삭제했습니다. 기기의 진행도, 코인과 아이템은 유지됩니다. 온라인 랭킹을 다시 사용할 때만 새 익명 계정이 생성됩니다.'**
  String get onlineDataDeletedDescription;

  /// No description provided for @onlineDataDeleteSuccess.
  ///
  /// In ko, this message translates to:
  /// **'온라인 데이터를 삭제했습니다.'**
  String get onlineDataDeleteSuccess;

  /// No description provided for @onlineDataDeleteOffline.
  ///
  /// In ko, this message translates to:
  /// **'연결할 수 없습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.'**
  String get onlineDataDeleteOffline;

  /// No description provided for @onlineDataDeleteUnauthenticated.
  ///
  /// In ko, this message translates to:
  /// **'온라인 계정을 확인할 수 없습니다. 랭킹을 한 번 연 뒤 다시 시도해 주세요.'**
  String get onlineDataDeleteUnauthenticated;

  /// No description provided for @onlineDataDeleteServerError.
  ///
  /// In ko, this message translates to:
  /// **'온라인 데이터를 삭제하지 못했습니다. 다시 시도해 주세요.'**
  String get onlineDataDeleteServerError;

  /// No description provided for @privacyIntroduction.
  ///
  /// In ko, this message translates to:
  /// **'시행일: 2026년 9월 4일. 웁사이드 스튜디오(OOPSIDE STUDIO)는 POPPOP 운영에 필요한 최소한의 정보만 처리합니다.'**
  String get privacyIntroduction;

  /// No description provided for @privacyOperatorTitle.
  ///
  /// In ko, this message translates to:
  /// **'운영자 및 연락처'**
  String get privacyOperatorTitle;

  /// No description provided for @privacyOperatorBody.
  ///
  /// In ko, this message translates to:
  /// **'운영자: 웁사이드 스튜디오(OOPSIDE STUDIO)\n이메일: oopsidestudio@gmail.com'**
  String get privacyOperatorBody;

  /// No description provided for @privacyOnlineTitle.
  ///
  /// In ko, this message translates to:
  /// **'온라인으로 전송되는 정보'**
  String get privacyOnlineTitle;

  /// No description provided for @privacyOnlineBody.
  ///
  /// In ko, this message translates to:
  /// **'온라인 랭킹을 열거나 기록을 제출하면 Firebase는 인증과 서버 내부 소유자 확인을 위해 익명 UID(Support ID)를 처리합니다. 공개 STAGE·60초 랭킹 문서에는 닉네임, 점수, 서버 제출 시각과 schema version만 포함하며 STAGE 도전에는 도달 Stage와 완료 여부가 추가됩니다. UID와 Support ID는 공개 랭킹 필드나 문서 경로에 포함되지 않습니다.'**
  String get privacyOnlineBody;

  /// No description provided for @privacyLocalTitle.
  ///
  /// In ko, this message translates to:
  /// **'기기에만 저장되는 정보'**
  String get privacyLocalTitle;

  /// No description provided for @privacyLocalBody.
  ///
  /// In ko, this message translates to:
  /// **'Stage 진행·해금 상태, 최근·최고 점수, 무한 팝 기록과 안내 확인 상태, 코인, 구매·장착 아이템, 닉네임과 온보딩 상태, 효과음·진동 설정은 브라우저 localStorage 또는 앱의 로컬 저장소에 보관합니다. 네트워크 오류 후 다시 전송할 최고 랭킹 기록도 기기에 일시 저장될 수 있습니다.'**
  String get privacyLocalBody;

  /// No description provided for @privacyFirebaseTitle.
  ///
  /// In ko, this message translates to:
  /// **'Firebase 사용 및 처리 목적'**
  String get privacyFirebaseTitle;

  /// No description provided for @privacyFirebaseBody.
  ///
  /// In ko, this message translates to:
  /// **'온라인 랭킹에는 Google Firebase Authentication의 익명 인증과 Cloud Firestore를 사용합니다. 랭킹 제공, 최고 기록 갱신, 중복·잘못된 제출 방지, 고객지원 및 삭제 요청 처리를 위해 정보를 사용합니다. Firebase는 인증 보안과 부정 사용 방지를 위해 IP 주소와 user-agent 같은 기술 정보를 처리할 수 있습니다. 웹 앱은 GitHub Pages에서 제공됩니다. Analytics, Crashlytics, 광고 SDK를 사용하지 않으며 개인정보를 판매하거나 맞춤 광고 목적으로 공유하지 않습니다.'**
  String get privacyFirebaseBody;

  /// No description provided for @privacyNotCollectedTitle.
  ///
  /// In ko, this message translates to:
  /// **'수집하지 않는 정보'**
  String get privacyNotCollectedTitle;

  /// No description provided for @privacyNotCollectedBody.
  ///
  /// In ko, this message translates to:
  /// **'정확한 위치, 카메라, 마이크, 사진, 연락처, 광고 식별자, 결제카드 정보는 수집하지 않으며 이메일·비밀번호 기반 계정을 만들지 않습니다.'**
  String get privacyNotCollectedBody;

  /// No description provided for @privacyRetentionTitle.
  ///
  /// In ko, this message translates to:
  /// **'보관 및 삭제'**
  String get privacyRetentionTitle;

  /// No description provided for @privacyRetentionBody.
  ///
  /// In ko, this message translates to:
  /// **'온라인 랭킹 기록과 익명 인증 식별자는 기록이 갱신되거나, 앱에서 삭제하거나, 이메일로 삭제를 요청하거나, 서비스 운영상 더 이상 필요하지 않을 때까지 보관합니다. 고객지원의 온라인 데이터 삭제를 사용하면 직접 삭제할 수 있습니다. 이메일 요청도 보조 방법으로 유지하며 확인 가능한 요청은 원칙적으로 30일 이내 처리합니다. 기기 로컬 정보는 설정의 데이터 초기화, 브라우저 사이트 데이터 삭제 또는 앱 삭제로 제거할 수 있습니다. 운영자는 기기에만 저장된 정보를 원격으로 확인하거나 삭제할 수 없습니다.'**
  String get privacyRetentionBody;

  /// No description provided for @privacyChildrenTitle.
  ///
  /// In ko, this message translates to:
  /// **'어린이 이용자와 안전한 닉네임'**
  String get privacyChildrenTitle;

  /// No description provided for @privacyChildrenBody.
  ///
  /// In ko, this message translates to:
  /// **'닉네임에는 실명, 학교명, 전화번호, 이메일, 주소 등 본인이나 다른 사람을 알아볼 수 있는 정보를 사용하지 마세요. 보호자는 어린이의 온라인 랭킹 이용을 지도하고 필요하면 데이터 삭제를 요청할 수 있습니다.'**
  String get privacyChildrenBody;

  /// No description provided for @privacySecurityTitle.
  ///
  /// In ko, this message translates to:
  /// **'보안'**
  String get privacySecurityTitle;

  /// No description provided for @privacySecurityBody.
  ///
  /// In ko, this message translates to:
  /// **'익명 인증, Firestore 보안 규칙, 제출 필드·점수 제한 등을 사용합니다. 다만 인터넷 전송이나 저장의 절대적인 안전을 보장할 수는 없습니다. Support ID는 공개 게시하지 마세요.'**
  String get privacySecurityBody;

  /// No description provided for @privacyContactTitle.
  ///
  /// In ko, this message translates to:
  /// **'문의 및 방침 변경'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In ko, this message translates to:
  /// **'서비스 또는 법적 요구가 바뀌면 방침과 시행일을 갱신합니다. 개인정보 또는 삭제 문의는 oopsidestudio@gmail.com으로 보내 주세요.'**
  String get privacyContactBody;

  /// No description provided for @supportIntroduction.
  ///
  /// In ko, this message translates to:
  /// **'POPPOP 이용 중 문제가 있거나 데이터 삭제가 필요하면 웁사이드 스튜디오로 문의해 주세요.'**
  String get supportIntroduction;

  /// No description provided for @supportContactTitle.
  ///
  /// In ko, this message translates to:
  /// **'게임 이용 및 오류 문의'**
  String get supportContactTitle;

  /// No description provided for @supportContactBody.
  ///
  /// In ko, this message translates to:
  /// **'oopsidestudio@gmail.com으로 사용 중인 기기 모델, OS와 버전, 문제가 발생한 화면, 재현 순서를 보내 주세요. 가능하면 개인정보가 보이지 않는 스크린샷도 함께 보내 주세요.'**
  String get supportContactBody;

  /// No description provided for @supportResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'로컬 진행도 초기화'**
  String get supportResetTitle;

  /// No description provided for @supportResetBody.
  ///
  /// In ko, this message translates to:
  /// **'POPPOP 설정에서 데이터 초기화를 선택하면 해당 기기의 Stage 진행, 점수, 무한 팝 기록, 코인, 구매·장착 아이템, 닉네임 및 설정을 지울 수 있습니다. 웹에서는 브라우저 사이트 데이터를 지울 수도 있습니다. 로컬 초기화는 온라인 랭킹 기록을 삭제하지 않습니다.'**
  String get supportResetBody;

  /// No description provided for @supportRankingTitle.
  ///
  /// In ko, this message translates to:
  /// **'온라인 랭킹 오류'**
  String get supportRankingTitle;

  /// No description provided for @supportRankingBody.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인하고 랭킹 화면에서 새로고침을 사용해 주세요. 전송에 실패한 최고 기록은 기기에 보관되었다가 나중에 다시 전송될 수 있습니다. 문제가 계속되면 종목(STAGE 도전 또는 60초 팝), 발생 시각과 화면을 이메일에 적어 주세요.'**
  String get supportRankingBody;

  /// No description provided for @supportNicknameTitle.
  ///
  /// In ko, this message translates to:
  /// **'안전한 닉네임'**
  String get supportNicknameTitle;

  /// No description provided for @supportNicknameBody.
  ///
  /// In ko, this message translates to:
  /// **'닉네임에는 실명, 학교명, 전화번호, 이메일, 주소 또는 다른 개인 식별 정보를 사용하지 마세요.'**
  String get supportNicknameBody;

  /// No description provided for @supportDeletionTitle.
  ///
  /// In ko, this message translates to:
  /// **'온라인 데이터 삭제'**
  String get supportDeletionTitle;

  /// No description provided for @supportDeletionBody.
  ///
  /// In ko, this message translates to:
  /// **'아래 온라인 데이터 삭제 버튼을 사용하면 STAGE·60초 랭킹 기록과 Firebase 익명 계정을 직접 삭제할 수 있습니다. 이메일 방식도 사용할 수 있습니다. 제목을 ‘POPPOP 데이터 삭제 요청’으로 작성하고 아래 Support ID를 oopsidestudio@gmail.com으로 보내 주세요. Support ID는 Firebase와 서버 내부에서 기록을 식별할 때 비공개로 처리되며 공개 랭킹 문서에는 포함되지 않습니다. 공개 게시하지 마세요.'**
  String get supportDeletionBody;

  /// No description provided for @supportDataDifferenceTitle.
  ///
  /// In ko, this message translates to:
  /// **'서버 데이터와 기기 데이터'**
  String get supportDataDifferenceTitle;

  /// No description provided for @supportDataDifferenceBody.
  ///
  /// In ko, this message translates to:
  /// **'직접 삭제하면 STAGE·60초 공개 랭킹, 일치하는 기존 기록과 비공개 서버 기록, 연결된 Firebase 익명 인증 계정을 삭제합니다. 진행도, 코인, 아이템, 닉네임과 설정 등 기기 로컬 정보는 지워지지 않습니다. 삭제한 온라인 기록은 복구할 수 없으며 다시 랭킹을 사용하면 이전 계정과 연결되지 않은 새 익명 계정이 생성됩니다.'**
  String get supportDataDifferenceBody;

  /// No description provided for @supportTimingTitle.
  ///
  /// In ko, this message translates to:
  /// **'처리 기간'**
  String get supportTimingTitle;

  /// No description provided for @supportTimingBody.
  ///
  /// In ko, this message translates to:
  /// **'확인 가능한 요청은 원칙적으로 30일 이내 처리합니다. 삭제한 온라인 데이터는 복구할 수 없습니다.'**
  String get supportTimingBody;

  /// No description provided for @termsIntroduction.
  ///
  /// In ko, this message translates to:
  /// **'시행일: 2026년 9월 4일. 이 약관은 이용자와 보호자가 POPPOP 이용 규칙을 쉽게 이해할 수 있도록 안내합니다.'**
  String get termsIntroduction;

  /// No description provided for @termsPurposeTitle.
  ///
  /// In ko, this message translates to:
  /// **'1. 목적과 동의'**
  String get termsPurposeTitle;

  /// No description provided for @termsPurposeBody.
  ///
  /// In ko, this message translates to:
  /// **'이 약관은 POPPOP을 이용할 때 적용되는 권리, 책임과 기본 규칙을 정합니다. 서비스를 이용하면 이 약관에 동의한 것으로 봅니다. 동의하지 않는 경우에는 서비스 이용을 중단해 주세요.'**
  String get termsPurposeBody;

  /// No description provided for @termsOperatorTitle.
  ///
  /// In ko, this message translates to:
  /// **'2. 운영자 및 연락처'**
  String get termsOperatorTitle;

  /// No description provided for @termsOperatorBody.
  ///
  /// In ko, this message translates to:
  /// **'POPPOP은 웁사이드 스튜디오(OOPSIDE STUDIO)가 운영합니다. 약관에 관한 문의는 oopsidestudio@gmail.com으로 보내 주세요.'**
  String get termsOperatorBody;

  /// No description provided for @termsEligibilityTitle.
  ///
  /// In ko, this message translates to:
  /// **'3. 이용 자격과 미성년자'**
  String get termsEligibilityTitle;

  /// No description provided for @termsEligibilityBody.
  ///
  /// In ko, this message translates to:
  /// **'어린이도 POPPOP을 즐길 수 있습니다. 관계 법령에 따라 보호자의 동의가 필요한 미성년자는 보호자의 동의를 받은 뒤 이용해야 합니다. 보호자는 어린이와 함께 온라인 랭킹, 닉네임 및 정보 처리 안내를 확인해 주세요.'**
  String get termsEligibilityBody;

  /// No description provided for @termsLicenseTitle.
  ///
  /// In ko, this message translates to:
  /// **'4. POPPOP 이용 권한'**
  String get termsLicenseTitle;

  /// No description provided for @termsLicenseBody.
  ///
  /// In ko, this message translates to:
  /// **'웁사이드 스튜디오는 이 약관을 지키는 범위에서 POPPOP을 비상업적 오락 목적으로 이용할 수 있는 제한적이고 개인적이며 비독점적·양도 불가능하고 철회 가능한 권한을 부여합니다. 이 권한은 게임이나 콘텐츠의 소유권을 이전하지 않습니다.'**
  String get termsLicenseBody;

  /// No description provided for @termsRankingTitle.
  ///
  /// In ko, this message translates to:
  /// **'5. 닉네임과 온라인 랭킹'**
  String get termsRankingTitle;

  /// No description provided for @termsRankingBody.
  ///
  /// In ko, this message translates to:
  /// **'이용자는 적절한 닉네임을 선택해야 합니다. 실명, 학교명, 전화번호, 이메일, 주소 등 개인을 알아볼 수 있는 정보는 사용하지 마세요. 온라인 랭킹에는 닉네임과 게임 기록이 다른 이용자에게 표시될 수 있습니다. 약관을 위반했거나 유효하지 않은 기록은 삭제 또는 정정될 수 있습니다.'**
  String get termsRankingBody;

  /// No description provided for @termsProhibitedTitle.
  ///
  /// In ko, this message translates to:
  /// **'6. 금지 행위'**
  String get termsProhibitedTitle;

  /// No description provided for @termsProhibitedBody.
  ///
  /// In ko, this message translates to:
  /// **'점수나 진행도를 부정하게 조작하는 행위, 봇·자동화 도구·변조된 프로그램 또는 취약점을 이용하는 행위, 다른 이용자를 사칭하는 행위, 개인정보나 유해한 내용이 포함된 닉네임을 사용하는 행위, 서비스나 다른 이용자의 이용을 방해하는 행위, 게임·랭킹·관련 시스템에 무단 접근을 시도하는 행위를 금지합니다.'**
  String get termsProhibitedBody;

  /// No description provided for @termsProgressTitle.
  ///
  /// In ko, this message translates to:
  /// **'7. 게임 진행도와 로컬 저장'**
  String get termsProgressTitle;

  /// No description provided for @termsProgressBody.
  ///
  /// In ko, this message translates to:
  /// **'대부분의 진행도, 점수, 코인, 아이템, 닉네임과 설정은 이용자의 기기에 저장됩니다. 앱·브라우저 데이터 삭제, 앱 제거, 기기 변경 또는 데이터 초기화 시 사라질 수 있습니다. 웁사이드 스튜디오는 기기에만 저장된 정보를 원격으로 복구할 수 없습니다.'**
  String get termsProgressBody;

  /// No description provided for @termsItemsTitle.
  ///
  /// In ko, this message translates to:
  /// **'8. 코인과 디지털 아이템'**
  String get termsItemsTitle;

  /// No description provided for @termsItemsBody.
  ///
  /// In ko, this message translates to:
  /// **'코인과 디지털 아이템은 게임 안에서만 사용하는 콘텐츠입니다. 현금이나 결제 수단과 같은 가치가 없고, 양도·교환·현금 환전할 수 없으며, POPPOP 밖의 소유권을 의미하지 않습니다. 서비스 운영에 따라 제공 여부와 게임 균형은 합리적인 범위에서 변경될 수 있습니다.'**
  String get termsItemsBody;

  /// No description provided for @termsPurchasesTitle.
  ///
  /// In ko, this message translates to:
  /// **'9. 인앱결제'**
  String get termsPurchasesTitle;

  /// No description provided for @termsPurchasesBody.
  ///
  /// In ko, this message translates to:
  /// **'현재 POPPOP은 실제 현금으로 구매하는 기능을 제공하지 않습니다. 향후 인앱결제를 제공하는 경우 Apple App Store 또는 Google Play 결제 시스템을 이용하며, 가격과 조건은 구매 확정 전에 구매 화면에 표시합니다. 취소와 환불에는 관계 법령 및 해당 스토어 정책이 적용됩니다.'**
  String get termsPurchasesBody;

  /// No description provided for @termsChangesTitle.
  ///
  /// In ko, this message translates to:
  /// **'10. 서비스 변경·점검·종료'**
  String get termsChangesTitle;

  /// No description provided for @termsChangesBody.
  ///
  /// In ko, this message translates to:
  /// **'업데이트, 보안, 기술 문제, 법적 요구 또는 운영상 필요에 따라 서비스의 전부 또는 일부를 합리적인 범위에서 변경·일시 중단·점검 또는 종료할 수 있습니다. 가능한 경우 중요한 변경은 미리 안내합니다.'**
  String get termsChangesBody;

  /// No description provided for @termsIntellectualPropertyTitle.
  ///
  /// In ko, this message translates to:
  /// **'11. 지식재산권'**
  String get termsIntellectualPropertyTitle;

  /// No description provided for @termsIntellectualPropertyBody.
  ///
  /// In ko, this message translates to:
  /// **'POPPOP의 프로그램, 그래픽, 캐릭터, 명칭, 소리와 그 밖의 콘텐츠는 웁사이드 스튜디오가 보유하거나 허락을 받아 사용하며 관계 지식재산권 법령의 보호를 받습니다. 법에서 허용하는 경우를 제외하고 허락 없이 복제·배포·판매하거나 상업적으로 이용할 수 없습니다.'**
  String get termsIntellectualPropertyBody;

  /// No description provided for @termsPrivacyTitle.
  ///
  /// In ko, this message translates to:
  /// **'12. 개인정보'**
  String get termsPrivacyTitle;

  /// No description provided for @termsPrivacyBody.
  ///
  /// In ko, this message translates to:
  /// **'정보 처리에 관한 내용은 POPPOP 개인정보처리방침에서 안내합니다. 특히 온라인 랭킹을 이용하기 전에 이 약관과 함께 확인해 주세요.'**
  String get termsPrivacyBody;

  /// No description provided for @termsLiabilityTitle.
  ///
  /// In ko, this message translates to:
  /// **'13. 합리적인 책임 범위'**
  String get termsLiabilityTitle;

  /// No description provided for @termsLiabilityBody.
  ///
  /// In ko, this message translates to:
  /// **'안전하고 안정적인 서비스를 제공하기 위해 노력하지만 일시적인 중단, 기기별 문제, 네트워크 장애 또는 기기 로컬 데이터 손실이 발생할 수 있습니다. 법이 허용하는 범위에서 웁사이드 스튜디오의 고의 또는 중대한 과실 없이 발생한 손해에 대해서는 책임을 지지 않습니다. 이 약관은 관계 법령상 배제할 수 없는 소비자의 권리나 책임을 제한하지 않습니다.'**
  String get termsLiabilityBody;

  /// No description provided for @termsRestrictionTitle.
  ///
  /// In ko, this message translates to:
  /// **'14. 이용 제한'**
  String get termsRestrictionTitle;

  /// No description provided for @termsRestrictionBody.
  ///
  /// In ko, this message translates to:
  /// **'약관을 중대하게 또는 반복해서 위반하거나, 다른 이용자에게 피해를 주거나, 랭킹 기록을 조작하거나, 서비스 보안을 위협하는 경우 행위의 내용과 정도를 고려해 유효하지 않은 기록을 삭제하거나 온라인 기능 이용을 합리적인 범위에서 제한할 수 있습니다.'**
  String get termsRestrictionBody;

  /// No description provided for @termsUpdatesTitle.
  ///
  /// In ko, this message translates to:
  /// **'15. 약관 변경과 시행일'**
  String get termsUpdatesTitle;

  /// No description provided for @termsUpdatesBody.
  ///
  /// In ko, this message translates to:
  /// **'서비스 또는 법적 요구가 바뀌면 이 약관을 수정할 수 있습니다. 변경된 내용과 시행일은 앱과 공개 약관 페이지에 게시합니다. 시행일 이후 서비스를 계속 이용하면 변경된 약관이 적용됩니다.'**
  String get termsUpdatesBody;

  /// No description provided for @termsLawTitle.
  ///
  /// In ko, this message translates to:
  /// **'16. 준거법'**
  String get termsLawTitle;

  /// No description provided for @termsLawBody.
  ///
  /// In ko, this message translates to:
  /// **'이 약관에는 대한민국 법률이 적용됩니다. 분쟁은 관계 법령과 절차에 따라 해결하며, 강행 법규가 보장하는 소비자 보호를 제한하지 않습니다.'**
  String get termsLawBody;

  /// No description provided for @termsContactTitle.
  ///
  /// In ko, this message translates to:
  /// **'17. 문의'**
  String get termsContactTitle;

  /// No description provided for @termsContactBody.
  ///
  /// In ko, this message translates to:
  /// **'약관 또는 POPPOP에 관한 문의는 웁사이드 스튜디오의 oopsidestudio@gmail.com으로 보내 주세요.'**
  String get termsContactBody;

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
