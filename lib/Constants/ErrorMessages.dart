class ErrorMessages {
  static const String unknown = '일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  static const String network = '네트워크 연결이 원활하지 않습니다. 인터넷 상태를 확인해주세요.';
  static const String timeout = '요청 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
  static const String authRequired = '로그인이 필요합니다. 다시 로그인해주세요.';
  static const String server = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  static const String badRequest = '요청을 처리할 수 없습니다. 입력값을 확인해주세요.';
  static const String parse = '데이터 처리 중 오류가 발생했습니다. 다시 시도해주세요.';
  static const String responseParse = '서버 응답 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';

  static const String requestInvalid = '요청 형식이 올바르지 않습니다.';
  static const String requiredFieldMissing = '필수 항목이 누락되었습니다.';
  static const String notFound = '요청한 데이터를 찾을 수 없습니다.';
  static const String forbidden = '권한이 없습니다.';
  static const String sessionExpired = '세션이 만료되었습니다. 다시 로그인해주세요.';

  static const String tagNameEmpty = '태그 이름을 입력해주세요.';
  static const String tagNameTooLong = '태그 이름은 30자 이하여야 합니다.';
  static const String tagNotFound = '유효하지 않은 태그입니다.';
  static const String tagUserUnmatched = '해당 태그에 접근할 수 없습니다.';
  static const String tagLimitExceeded = '문제당 태그는 최대 5개까지 설정할 수 있습니다.';
}
