import 'package:flutter/foundation.dart';

@immutable
class StageIntroDefinition {
  const StageIntroDefinition({
    required this.title,
    required this.headline,
    required this.rules,
  });

  final String title;
  final String headline;
  final List<String> rules;
}

const stageIntroDefinitions = <int, StageIntroDefinition>{
  11: StageIntroDefinition(
    title: 'STAGE 11–20',
    headline: '단단한 풍선 등장!',
    rules: ['풍선마다 2번 터치', '빠르게 모두 터뜨리기'],
  ),
  21: StageIntroDefinition(
    title: 'STAGE 21–30',
    headline: '가짜 풍선 등장!',
    rules: ['가짜 풍선 터치 금지', '진짜 풍선만 터뜨리기'],
  ),
  31: StageIntroDefinition(
    title: 'STAGE 31–40',
    headline: '분열 풍선 등장!',
    rules: ['터뜨리면 작은 풍선으로 분열', '분열된 풍선까지 모두 터뜨리기'],
  ),
  41: StageIntroDefinition(
    title: 'STAGE 41–50',
    headline: '숫자 풍선 등장!',
    rules: ['풍선에 숫자 표시', '숫자 순서대로 터뜨리기'],
  ),
};
