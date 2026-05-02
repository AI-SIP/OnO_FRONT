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

  static const String invalidRefreshToken = '유효하지 않은 리프레시토큰입니다.';
  static const String refreshTokenNotFound = '리프레시 토큰 정보를 찾을 수 없습니다.';
  static const String invalidAuthority = '유효하지 않은 권한입니다.';
  static const String refreshTokenNotEqual = '리프레시 토큰이 일치하지 않습니다.';
  static const String accessTokenExpired = '엑세스 토큰이 만료되었습니다.';
  static const String refreshTokenExpired = '리프레시 토큰이 만료되었습니다.';
  static const String authenticationFailed = '인증이 실패했습니다.';
  static const String accessDenied = '접근 권한이 없습니다.';
  static const String invalidAccessToken = '유효하지 않은 엑세스 토큰입니다.';

  static const String fileUploadFailed = '파일 업로드 중 문제가 발생했습니다.';

  static const String userNotFound = '사용자를 찾을 수 없습니다.';

  static const String problemNotFound = '문제를 찾을 수 없습니다.';
  static const String problemUserUnmatched = '문제 작성자가 아닙니다.';
  static const String problemSolveImageAlreadyRegistered =
      '이미 오늘의 복습을 완료한 문제입니다.';
  static const String problemAnalysisNotFound = '문제 분석 결과를 찾을 수 없습니다.';

  static const String problemSolveNotFound = '복습 기록을 찾을 수 없습니다.';
  static const String problemSolveUserUnmatched = '해당 복습 기록에 대한 권한이 없습니다.';

  static const String folderNotFound = '폴더를 찾을 수 없습니다.';
  static const String folderUserUnmatched = '폴더를 소유한 유저가 아닙니다.';
  static const String rootFolderNotExist = '루트 폴더가 존재하지 않습니다.';
  static const String rootFolderCannotRemove = '루트 폴더는 삭제할 수 없습니다.';

  static const String practiceNoteNotFound = '복습 세트를 찾을 수 없습니다.';

  static const String missionTypeNotFound = '잘못된 미션 종류입니다.';
  static const String missionUserNotFound = '해당하는 유저가 존재하지 않습니다.';

  static const String fcmTokenNotFound = 'Fcm Token을 찾을 수 없습니다.';
  static const String fcmSendFailed = 'Fcm 메시지 전송에 실패했습니다.';

  static const String tagNameEmpty = '태그 이름을 입력해주세요.';
  static const String tagNameTooLong = '태그 이름은 30자 이하여야 합니다.';
  static const String tagNotFound = '유효하지 않은 태그입니다.';
  static const String tagUserUnmatched = '해당 태그에 접근할 수 없습니다.';
  static const String tagLimitExceeded = '문제당 태그는 최대 5개까지 설정할 수 있습니다.';
}
