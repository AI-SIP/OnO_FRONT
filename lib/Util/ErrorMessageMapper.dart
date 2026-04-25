import '../Constants/ErrorMessages.dart';

class ErrorMessageMapper {
  static String byErrorCode({required int? errorCode, String? fallback}) {
    switch (errorCode) {
      case 1001:
        return ErrorMessages.requestInvalid;
      case 1002:
        return ErrorMessages.requiredFieldMissing;
      case 1003:
        return ErrorMessages.notFound;
      case 1004:
        return ErrorMessages.forbidden;
      case 1005:
        return ErrorMessages.sessionExpired;
      case 9001:
        return ErrorMessages.tagNameEmpty;
      case 9002:
        return ErrorMessages.tagNameTooLong;
      case 9003:
        return ErrorMessages.tagNotFound;
      case 9004:
        return ErrorMessages.tagUserUnmatched;
      case 9005:
        return ErrorMessages.tagLimitExceeded;
      default:
        return fallback ?? ErrorMessages.unknown;
    }
  }

  static String sanitizeRawMessage(
    String? raw, {
    String fallback = ErrorMessages.unknown,
  }) {
    final message = (raw ?? '').trim();
    if (message.isEmpty) return fallback;

    final lower = message.toLowerCase();
    if (_looksLikeTimeout(lower)) return ErrorMessages.timeout;
    if (_looksLikeNetwork(lower)) return ErrorMessages.network;
    if (_looksLikeAuth(lower)) return ErrorMessages.authRequired;
    if (_looksLikeServer(lower)) return ErrorMessages.server;
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
