// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'POPPOP';

  @override
  String get pause => '일시정지';

  @override
  String get resume => '계속하기';

  @override
  String get exit => '끝내기';

  @override
  String get cancel => '취소';

  @override
  String stage(int stage) {
    return 'Stage $stage';
  }

  @override
  String score(int score) {
    return '점수 $score';
  }

  @override
  String remaining(int count) {
    return '남은 풍선 $count';
  }

  @override
  String timeSeconds(int seconds) {
    return '시간 $seconds초';
  }

  @override
  String get nicknameTitle => '닉네임을 정해주세요 🎈';

  @override
  String get nicknameSubtitle => '게임에서 사용할 이름이에요';

  @override
  String get nicknameHint => '닉네임 (2~10자)';

  @override
  String get nicknameValidation => '닉네임은 2자 이상 10자 이하로 입력해 주세요.';

  @override
  String get start => '시작하기';

  @override
  String get rankingTitle => '온라인 랭킹';

  @override
  String get stageChallenge => 'STAGE 도전';

  @override
  String get sixtySecondPop => '60초 팝';

  @override
  String get challenge => '도전하기';

  @override
  String get retry => '다시 시도';

  @override
  String get rankingEmpty => '아직 등록된 기록이 없어요.';

  @override
  String get rankingLoadError => '랭킹을 불러오지 못했어요.';

  @override
  String get rankingSaved => '최고 기록을 온라인 랭킹에 반영했어요.';

  @override
  String get rankingPending => '인터넷 연결 후 자동으로 다시 전송할게요.';

  @override
  String get rankedStageExitTitle => '랭킹 도전을 끝낼까요?';

  @override
  String get rankedStageExitBody => '현재 점수와 도달 스테이지를 온라인 랭킹에 저장하고 종료할 수 있어요.';

  @override
  String get rankedStageKeepPlaying => '계속하기';

  @override
  String get rankedStageSaveExit => '기록 저장하고 종료';

  @override
  String get rankedExitTitle => '랭킹 도전 끝내기';

  @override
  String get rankedExitBody => '중간에 끝내면 기록은 제출되지 않아요.';

  @override
  String get gameExitTitle => '게임 끝내기';

  @override
  String get gameExitBody => '현재 게임을 끝내고 홈으로 돌아갈까요?';

  @override
  String get endlessExitTitle => '무한 팝 끝내기';

  @override
  String get endlessExitBody => '현재 기록을 저장하고 도전을 끝낼까요?';

  @override
  String get endlessInfo =>
      '무한 팝은 시간 제한 없이 원터치 풍선을 계속 터뜨리는 일반 모드예요. 온라인 랭킹에서는 STAGE 도전과 60초 팝 중 선택할 수 있으며, 랭킹 도전은 하단 랭킹 메뉴에서 시작해요.';

  @override
  String get fakePenalty => '-2초';

  @override
  String get allClear => 'ALL CLEAR';

  @override
  String get back => '뒤로가기';

  @override
  String get close => '닫기';

  @override
  String get confirm => '확인';

  @override
  String get save => '저장';

  @override
  String get reset => '초기화';

  @override
  String get home => '홈';

  @override
  String get shop => '상점';

  @override
  String get event => '이벤트';

  @override
  String get ranking => '랭킹';

  @override
  String get settings => '설정';

  @override
  String get help => '도움말';

  @override
  String get achievements => '업적';

  @override
  String get bestScore => '최고 기록';

  @override
  String get lastScore => '최근 기록';

  @override
  String get record => '기록';

  @override
  String get rank => '순위';

  @override
  String get nickname => '닉네임';

  @override
  String get notSet => '설정 안 됨';

  @override
  String get locked => '잠김';

  @override
  String get inUse => '사용 중';

  @override
  String get use => '사용하기';

  @override
  String get playNow => '바로 플레이';

  @override
  String get goHome => '홈으로';

  @override
  String get coinPurchase => '코인 충전';

  @override
  String get ownedCoins => '보유 코인';

  @override
  String coins(String count) {
    return '$count 코인';
  }

  @override
  String get purchaseComingSoon => '결제 기능 준비 중입니다.';

  @override
  String get productsEmpty => '표시할 상품이 없습니다';

  @override
  String get previewClose => '풍선 미리보기 닫기';

  @override
  String productInUse(String name) {
    return '$name 사용 중';
  }

  @override
  String productPurchased(String name) {
    return '$name 구매 완료!';
  }

  @override
  String get productNotOwned => '보유하지 않은 상품입니다.';

  @override
  String get coinsInsufficient => '코인이 부족해요!';

  @override
  String get productAlreadyOwned => '이미 보유한 상품입니다.';

  @override
  String get productUnavailable => '현재 구매할 수 없는 상품입니다.';

  @override
  String get equippedDone => '착용 완료!';

  @override
  String buyPrice(int price) {
    return '$price 구매';
  }

  @override
  String get filterAll => '전체';

  @override
  String get filterOwned => '보유';

  @override
  String get filterUnowned => '미보유';

  @override
  String get filterLimited => '한정';

  @override
  String get rarityCommon => '일반';

  @override
  String get rarityRare => '희귀';

  @override
  String get rarityHeroic => '영웅';

  @override
  String get rarityLegendary => '전설';

  @override
  String get recommended => '추천';

  @override
  String get basicOwned => '기본 보유';

  @override
  String get soundEffects => '효과음';

  @override
  String get haptics => '진동';

  @override
  String get player => '플레이어';

  @override
  String get gameSettings => '게임 설정';

  @override
  String get information => '정보';

  @override
  String get terms => '이용약관';

  @override
  String get privacy => '개인정보처리방침';

  @override
  String get contact => '문의하기';

  @override
  String version(String version) {
    return '버전 $version';
  }

  @override
  String get termsPending => '정식 서비스 출시 전 이용약관이 제공될 예정입니다.';

  @override
  String get privacyPending => '정식 서비스 출시 전 개인정보처리방침이 제공될 예정입니다.';

  @override
  String get contactPending => '문의 채널은 정식 출시 전 안내될 예정입니다.';

  @override
  String get dataReset => '데이터 초기화';

  @override
  String get dataResetDone => '게임 데이터가 초기화되었습니다.';

  @override
  String get dataResetTitle => '모든 게임 데이터를 초기화할까요?';

  @override
  String get dataResetBody => '코인, 구매한 풍선, 장착 상태, 닉네임 및 설정이 모두 초기화됩니다.';

  @override
  String get nicknameChange => '닉네임 변경';

  @override
  String get supportId => 'Support ID';

  @override
  String get supportIdDescription =>
      '온라인 랭킹 데이터 삭제를 요청할 때 이 ID를 함께 보내 주세요. 공개된 곳에는 게시하지 마세요.';

  @override
  String get copySupportId => 'Support ID 복사';

  @override
  String get supportIdCopied => 'Support ID를 복사했습니다.';

  @override
  String get supportIdError => 'Support ID를 불러오지 못했습니다. 네트워크 연결 후 다시 시도해 주세요.';

  @override
  String get linkOpenError => '페이지를 열지 못했습니다.';

  @override
  String get view => '확인';

  @override
  String get support => '고객지원';

  @override
  String get viewOnWeb => '웹에서 보기';

  @override
  String get emailSupport => '이메일 문의';

  @override
  String get supportEmailSubject => 'POPPOP 문의';

  @override
  String get privacyIntroduction =>
      '시행일: 2026년 9월 4일. 웁사이드 스튜디오(OOPSIDE STUDIO)는 POPPOP 운영에 필요한 최소한의 정보만 처리합니다.';

  @override
  String get privacyOperatorTitle => '운영자 및 연락처';

  @override
  String get privacyOperatorBody =>
      '운영자: 웁사이드 스튜디오(OOPSIDE STUDIO)\n이메일: oopsidestudio@gmail.com';

  @override
  String get privacyOnlineTitle => '온라인으로 전송되는 정보';

  @override
  String get privacyOnlineBody =>
      '온라인 랭킹을 열거나 기록을 제출하면 Firebase 익명 UID(Support ID), 닉네임, 점수, 서버 제출 시각, schema version을 처리합니다. STAGE 도전에는 도달 Stage와 완료 여부가 추가됩니다. 종목은 STAGE 및 60초 랭킹 collection으로 구분합니다.';

  @override
  String get privacyLocalTitle => '기기에만 저장되는 정보';

  @override
  String get privacyLocalBody =>
      'Stage 진행·해금 상태, 최근·최고 점수, 무한 팝 기록과 안내 확인 상태, 코인, 구매·장착 아이템, 닉네임과 온보딩 상태, 효과음·진동 설정은 브라우저 localStorage 또는 앱의 로컬 저장소에 보관합니다. 네트워크 오류 후 다시 전송할 최고 랭킹 기록도 기기에 일시 저장될 수 있습니다.';

  @override
  String get privacyFirebaseTitle => 'Firebase 사용 및 처리 목적';

  @override
  String get privacyFirebaseBody =>
      '온라인 랭킹에는 Google Firebase Authentication의 익명 인증과 Cloud Firestore를 사용합니다. 랭킹 제공, 최고 기록 갱신, 중복·잘못된 제출 방지, 고객지원 및 삭제 요청 처리를 위해 정보를 사용합니다. Firebase는 인증 보안과 부정 사용 방지를 위해 IP 주소와 user-agent 같은 기술 정보를 처리할 수 있습니다. 웹 앱은 GitHub Pages에서 제공됩니다. Analytics, Crashlytics, 광고 SDK를 사용하지 않으며 개인정보를 판매하거나 맞춤 광고 목적으로 공유하지 않습니다.';

  @override
  String get privacyNotCollectedTitle => '수집하지 않는 정보';

  @override
  String get privacyNotCollectedBody =>
      '정확한 위치, 카메라, 마이크, 사진, 연락처, 광고 식별자, 결제카드 정보는 수집하지 않으며 이메일·비밀번호 기반 계정을 만들지 않습니다.';

  @override
  String get privacyRetentionTitle => '보관 및 삭제';

  @override
  String get privacyRetentionBody =>
      '온라인 랭킹 기록과 익명 인증 식별자는 기록이 갱신되거나, 삭제를 요청하거나, 서비스 운영상 더 이상 필요하지 않을 때까지 보관합니다. 확인 가능한 삭제 요청은 원칙적으로 30일 이내 처리합니다. 기기 로컬 정보는 설정의 데이터 초기화, 브라우저 사이트 데이터 삭제 또는 앱 삭제로 제거할 수 있습니다. 운영자는 기기에만 저장된 정보를 원격으로 확인하거나 삭제할 수 없습니다.';

  @override
  String get privacyChildrenTitle => '어린이 이용자와 안전한 닉네임';

  @override
  String get privacyChildrenBody =>
      '닉네임에는 실명, 학교명, 전화번호, 이메일, 주소 등 본인이나 다른 사람을 알아볼 수 있는 정보를 사용하지 마세요. 보호자는 어린이의 온라인 랭킹 이용을 지도하고 필요하면 데이터 삭제를 요청할 수 있습니다.';

  @override
  String get privacySecurityTitle => '보안';

  @override
  String get privacySecurityBody =>
      '익명 인증, Firestore 보안 규칙, 제출 필드·점수 제한 등을 사용합니다. 다만 인터넷 전송이나 저장의 절대적인 안전을 보장할 수는 없습니다. Support ID는 공개 게시하지 마세요.';

  @override
  String get privacyContactTitle => '문의 및 방침 변경';

  @override
  String get privacyContactBody =>
      '서비스 또는 법적 요구가 바뀌면 방침과 시행일을 갱신합니다. 개인정보 또는 삭제 문의는 oopsidestudio@gmail.com으로 보내 주세요.';

  @override
  String get supportIntroduction =>
      'POPPOP 이용 중 문제가 있거나 데이터 삭제가 필요하면 웁사이드 스튜디오로 문의해 주세요.';

  @override
  String get supportContactTitle => '게임 이용 및 오류 문의';

  @override
  String get supportContactBody =>
      'oopsidestudio@gmail.com으로 사용 중인 기기 모델, OS와 버전, 문제가 발생한 화면, 재현 순서를 보내 주세요. 가능하면 개인정보가 보이지 않는 스크린샷도 함께 보내 주세요.';

  @override
  String get supportResetTitle => '로컬 진행도 초기화';

  @override
  String get supportResetBody =>
      'POPPOP 설정에서 데이터 초기화를 선택하면 해당 기기의 Stage 진행, 점수, 무한 팝 기록, 코인, 구매·장착 아이템, 닉네임 및 설정을 지울 수 있습니다. 웹에서는 브라우저 사이트 데이터를 지울 수도 있습니다. 로컬 초기화는 온라인 랭킹 기록을 삭제하지 않습니다.';

  @override
  String get supportRankingTitle => '온라인 랭킹 오류';

  @override
  String get supportRankingBody =>
      '네트워크 연결을 확인하고 랭킹 화면에서 새로고침을 사용해 주세요. 전송에 실패한 최고 기록은 기기에 보관되었다가 나중에 다시 전송될 수 있습니다. 문제가 계속되면 종목(STAGE 도전 또는 60초 팝), 발생 시각과 화면을 이메일에 적어 주세요.';

  @override
  String get supportNicknameTitle => '안전한 닉네임';

  @override
  String get supportNicknameBody =>
      '닉네임에는 실명, 학교명, 전화번호, 이메일, 주소 또는 다른 개인 식별 정보를 사용하지 마세요.';

  @override
  String get supportDeletionTitle => '온라인 데이터 삭제 요청';

  @override
  String get supportDeletionBody =>
      '아래 Support ID를 복사하세요. 제목을 ‘POPPOP 데이터 삭제 요청’으로 작성하고 본문에 Support ID를 붙여 oopsidestudio@gmail.com으로 보내 주세요. Support ID는 Firebase 익명 UID이며 삭제할 기록을 구분할 수 있습니다. 공개 게시하지 마세요. Support ID가 없으면 기록을 안전하게 특정하고 삭제하기 어려울 수 있습니다.';

  @override
  String get supportDataDifferenceTitle => '서버 데이터와 기기 데이터';

  @override
  String get supportDataDifferenceBody =>
      '확인된 요청으로 해당 Support ID의 STAGE·60초 랭킹 문서와 연결된 Firebase 익명 인증 계정 식별자를 삭제합니다. 진행도, 코인, 아이템, 닉네임과 설정 등 기기 로컬 정보는 이메일 요청으로 지워지지 않으므로 데이터 초기화 또는 앱·사이트 데이터 삭제를 직접 사용해 주세요.';

  @override
  String get supportTimingTitle => '처리 기간';

  @override
  String get supportTimingBody =>
      '확인 가능한 요청은 원칙적으로 30일 이내 처리합니다. 삭제한 온라인 데이터는 복구할 수 없습니다.';

  @override
  String get termsIntroduction =>
      '시행일: 2026년 9월 4일. 이 약관은 이용자와 보호자가 POPPOP 이용 규칙을 쉽게 이해할 수 있도록 안내합니다.';

  @override
  String get termsPurposeTitle => '1. 목적과 동의';

  @override
  String get termsPurposeBody =>
      '이 약관은 POPPOP을 이용할 때 적용되는 권리, 책임과 기본 규칙을 정합니다. 서비스를 이용하면 이 약관에 동의한 것으로 봅니다. 동의하지 않는 경우에는 서비스 이용을 중단해 주세요.';

  @override
  String get termsOperatorTitle => '2. 운영자 및 연락처';

  @override
  String get termsOperatorBody =>
      'POPPOP은 웁사이드 스튜디오(OOPSIDE STUDIO)가 운영합니다. 약관에 관한 문의는 oopsidestudio@gmail.com으로 보내 주세요.';

  @override
  String get termsEligibilityTitle => '3. 이용 자격과 미성년자';

  @override
  String get termsEligibilityBody =>
      '어린이도 POPPOP을 즐길 수 있습니다. 관계 법령에 따라 보호자의 동의가 필요한 미성년자는 보호자의 동의를 받은 뒤 이용해야 합니다. 보호자는 어린이와 함께 온라인 랭킹, 닉네임 및 정보 처리 안내를 확인해 주세요.';

  @override
  String get termsLicenseTitle => '4. POPPOP 이용 권한';

  @override
  String get termsLicenseBody =>
      '웁사이드 스튜디오는 이 약관을 지키는 범위에서 POPPOP을 비상업적 오락 목적으로 이용할 수 있는 제한적이고 개인적이며 비독점적·양도 불가능하고 철회 가능한 권한을 부여합니다. 이 권한은 게임이나 콘텐츠의 소유권을 이전하지 않습니다.';

  @override
  String get termsRankingTitle => '5. 닉네임과 온라인 랭킹';

  @override
  String get termsRankingBody =>
      '이용자는 적절한 닉네임을 선택해야 합니다. 실명, 학교명, 전화번호, 이메일, 주소 등 개인을 알아볼 수 있는 정보는 사용하지 마세요. 온라인 랭킹에는 닉네임과 게임 기록이 다른 이용자에게 표시될 수 있습니다. 약관을 위반했거나 유효하지 않은 기록은 삭제 또는 정정될 수 있습니다.';

  @override
  String get termsProhibitedTitle => '6. 금지 행위';

  @override
  String get termsProhibitedBody =>
      '점수나 진행도를 부정하게 조작하는 행위, 봇·자동화 도구·변조된 프로그램 또는 취약점을 이용하는 행위, 다른 이용자를 사칭하는 행위, 개인정보나 유해한 내용이 포함된 닉네임을 사용하는 행위, 서비스나 다른 이용자의 이용을 방해하는 행위, 게임·랭킹·관련 시스템에 무단 접근을 시도하는 행위를 금지합니다.';

  @override
  String get termsProgressTitle => '7. 게임 진행도와 로컬 저장';

  @override
  String get termsProgressBody =>
      '대부분의 진행도, 점수, 코인, 아이템, 닉네임과 설정은 이용자의 기기에 저장됩니다. 앱·브라우저 데이터 삭제, 앱 제거, 기기 변경 또는 데이터 초기화 시 사라질 수 있습니다. 웁사이드 스튜디오는 기기에만 저장된 정보를 원격으로 복구할 수 없습니다.';

  @override
  String get termsItemsTitle => '8. 코인과 디지털 아이템';

  @override
  String get termsItemsBody =>
      '코인과 디지털 아이템은 게임 안에서만 사용하는 콘텐츠입니다. 현금이나 결제 수단과 같은 가치가 없고, 양도·교환·현금 환전할 수 없으며, POPPOP 밖의 소유권을 의미하지 않습니다. 서비스 운영에 따라 제공 여부와 게임 균형은 합리적인 범위에서 변경될 수 있습니다.';

  @override
  String get termsPurchasesTitle => '9. 인앱결제';

  @override
  String get termsPurchasesBody =>
      '현재 POPPOP은 실제 현금으로 구매하는 기능을 제공하지 않습니다. 향후 인앱결제를 제공하는 경우 Apple App Store 또는 Google Play 결제 시스템을 이용하며, 가격과 조건은 구매 확정 전에 구매 화면에 표시합니다. 취소와 환불에는 관계 법령 및 해당 스토어 정책이 적용됩니다.';

  @override
  String get termsChangesTitle => '10. 서비스 변경·점검·종료';

  @override
  String get termsChangesBody =>
      '업데이트, 보안, 기술 문제, 법적 요구 또는 운영상 필요에 따라 서비스의 전부 또는 일부를 합리적인 범위에서 변경·일시 중단·점검 또는 종료할 수 있습니다. 가능한 경우 중요한 변경은 미리 안내합니다.';

  @override
  String get termsIntellectualPropertyTitle => '11. 지식재산권';

  @override
  String get termsIntellectualPropertyBody =>
      'POPPOP의 프로그램, 그래픽, 캐릭터, 명칭, 소리와 그 밖의 콘텐츠는 웁사이드 스튜디오가 보유하거나 허락을 받아 사용하며 관계 지식재산권 법령의 보호를 받습니다. 법에서 허용하는 경우를 제외하고 허락 없이 복제·배포·판매하거나 상업적으로 이용할 수 없습니다.';

  @override
  String get termsPrivacyTitle => '12. 개인정보';

  @override
  String get termsPrivacyBody =>
      '정보 처리에 관한 내용은 POPPOP 개인정보처리방침에서 안내합니다. 특히 온라인 랭킹을 이용하기 전에 이 약관과 함께 확인해 주세요.';

  @override
  String get termsLiabilityTitle => '13. 합리적인 책임 범위';

  @override
  String get termsLiabilityBody =>
      '안전하고 안정적인 서비스를 제공하기 위해 노력하지만 일시적인 중단, 기기별 문제, 네트워크 장애 또는 기기 로컬 데이터 손실이 발생할 수 있습니다. 법이 허용하는 범위에서 웁사이드 스튜디오의 고의 또는 중대한 과실 없이 발생한 손해에 대해서는 책임을 지지 않습니다. 이 약관은 관계 법령상 배제할 수 없는 소비자의 권리나 책임을 제한하지 않습니다.';

  @override
  String get termsRestrictionTitle => '14. 이용 제한';

  @override
  String get termsRestrictionBody =>
      '약관을 중대하게 또는 반복해서 위반하거나, 다른 이용자에게 피해를 주거나, 랭킹 기록을 조작하거나, 서비스 보안을 위협하는 경우 행위의 내용과 정도를 고려해 유효하지 않은 기록을 삭제하거나 온라인 기능 이용을 합리적인 범위에서 제한할 수 있습니다.';

  @override
  String get termsUpdatesTitle => '15. 약관 변경과 시행일';

  @override
  String get termsUpdatesBody =>
      '서비스 또는 법적 요구가 바뀌면 이 약관을 수정할 수 있습니다. 변경된 내용과 시행일은 앱과 공개 약관 페이지에 게시합니다. 시행일 이후 서비스를 계속 이용하면 변경된 약관이 적용됩니다.';

  @override
  String get termsLawTitle => '16. 준거법';

  @override
  String get termsLawBody =>
      '이 약관에는 대한민국 법률이 적용됩니다. 분쟁은 관계 법령과 절차에 따라 해결하며, 강행 법규가 보장하는 소비자 보호를 제한하지 않습니다.';

  @override
  String get termsContactTitle => '17. 문의';

  @override
  String get termsContactBody =>
      '약관 또는 POPPOP에 관한 문의는 웁사이드 스튜디오의 oopsidestudio@gmail.com으로 보내 주세요.';

  @override
  String get progressReset => '진행 초기화';

  @override
  String get progressResetBody => '저장된 진행 상태를 초기화할까요?';

  @override
  String get endlessPop => '무한 팝';

  @override
  String get endlessStart => '도전 시작';

  @override
  String get endlessRuleOneHit => '모든 풍선은 한 번 터치하면 터져요.';

  @override
  String get endlessRuleNoLimit => '시간 제한과 게임오버 없이 계속 터뜨릴 수 있어요.';

  @override
  String get endlessRuleScore => '풍선 1개마다 기록이 1 올라가요.';

  @override
  String get endlessRuleSave => '끝내기를 누르면 현재 기록과 BEST가 저장돼요.';

  @override
  String get endlessRankingInfo =>
      '온라인 랭킹에서는 STAGE 도전 또는 60초 팝을 선택할 수 있어요. 하단 랭킹 메뉴에서 시작해 보세요.';

  @override
  String get endlessLocked => 'Stage 30 완료 후 이용할 수 있어요.';

  @override
  String get endlessTitle => '∞ (무한 팝)';

  @override
  String get endlessStartSemantic => '무한 팝 시작';

  @override
  String get endlessLockedSemantic => '무한 팝 잠김';

  @override
  String get endlessInfoSemantic => '무한 팝 설명';

  @override
  String get preparing => '준비 중...';

  @override
  String get nextStep => '다음 단계 ▶';

  @override
  String get startShort => '시작';

  @override
  String get startScreen => '시작 화면으로';

  @override
  String get endlessFinished => '무한 팝 종료';

  @override
  String currentRecord(int score) {
    return '현재 기록  $score';
  }

  @override
  String get tryAgain => '다시 도전';

  @override
  String get timeUp => '시간 끝!';

  @override
  String get gameComplete => '게임 완료!';

  @override
  String get finalScore => '최종 점수';

  @override
  String points(int score) {
    return '$score점';
  }

  @override
  String get again => '다시';

  @override
  String stageLockedSemantic(String title) {
    return '$title STAGE 잠김';
  }

  @override
  String stageStartSemantic(String title) {
    return '$title STAGE 시작';
  }

  @override
  String get stageOneDescription => '기본 풍선 · 보스 도전!';

  @override
  String get stageTwoDescription => '2회 터치 풍선 · 더블 보스!';

  @override
  String get stageFakeDescription => '가짜 풍선을 터뜨리지 마세요!';

  @override
  String get modeEndless => '∞ 무한';

  @override
  String get ribbonText => '터치해서 터뜨려!';

  @override
  String get rankingColumnRank => '순위';

  @override
  String get rankingColumnNickname => '닉네임';

  @override
  String get rankingColumnRecord => '기록';

  @override
  String get myBestNone => '내 최고 기록  -';

  @override
  String myBest(int score, String rank) {
    return '내 최고 기록  $score점 · $rank';
  }

  @override
  String get outsideTop100 => '100위 밖';

  @override
  String rankPosition(int rank) {
    return '$rank위';
  }

  @override
  String get skinBasic => '기본 풍선';

  @override
  String get skinHeart => '하트 풍선';

  @override
  String get skinStar => '별 풍선';

  @override
  String get skinFlower => '꽃 풍선';

  @override
  String get skinMochi => '모찌';

  @override
  String get skinWari => '와리';

  @override
  String get skinKicks => 'KICKS';

  @override
  String get skinBoo => 'BOO';

  @override
  String get skinMugi => '무기';

  @override
  String get skinGemi => '제미';

  @override
  String get skinShushu => '슈슈';

  @override
  String get skinStarDescription => '조용하지만 은근 튀는 편';

  @override
  String get skinFlowerDescription => '화사하고 기분파';

  @override
  String get skinMochiDescription => '겁 많고 호기심 많음';

  @override
  String get skinWariDescription => '시원하고 자유분방함';

  @override
  String get skinKicksDescription => '활발하고 승부욕 강함';

  @override
  String get skinBooDescription => '장난기 많고 살짝 겁쟁이';

  @override
  String get skinMugiDescription => '예민하고 까칠함';

  @override
  String get skinGemiDescription => '차갑고 단단함';

  @override
  String get skinShushuDescription => '달콤하고 엉뚱함';

  @override
  String get sectionMultiHitHeadline => '단단한 풍선 등장!';

  @override
  String get sectionMultiHitRule1 => '풍선마다 2번 터치';

  @override
  String get sectionMultiHitRule2 => '빠르게 모두 터뜨리기';

  @override
  String get sectionFakeHeadline => '가짜 풍선 등장!';

  @override
  String get sectionFakeRule1 => '가짜 풍선 터치 금지';

  @override
  String get sectionFakeRule2 => '진짜 풍선만 터뜨리기';

  @override
  String get timeInfinite => '시간  ∞';

  @override
  String get refresh => '새로고침';

  @override
  String rankingScore(int score, String detail) {
    return '$score · $detail';
  }

  @override
  String reachedStage(int stage) {
    return 'STAGE $stage';
  }
}
