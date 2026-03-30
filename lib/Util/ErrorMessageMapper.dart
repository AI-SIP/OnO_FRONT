class ErrorMessageMapper {
  static const String _unknownError = '일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  static const String _networkError = '네트워크 연결이 원활하지 않습니다. 인터넷 상태를 확인해주세요.';
  static const String _timeoutError = '요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
  static const String _authError = '로그인이 필요합니다. 다시 로그인해주세요.';
  static const String _serverError = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  static String byErrorCode({required int? errorCode, String? fallback}) {
    switch (errorCode) {
      case 1001:
        return '요청 형식이 올바르지 않습니다.';
      case 1002:
        return '필수 항목이 누락되었습니다.';
      case 1003:
        return '요청한 데이터를 찾을 수 없습니다.';
      case 1004:
        return '권한이 없습니다.';
      case 1005:
        return '세션이 만료되었습니다. 다시 로그인해주세요.';
      case 9001:
        return '태그 이름을 입력해주세요.';
      case 9002:
        return '태그 이름은 30자 이하여야 합니다.';
      case 9003:
        return '유효하지 않은 태그입니다.';
      case 9004:
        return '해당 태그에 접근할 수 없습니다.';
      case 9005:
        return '문제당 태그는 최대 5개까지 설정할 수 있습니다.';
      default:
        return fallback ?? _unknownError;
    }
  }

  static String sanitizeRawMessage(
    String? raw, {
    String fallback = _unknownError,
  }) {
    final message = (raw ?? '').trim();
    if (message.isEmpty) return fallback;

    final lower = message.toLowerCase();
    if (_looksLikeTimeout(lower)) return _timeoutError;
    if (_looksLikeNetwork(lower)) return _networkError;
    if (_looksLikeAuth(lower)) return _authError;
    if (_looksLikeServer(lower)) return _serverError;
    if (_looksLikeInternalRaw(lower)) return fallback;

    return message;
  }

  static bool _looksLikeTimeout(String lower) {
    return lower.contains('timeoutexception') ||
        lower.contains('future not completed') ||
        lower.contains('요청 시간이 초과');
  }

  static bool _looksLikeNetwork(String lower) {
    return lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('networkexception') ||
        lower.contains('xmlhttprequest error') ||
        lower.contains('network is unreachable');
  }

  static bool _looksLikeAuth(String lower) {
    return lower.contains('unauthorizedexception') ||
        lower.contains('authorization token') ||
        lower.contains('refresh token') ||
        lower.contains('로그인이 필요') ||
        lower.contains('세션이 만료');
  }

  static bool _looksLikeServer(String lower) {
    return lower.contains('serverexception') ||
        lower.contains('status: 5') ||
        lower.contains('http 5');
  }

  static bool _looksLikeInternalRaw(String lower) {
    return lower.contains('exception:') ||
        lower.contains('response:') ||
        lower.contains('uri=') ||
        lower.contains('json parsing failed') ||
        lower.contains('failed to parse response') ||
        lower.contains('unknown error:') ||
        lower.contains('{') ||
        lower.contains('<!doctype html');
  }
}
