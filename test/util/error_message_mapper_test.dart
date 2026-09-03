import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Constants/ErrorMessages.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Util/ErrorMessageMapper.dart';

import '../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('ErrorMessageMapper', () {
    test('allows safe server messages when requested', () {
      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          '이미 사용 중인 이름입니다.',
          allowRawMessage: true,
        ),
        '이미 사용 중인 이름입니다.',
      );
    });

    test('falls back for internal-looking raw messages', () {
      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          'BadRequestException: invalid request',
          fallback: ErrorMessages.badRequest,
          allowRawMessage: true,
        ),
        ErrorMessages.badRequest,
      );
    });

    test('bad request exceptions prefer safe server messages over error code',
        () {
      final exception = BadRequestException(
        statusCode: 400,
        errorCode: 5001,
        message: '폴더 이름은 20자 이하여야 합니다.',
      );

      expect(exception.getUserMessage(), '폴더 이름은 20자 이하여야 합니다.');
    });

    test('bad request exceptions use error code mapping when message is empty',
        () {
      final exception = BadRequestException(
        statusCode: 400,
        errorCode: 5001,
        message: '',
      );

      expect(exception.getUserMessage(), ErrorMessages.folderNotFound);
    });
  });

  group('sanitizeRawMessage - 빈 입력', () {
    test('null 이면 fallback 을 쓴다', () {
      expect(
        ErrorMessageMapper.sanitizeRawMessage(null, fallback: '기본 문구'),
        '기본 문구',
      );
    });

    test('빈 문자열이면 fallback 을 쓴다', () {
      expect(
        ErrorMessageMapper.sanitizeRawMessage('', fallback: '기본 문구'),
        '기본 문구',
      );
    });

    test('공백만 있으면 fallback 을 쓴다 (trim 후 empty 판정)', () {
      expect(
        ErrorMessageMapper.sanitizeRawMessage('   \n\t  ', fallback: '기본 문구'),
        '기본 문구',
      );
    });

    test('fallback 을 생략하면 ErrorMessages.unknown 이 기본값이다', () {
      expect(ErrorMessageMapper.sanitizeRawMessage(''), ErrorMessages.unknown);
    });
  });

  group('sanitizeRawMessage - allowRawMessage 가 false 일 때', () {
    test('안전해 보이는 메시지여도 원문 대신 fallback 을 쓴다', () {
      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          '이미 사용 중인 이름입니다.',
          fallback: '기본 문구',
          allowRawMessage: false,
        ),
        '기본 문구',
      );
    });

    test('allowRawMessage 를 생략하면 기본값은 false 다', () {
      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          '이미 사용 중인 이름입니다.',
          fallback: '기본 문구',
        ),
        '기본 문구',
      );
    });

    test('패턴에 걸리는 메시지는 allowRawMessage 값과 무관하게 표준 문구로 바뀐다', () {
      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          'SocketException: Failed host lookup',
          fallback: '기본 문구',
          allowRawMessage: false,
        ),
        ErrorMessages.network,
      );
    });
  });

  group('sanitizeRawMessage - 패턴 감지', () {
    test('타임아웃 계열 영문 패턴을 인식한다', () {
      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          'TimeoutException after 30 seconds',
          allowRawMessage: true,
        ),
        ErrorMessages.timeout,
      );
    });

    test('타임아웃 계열 한글 패턴을 인식한다', () {
      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          '요청 시간이 초과되었습니다',
          allowRawMessage: true,
        ),
        ErrorMessages.timeout,
      );
    });

    test('네트워크 계열 패턴을 인식한다', () {
      for (final raw in [
        'SocketException: Connection refused',
        'Failed host lookup: api.ono.com',
        'NetworkException: no internet',
        'XMLHttpRequest error.',
        'Network is unreachable',
      ]) {
        expect(
          ErrorMessageMapper.sanitizeRawMessage(raw, allowRawMessage: true),
          ErrorMessages.network,
          reason: '"$raw" 는 네트워크 오류로 인식되어야 한다',
        );
      }
    });

    test('인증 계열 패턴을 인식한다', () {
      for (final raw in [
        'UnauthorizedException: no token',
        'Authorization token missing',
        'Refresh token expired',
        '리프레시토큰이 존재하지 않습니다',
        '로그인이 필요합니다',
        '세션이 만료되었습니다',
      ]) {
        expect(
          ErrorMessageMapper.sanitizeRawMessage(raw, allowRawMessage: true),
          ErrorMessages.authRequired,
          reason: '"$raw" 는 인증 오류로 인식되어야 한다',
        );
      }
    });

    test('서버 오류 계열 패턴을 인식한다', () {
      for (final raw in [
        'ServerException: internal error',
        'status: 500',
        'HTTP 502 Bad Gateway',
      ]) {
        expect(
          ErrorMessageMapper.sanitizeRawMessage(raw, allowRawMessage: true),
          ErrorMessages.server,
          reason: '"$raw" 는 서버 오류로 인식되어야 한다',
        );
      }
    });

    test('예외 클래스명(ClassName: message) 형태는 내부 정보로 보고 fallback 을 쓴다', () {
      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          'FormatException: invalid character',
          fallback: '기본 문구',
          allowRawMessage: true,
        ),
        '기본 문구',
      );
    });

    test('JSON 파싱 실패 문구는 내부 정보로 보고 fallback 을 쓴다', () {
      for (final raw in [
        'json parsing failed: unexpected token',
        'Failed to parse response body',
        'Unknown error: null',
        '<!DOCTYPE html><html>...',
        '{"error": "internal"}',
      ]) {
        expect(
          ErrorMessageMapper.sanitizeRawMessage(
            raw,
            fallback: '기본 문구',
            allowRawMessage: true,
          ),
          '기본 문구',
          reason: '"$raw" 는 내부 정보로 보고 걸러내야 한다',
        );
      }
    });
  });

  group('sanitizeRawMessage - 걸러내지 못하는 내부 정보 (발견된 필터링 공백)', () {
    // ErrorMessageMapper._looksLikeInternalRaw (lib/Util/ErrorMessageMapper.dart:159)
    // 는 'exception:', 'response:', 'uri=', 'json parsing failed',
    // 'failed to parse response', 'unknown error:', '{', '<!doctype html'
    // 만 검사한다. 그 외의 내부 정보 형태 - 순수 URL, SQL 조각, 스택 트레이스 라인,
    // 일반적인 영문 런타임 에러 문구 - 는 이 목록에 걸리지 않아서 allowRawMessage
    // 가 true 인 경로(ApiException/UnauthorizedException/ServerException/
    // BadRequestException)에서는 사용자에게 그대로 노출된다.
    //
    // 크래시는 아니라서 skip 하지 않고, 현재 동작을 그대로 문서화해 둔다.
    // 발견 내용은 최종 보고에도 남긴다.

    test('원본 URL(토큰 포함 가능)이 걸러지지 않고 그대로 노출된다', () {
      const raw = 'https://internal-api.ono.local/secret?token=abc123';

      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          raw,
          fallback: '기본 문구',
          allowRawMessage: true,
        ),
        raw,
      );
    });

    test('SQL 조각이 걸러지지 않고 그대로 노출된다', () {
      const raw = 'SELECT * FROM users WHERE id=1';

      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          raw,
          fallback: '기본 문구',
          allowRawMessage: true,
        ),
        raw,
      );
    });

    test('파일 경로가 담긴 스택 트레이스 한 줄이 걸러지지 않고 그대로 노출된다', () {
      const raw = '#0 Foo.bar (file:///Users/x/lib/foo.dart:12:3)';

      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          raw,
          fallback: '기본 문구',
          allowRawMessage: true,
        ),
        raw,
      );
    });

    test('클래스명 없이 순수 영문 런타임 에러 문구도 걸러지지 않는다', () {
      const raw = 'Null check operator used on a null value';

      expect(
        ErrorMessageMapper.sanitizeRawMessage(
          raw,
          fallback: '기본 문구',
          allowRawMessage: true,
        ),
        raw,
      );
    });
  });

  group('byErrorCodeOrNull - 전체 매핑', () {
    // ErrorMessageMapper.byErrorCodeOrNull 의 switch 문 전체를 잠가 둔다.
    // 리팩터링 중 case 를 실수로 지우거나 다른 상수를 잘못 연결하면 여기서 바로 드러난다.
    const expected = <int, String>{
      1001: ErrorMessages.invalidRefreshToken,
      1002: ErrorMessages.refreshTokenNotFound,
      1003: ErrorMessages.invalidAuthority,
      1004: ErrorMessages.refreshTokenNotEqual,
      1005: ErrorMessages.accessTokenExpired,
      1006: ErrorMessages.refreshTokenExpired,
      1007: ErrorMessages.authenticationFailed,
      1008: ErrorMessages.accessDenied,
      1009: ErrorMessages.invalidAccessToken,
      2001: ErrorMessages.fileUploadFailed,
      3001: ErrorMessages.userNotFound,
      4001: ErrorMessages.problemNotFound,
      4002: ErrorMessages.problemUserUnmatched,
      4003: ErrorMessages.problemSolveImageAlreadyRegistered,
      4004: ErrorMessages.problemAnalysisNotFound,
      4021: ErrorMessages.problemSolveNotFound,
      4022: ErrorMessages.problemSolveUserUnmatched,
      5001: ErrorMessages.folderNotFound,
      5002: ErrorMessages.folderUserUnmatched,
      5003: ErrorMessages.rootFolderNotExist,
      5004: ErrorMessages.rootFolderCannotRemove,
      5005: ErrorMessages.rootFolderCannotUpdate,
      6001: ErrorMessages.practiceNoteNotFound,
      7001: ErrorMessages.missionTypeNotFound,
      7002: ErrorMessages.missionUserNotFound,
      8001: ErrorMessages.fcmTokenNotFound,
      8002: ErrorMessages.fcmSendFailed,
      9001: ErrorMessages.tagNameEmpty,
      9002: ErrorMessages.tagNameTooLong,
      9003: ErrorMessages.tagNotFound,
      9004: ErrorMessages.tagUserUnmatched,
      9005: ErrorMessages.tagLimitExceeded,
      10001: ErrorMessages.studyRoomNotFound,
      10002: ErrorMessages.studyRoomForbidden,
      10003: ErrorMessages.studyRoomHostOnly,
      10004: ErrorMessages.studyRoomFull,
      10005: ErrorMessages.studyRoomLimitExceeded,
      10006: ErrorMessages.inviteCodeInvalid,
      10007: ErrorMessages.inviteCodeExpired,
      10008: ErrorMessages.alreadyStudyRoomMember,
      10009: ErrorMessages.challengeNotFound,
      10010: ErrorMessages.challengeLimitExceeded,
      10011: ErrorMessages.sessionAlreadyActive,
      10012: ErrorMessages.sessionNotFound,
      10013: ErrorMessages.sharedProblemNotFound,
      10014: ErrorMessages.weeklyReportNotFound,
      10015: ErrorMessages.invalidReactionEmoji,
      10016: ErrorMessages.invalidStudyRoomRequest,
    };

    test('정의된 errorCode 48개가 모두 기대한 메시지로 매핑된다', () {
      expect(expected.length, 48);
      expected.forEach((code, message) {
        expect(
          ErrorMessageMapper.byErrorCodeOrNull(code),
          message,
          reason: 'errorCode $code 매핑이 어긋난다',
        );
      });
    });

    test('정의되지 않은 errorCode 는 null 이다', () {
      for (final code in [0, -1, 1000, 4005, 9999, 20000]) {
        expect(
          ErrorMessageMapper.byErrorCodeOrNull(code),
          isNull,
          reason: 'errorCode $code 는 매핑되어 있으면 안 된다',
        );
      }
    });

    test('errorCode 가 null 이면 null 이다', () {
      expect(ErrorMessageMapper.byErrorCodeOrNull(null), isNull);
    });

    test('byErrorCode 는 매핑이 없을 때 fallback, 그다음 unknown 순으로 떨어진다', () {
      expect(
        ErrorMessageMapper.byErrorCode(errorCode: 5001),
        ErrorMessages.folderNotFound,
      );
      expect(
        ErrorMessageMapper.byErrorCode(errorCode: 9999, fallback: '기본 문구'),
        '기본 문구',
      );
      expect(
        ErrorMessageMapper.byErrorCode(errorCode: 9999),
        ErrorMessages.unknown,
      );
    });

    test('매핑된 48개 메시지 중 완전히 같은 문구가 중복되지 않는다', () {
      final seen = <String, int>{};
      final duplicates = <String>[];

      expected.forEach((code, message) {
        final firstCode = seen[message];
        if (firstCode != null) {
          duplicates.add('$firstCode 와 $code 가 "$message" 로 겹친다');
        } else {
          seen[message] = code;
        }
      });

      expect(duplicates, isEmpty, reason: duplicates.join(', '));
    });

    test('ErrorMessages 에 정의되어 있지만 errorCode 매핑에는 연결되지 않은 상수가 있다 (사용처 확인 필요)',
        () {
      // 아래 상수들은 lib/Constants/ErrorMessages.dart 에 정의되어 있지만
      // grep 기준으로 lib/ 어디에서도 참조되지 않는다(byErrorCodeOrNull 포함).
      // 리팩터링 중 남은 죽은 코드일 수도, 매핑을 빠뜨린 것일 수도 있어 사람이 확인해야 한다.
      // 이 상수 중 하나라도 나중에 실제로 연결되면 이 테스트가 깨지면서 알려준다.
      const unwiredSoFar = {
        ErrorMessages.requestInvalid,
        ErrorMessages.requiredFieldMissing,
        ErrorMessages.notFound,
        ErrorMessages.forbidden,
        ErrorMessages.sessionExpired,
      };

      for (final message in unwiredSoFar) {
        expect(
          expected.values.contains(message),
          isFalse,
          reason: '"$message" 가 매핑에 연결됐다면 이 목록에서 지워야 한다',
        );
      }
    });
  });
}
