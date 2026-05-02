import '../Constants/ErrorMessages.dart';
import '../Util/ErrorMessageMapper.dart';

/// API 호출 중 발생하는 예외를 처리하기 위한 커스텀 예외 클래스들

/// 기본 API 예외 클래스
class ApiException implements Exception {
  final int? statusCode;
  final int? errorCode;
  final String message;

  ApiException({
    this.statusCode,
    this.errorCode,
    required this.message,
  });

  @override
  String toString() {
    if (statusCode != null && errorCode != null) {
      return 'ApiException(status: $statusCode, errorCode: $errorCode, message: $message)';
    }
    return 'ApiException: $message';
  }

  /// 사용자에게 표시할 메시지를 반환
  String getUserMessage() {
    return ErrorMessageMapper.byErrorCode(
      errorCode: errorCode,
      fallback: ErrorMessageMapper.sanitizeRawMessage(message),
    );
  }
}

/// 네트워크 연결 관련 예외
class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = ErrorMessages.network});

  @override
  String toString() => 'NetworkException: $message';

  String getUserMessage() =>
      ErrorMessageMapper.sanitizeRawMessage(message, fallback: message);
}

/// 타임아웃 예외
class TimeoutException implements Exception {
  final String message;

  TimeoutException({this.message = ErrorMessages.timeout});

  @override
  String toString() => 'TimeoutException: $message';

  String getUserMessage() =>
      ErrorMessageMapper.sanitizeRawMessage(message, fallback: message);
}

/// 인증 관련 예외
class UnauthorizedException implements Exception {
  final int? errorCode;
  final String message;

  UnauthorizedException({
    this.errorCode,
    this.message = ErrorMessages.authRequired,
  });

  @override
  String toString() => 'UnauthorizedException(errorCode: $errorCode): $message';

  String getUserMessage() => ErrorMessageMapper.byErrorCode(
        errorCode: errorCode,
        fallback: ErrorMessageMapper.sanitizeRawMessage(
          message,
          fallback: ErrorMessages.authRequired,
        ),
      );
}

/// 서버 내부 오류 예외
class ServerException implements Exception {
  final int? statusCode;
  final String message;

  ServerException({
    this.statusCode,
    this.message = ErrorMessages.server,
  });

  @override
  String toString() => 'ServerException(status: $statusCode): $message';

  String getUserMessage() => ErrorMessageMapper.sanitizeRawMessage(message,
      fallback: ErrorMessages.server);
}

/// 잘못된 요청 예외 (400번대 에러)
class BadRequestException implements Exception {
  final int? statusCode;
  final int? errorCode;
  final String message;

  BadRequestException({
    this.statusCode,
    this.errorCode,
    required this.message,
  });

  @override
  String toString() =>
      'BadRequestException(status: $statusCode, errorCode: $errorCode): $message';

  String getUserMessage() {
    return ErrorMessageMapper.byErrorCode(
      errorCode: errorCode,
      fallback: ErrorMessageMapper.sanitizeRawMessage(
        message,
        fallback: ErrorMessages.badRequest,
      ),
    );
  }
}

/// JSON 파싱 실패 예외
class ParseException implements Exception {
  final String message;

  ParseException({this.message = ErrorMessages.parse});

  @override
  String toString() => 'ParseException: $message';

  String getUserMessage() => ErrorMessageMapper.sanitizeRawMessage(message,
      fallback: ErrorMessages.parse);
}
