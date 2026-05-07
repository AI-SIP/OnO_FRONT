import '../Constants/ErrorMessages.dart';

class ErrorMessageMapper {
  static String? byErrorCodeOrNull(int? errorCode) {
    switch (errorCode) {
      case 1001:
        return ErrorMessages.invalidRefreshToken;
      case 1002:
        return ErrorMessages.refreshTokenNotFound;
      case 1003:
        return ErrorMessages.invalidAuthority;
      case 1004:
        return ErrorMessages.refreshTokenNotEqual;
      case 1005:
        return ErrorMessages.accessTokenExpired;
      case 1006:
        return ErrorMessages.refreshTokenExpired;
      case 1007:
        return ErrorMessages.authenticationFailed;
      case 1008:
        return ErrorMessages.accessDenied;
      case 1009:
        return ErrorMessages.invalidAccessToken;
      case 2001:
        return ErrorMessages.fileUploadFailed;
      case 3001:
        return ErrorMessages.userNotFound;
      case 4001:
        return ErrorMessages.problemNotFound;
      case 4002:
        return ErrorMessages.problemUserUnmatched;
      case 4003:
        return ErrorMessages.problemSolveImageAlreadyRegistered;
      case 4004:
        return ErrorMessages.problemAnalysisNotFound;
      case 4021:
        return ErrorMessages.problemSolveNotFound;
      case 4022:
        return ErrorMessages.problemSolveUserUnmatched;
      case 5001:
        return ErrorMessages.folderNotFound;
      case 5002:
        return ErrorMessages.folderUserUnmatched;
      case 5003:
        return ErrorMessages.rootFolderNotExist;
      case 5004:
        return ErrorMessages.rootFolderCannotRemove;
      case 6001:
        return ErrorMessages.practiceNoteNotFound;
      case 7001:
        return ErrorMessages.missionTypeNotFound;
      case 7002:
        return ErrorMessages.missionUserNotFound;
      case 8001:
        return ErrorMessages.fcmTokenNotFound;
      case 8002:
        return ErrorMessages.fcmSendFailed;
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
        return null;
    }
  }

  static String byErrorCode({required int? errorCode, String? fallback}) {
    return byErrorCodeOrNull(errorCode) ?? fallback ?? ErrorMessages.unknown;
  }

  static String sanitizeRawMessage(
    String? raw, {
    String fallback = ErrorMessages.unknown,
    bool allowRawMessage = false,
  }) {
    final message = (raw ?? '').trim();
    if (message.isEmpty) return fallback;

    final lower = message.toLowerCase();
    if (_looksLikeTimeout(lower)) return ErrorMessages.timeout;
    if (_looksLikeNetwork(lower)) return ErrorMessages.network;
    if (_looksLikeAuth(lower)) return ErrorMessages.authRequired;
    if (_looksLikeServer(lower)) return ErrorMessages.server;
    if (_looksLikeInternalRaw(lower)) return fallback;

    return allowRawMessage ? message : fallback;
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
        lower.contains('리프레시토큰') ||
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
