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
    // errorCode에 따른 한국어 메시지 반환
    switch (errorCode) {
      case 1005:
        return '세션이 만료되었습니다. 다시 로그인해주세요.';
      case 1001:
        return '요청 형식이 올바르지 않습니다.';
      case 1002:
        return '필수 항목이 누락되었습니다.';
      case 1003:
        return '요청한 데이터를 찾을 수 없습니다.';
      case 1004:
        return '권한이 없습니다.';
      default:
        return message;
    }
  }
}

/// 네트워크 연결 관련 예외
class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = '네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요.'});

  @override
  String toString() => 'NetworkException: $message';

  String getUserMessage() => message;
}

/// 타임아웃 예외
class TimeoutException implements Exception {
  final String message;

  TimeoutException({this.message = '요청 시간이 초과되었습니다. 다시 시도해주세요.'});

  @override
  String toString() => 'TimeoutException: $message';

  String getUserMessage() => message;
}

/// 인증 관련 예외
class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException({this.message = '인증에 실패했습니다. 다시 로그인해주세요.'});

  @override
  String toString() => 'UnauthorizedException: $message';

  String getUserMessage() => message;
}

/// 서버 내부 오류 예외
class ServerException implements Exception {
  final int? statusCode;
  final String message;

  ServerException({
    this.statusCode,
    this.message = '서버에서 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
  });

  @override
  String toString() => 'ServerException(status: $statusCode): $message';

  String getUserMessage() => message;
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
    // errorCode별로 사용자 친화적인 메시지 반환
    // errorCode가 있으면 서버에서 전달한 message를 그대로 사용
    // 서버가 한국어 메시지를 제공하는 경우 그대로 반환
    if (errorCode != null) {
      return message;
    }

    // errorCode가 없는 경우 기본 메시지
    switch (errorCode) {
      case 1001:
        return '입력 형식이 올바르지 않습니다.';
      case 1002:
        return '필수 정보를 모두 입력해주세요.';
      case 1003:
        return '요청한 항목을 찾을 수 없습니다.';
      default:
        return message;
    }
  }
}

/// JSON 파싱 실패 예외
class ParseException implements Exception {
  final String message;

  ParseException({this.message = '데이터 처리 중 오류가 발생했습니다.'});

  @override
  String toString() => 'ParseException: $message';

  String getUserMessage() => message;
}