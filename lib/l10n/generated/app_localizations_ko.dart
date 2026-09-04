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
  String get allClear => 'ALL CLEAR';
}
