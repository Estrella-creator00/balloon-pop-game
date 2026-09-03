abstract final class RankingNickname {
  static const fallback = 'POPPOP 플레이어';
  static const maximumLength = 16;
  static const _blockedWords = <String>{
    'admin',
    'administrator',
    '운영자',
    '관리자',
    'fuck',
    'shit',
    '씨발',
    '시발',
  };

  static String sanitize(String? value) {
    final raw = value ?? '';
    if (RegExp(r'[\r\n\u0000-\u001F\u007F]').hasMatch(raw)) return fallback;
    final normalized = raw.trim().replaceAll(RegExp(r' +'), ' ');
    if (normalized.isEmpty ||
        normalized.length > maximumLength ||
        !RegExp(r'^[가-힣A-Za-z0-9 ]+$').hasMatch(normalized)) {
      return fallback;
    }
    final folded = normalized.toLowerCase().replaceAll(' ', '');
    if (_blockedWords.any(folded.contains)) return fallback;
    return normalized;
  }
}
