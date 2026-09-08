import 'package:unorm_dart/unorm_dart.dart' as unicode;

enum NicknameInvalidReason {
  empty,
  length,
  characters,
  unsafe,
  personalInformation,
  meaningless,
}

class NicknameValidation {
  const NicknameValidation.valid(this.normalized) : reason = null;
  const NicknameValidation.invalid(this.reason) : normalized = null;

  final String? normalized;
  final NicknameInvalidReason? reason;
  bool get isValid => normalized != null;
}

/// Client-side copy of the nickname policy. The Functions backend applies the
/// same checks independently and remains the final authority.
abstract final class RankingNickname {
  static const fallback = 'POPPOP 플레이어';
  static const minimumLength = 2;
  static const maximumLength = 16;

  static final _unsafeCodePoints = RegExp(
    r'[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u202A-\u202E\u2060\u2066-\u2069\uFEFF]',
  );
  static final _allowed = RegExp(r'^[가-힣A-Za-z0-9 ]+$');
  static final _email = RegExp(
    r'(?:[a-z0-9][a-z0-9._%+\-]{0,63})\s*(?:@|\bat\b)\s*[a-z0-9\-]+(?:\s*\.\s*[a-z]{2,}|\s+dot\s+[a-z]{2,})',
    caseSensitive: false,
  );
  static final _url = RegExp(
    r'(?:https?\s*:\s*//|www\s*\.|[a-z0-9\-]+\s*\.\s*(?:com|net|org|kr|io|gg)\b)',
    caseSensitive: false,
  );
  static final _school = RegExp(
    r'(?:학교|초등|중학교|고등학교|대학교|school|academy)',
    caseSensitive: false,
  );
  static final _social = RegExp(
    r'(?:@|instagram|insta|discord|telegram|kakao|카톡|오픈채팅|텔레그램|디엠|dm)',
    caseSensitive: false,
  );

  // These remain private so an error never reveals a usable evasion list.
  static const _blockedFragments = <String>{
    'fuck',
    'shit',
    'bitch',
    'cunt',
    'nigger',
    'nigga',
    'whore',
    'slut',
    'porn',
    'rape',
    'killurself',
    '씨발',
    '병신',
    '개새끼',
    '개색기',
    '좆',
    '보지',
    '자지',
    '섹스',
    '강간',
    '창녀',
    '김치녀',
    '한남충',
    '한녀충',
    '죽어버려',
  };
  static const _blockedWhole = <String>{
    'admin',
    'administrator',
    'operator',
    'moderator',
    '운영자',
    '관리자',
    '시발',
    'sex',
    'nazi',
    'kys',
    '죽어',
    '꺼져',
    '자살',
  };

  static NicknameValidation validate(String? value) {
    final raw = value ?? '';
    if (_unsafeCodePoints.hasMatch(raw)) {
      return const NicknameValidation.invalid(
        NicknameInvalidReason.characters,
      );
    }
    final normalized = unicode.nfkc(raw).trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return const NicknameValidation.invalid(NicknameInvalidReason.empty);
    }
    if (normalized.length < minimumLength ||
        normalized.length > maximumLength) {
      return const NicknameValidation.invalid(NicknameInvalidReason.length);
    }
    if (_containsPersonalInformation(normalized)) {
      return const NicknameValidation.invalid(
        NicknameInvalidReason.personalInformation,
      );
    }
    if (!_allowed.hasMatch(normalized)) {
      return const NicknameValidation.invalid(
        NicknameInvalidReason.characters,
      );
    }
    final moderationKey = _moderationKey(normalized);
    if (_blockedWhole.contains(moderationKey) ||
        _blockedFragments.any(moderationKey.contains)) {
      return const NicknameValidation.invalid(NicknameInvalidReason.unsafe);
    }
    if (_isMeaningless(moderationKey)) {
      return const NicknameValidation.invalid(
        NicknameInvalidReason.meaningless,
      );
    }
    return NicknameValidation.valid(normalized);
  }

  static String? normalize(String? value) => validate(value).normalized;

  /// Display-only compatibility fallback. Submission code rejects invalid
  /// names and must not use this method to bypass validation.
  static String sanitize(String? value) => normalize(value) ?? fallback;

  static bool _containsPersonalInformation(String value) {
    final lowered = value.toLowerCase();
    final digits = lowered.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 7 ||
        _email.hasMatch(lowered) ||
        _url.hasMatch(lowered) ||
        _social.hasMatch(lowered) ||
        _school.hasMatch(lowered);
  }

  static String _moderationKey(String value) {
    var key = value.toLowerCase().replaceAll(RegExp(r'[^가-힣a-z0-9]'), '');
    const substitutions = {
      '0': 'o',
      '1': 'i',
      '3': 'e',
      '4': 'a',
      '5': 's',
      '7': 't',
      '8': 'b',
      '9': 'g',
    };
    substitutions.forEach((from, to) => key = key.replaceAll(from, to));
    return key.replaceAllMapped(RegExp(r'(.)\1{2,}'), (match) => match[1]!);
  }

  static bool _isMeaningless(String value) {
    if (value.length >= 3 && value.split('').toSet().length == 1) return true;
    for (var unit = 1; unit <= 3; unit++) {
      if (value.length < unit * 3 || value.length % unit != 0) continue;
      final pattern = value.substring(0, unit);
      if (List.filled(value.length ~/ unit, pattern).join() == value) {
        return true;
      }
    }
    return false;
  }
}
