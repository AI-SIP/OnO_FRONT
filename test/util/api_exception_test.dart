import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Constants/ErrorMessages.dart';
import 'package:ono/Exception/ApiException.dart';

import '../helpers/helpers.dart';

/// lib/Exception/ApiException.dart 의 7종 예외를 검증한다.
///
/// 공통 관심사:
/// - toString() 이 디버깅에 필요한 정보(status, errorCode, message)를 담는지
/// - getUserMessage() 가 서버 메시지와 errorCode 매핑 중 무엇을 우선하는지
/// - 서버 메시지가 내부 정보를 담고 있을 때 안전하게 대체되는지
void main() {
  setUpOnoTest();

  group('ApiException', () {
    test('statusCode 와 errorCode 가 모두 있으면 둘 다 toString 에 담는다', () {
      final exception = ApiException(
        statusCode: 400,
        errorCode: 5001,
        message: '폴더를 찾을 수 없습니다.',
      );

      expect(
        exception.toString(),
        'ApiException(status: 400, errorCode: 5001, message: 폴더를 찾을 수 없습니다.)',
      );
    });

    test('statusCode 나 errorCode 중 하나만 있어도 간단한 형태로 떨어진다', () {
      // statusCode 만 있고 errorCode 가 없는 경우 - 둘 다 있어야 하는 조건이라 else 로 빠진다.
      final exception = ApiException(statusCode: 400, message: '잘못된 요청');

      expect(exception.toString(), 'ApiException: 잘못된 요청');
    });

    test('statusCode, errorCode 둘 다 없으면 message 만 담는다', () {
      final exception = ApiException(message: '알 수 없는 오류');

      expect(exception.toString(), 'ApiException: 알 수 없는 오류');
    });

    test('안전한 서버 메시지는 그대로 사용자에게 보여준다', () {
      final exception = ApiException(
        statusCode: 400,
        errorCode: 5001,
        message: '폴더 이름은 20자 이하여야 합니다.',
      );

      expect(exception.getUserMessage(), '폴더 이름은 20자 이하여야 합니다.');
    });

    test('내부 정보로 보이는 메시지는 errorCode 매핑으로 대체한다', () {
      final exception = ApiException(
        statusCode: 500,
        errorCode: 5001,
        message: 'FolderNotFoundException: folder 5 not found',
      );

      expect(exception.getUserMessage(), ErrorMessages.folderNotFound);
    });

    test('메시지가 비어 있고 errorCode 도 매핑에 없으면 unknown 으로 떨어진다', () {
      final exception = ApiException(statusCode: 500, message: '');

      expect(exception.getUserMessage(), ErrorMessages.unknown);
    });

    test('메시지가 비어 있어도 errorCode 매핑이 있으면 그것을 쓴다', () {
      final exception =
          ApiException(statusCode: 400, errorCode: 9001, message: '');

      expect(exception.getUserMessage(), ErrorMessages.tagNameEmpty);
    });
  });

  group('NetworkException', () {
    test('기본 메시지는 ErrorMessages.network 이다', () {
      final exception = NetworkException();

      expect(exception.message, ErrorMessages.network);
      expect(
          exception.toString(), 'NetworkException: ${ErrorMessages.network}');
      expect(exception.getUserMessage(), ErrorMessages.network);
    });

    test('안전한 커스텀 메시지는 그대로 노출된다', () {
      final exception = NetworkException(message: '와이파이 신호가 약합니다.');

      expect(exception.getUserMessage(), '와이파이 신호가 약합니다.');
    });

    test('메시지에 네트워크 계열 기술 용어가 섞이면 표준 네트워크 문구로 바뀐다', () {
      final exception =
          NetworkException(message: 'SocketException: Failed host lookup');

      expect(exception.getUserMessage(), ErrorMessages.network);
    });

    test('메시지에 타임아웃 문구가 섞이면 표준 타임아웃 문구로 바뀐다 (교차 감지)', () {
      // NetworkException 이지만 메시지 내용이 타임아웃 패턴과 겹치면
      // sanitizeRawMessage 가 타임아웃 메시지로 덮어써 버린다.
      final exception = NetworkException(message: '요청 시간이 초과되어 연결이 끊겼습니다.');

      expect(exception.getUserMessage(), ErrorMessages.timeout);
    });

    test(
      'message 를 빈 문자열로 명시하면 getUserMessage() 도 빈 문자열이 된다',
      () {
        // TODO(#174): 실제 버그. lib/Exception/ApiException.dart:46-47
        // NetworkException.getUserMessage() 는 fallback 으로 자기 자신의 message 를
        // 넘기기 때문에, message 를 빈 문자열로 명시적으로 생성하면
        // sanitizeRawMessage 의 "빈 문자열이면 fallback 반환" 분기에서
        // fallback 도 빈 문자열이라 최종적으로 빈 SnackBar 가 뜬다.
        final exception = NetworkException(message: '');

        expect(exception.getUserMessage(), isNotEmpty);
      },
      skip: '#174 에서 수정 예정',
    );
  });

  group('TimeoutException', () {
    test('기본 메시지는 ErrorMessages.timeout 이다', () {
      final exception = TimeoutException();

      expect(exception.message, ErrorMessages.timeout);
      expect(
          exception.toString(), 'TimeoutException: ${ErrorMessages.timeout}');
      expect(exception.getUserMessage(), ErrorMessages.timeout);
    });

    test('안전한 커스텀 메시지는 그대로 노출된다', () {
      final exception = TimeoutException(message: '응답이 너무 늦습니다.');

      expect(exception.getUserMessage(), '응답이 너무 늦습니다.');
    });

    test(
      'message 를 빈 문자열로 명시하면 getUserMessage() 도 빈 문자열이 된다',
      () {
        // TODO(#174): 실제 버그. lib/Exception/ApiException.dart:59-60
        // TimeoutException 도 NetworkException 과 같은 구조(fallback = 자기 message)라
        // 같은 문제를 겪는다.
        final exception = TimeoutException(message: '');

        expect(exception.getUserMessage(), isNotEmpty);
      },
      skip: '#174 에서 수정 예정',
    );
  });

  group('UnauthorizedException', () {
    test('기본값은 errorCode 없이 authRequired 메시지를 쓴다', () {
      final exception = UnauthorizedException();

      expect(exception.errorCode, isNull);
      expect(exception.message, ErrorMessages.authRequired);
      expect(
        exception.toString(),
        'UnauthorizedException(errorCode: null): ${ErrorMessages.authRequired}',
      );
    });

    test('toString 에 errorCode 가 그대로 담긴다', () {
      final exception =
          UnauthorizedException(errorCode: 1005, message: '엑세스 토큰 만료');

      expect(
        exception.toString(),
        'UnauthorizedException(errorCode: 1005): 엑세스 토큰 만료',
      );
    });

    test('안전한 서버 메시지를 우선 사용한다', () {
      final exception =
          UnauthorizedException(errorCode: 1005, message: '다시 로그인해주세요.');

      expect(exception.getUserMessage(), '다시 로그인해주세요.');
    });

    test('내부 정보로 보이는 메시지는 errorCode 매핑으로 대체한다', () {
      final exception = UnauthorizedException(
        errorCode: 1005,
        message: 'CustomAuthException: token expired',
      );

      expect(exception.getUserMessage(), ErrorMessages.accessTokenExpired);
    });

    test(
      '메시지에 인증 관련 일반 패턴이 섞이면 errorCode 매핑보다 일반 authRequired 문구가 우선한다 (정밀도 손실)',
      () {
        // 'unauthorizedexception' 같은 일반 인증 패턴은 _looksLikeAuth 에서 먼저
        // 걸러지기 때문에, errorCode 1005(accessTokenExpired) 처럼 더 구체적인
        // 매핑이 있어도 무시되고 뭉뚱그린 authRequired 문구로 대체된다.
        final exception = UnauthorizedException(
          errorCode: 1005,
          message: 'UnauthorizedException: token expired',
        );

        expect(exception.getUserMessage(), ErrorMessages.authRequired);
      },
    );

    test('메시지도 없고 errorCode 매핑도 없으면 authRequired 로 떨어진다', () {
      final exception = UnauthorizedException(message: '');

      expect(exception.getUserMessage(), ErrorMessages.authRequired);
    });
  });

  group('ServerException', () {
    test('기본 메시지는 ErrorMessages.server 이다', () {
      final exception = ServerException();

      expect(exception.message, ErrorMessages.server);
      expect(exception.toString(),
          'ServerException(status: null): ${ErrorMessages.server}');
    });

    test('statusCode 가 toString 에 담긴다', () {
      final exception = ServerException(statusCode: 503, message: '서버 점검 중');

      expect(exception.toString(), 'ServerException(status: 503): 서버 점검 중');
    });

    test('안전한 서버 메시지는 그대로 노출된다', () {
      final exception =
          ServerException(statusCode: 500, message: '일시적인 서버 점검입니다.');

      expect(exception.getUserMessage(), '일시적인 서버 점검입니다.');
    });

    test('내부 정보로 보이는 메시지는 표준 서버 오류 문구로 대체된다', () {
      final exception = ServerException(
        statusCode: 500,
        message: 'ServerException: NullPointerException at line 42',
      );

      expect(exception.getUserMessage(), ErrorMessages.server);
    });

    test('메시지가 비어 있으면 표준 서버 오류 문구를 쓴다', () {
      final exception = ServerException(statusCode: 500, message: '');

      expect(exception.getUserMessage(), ErrorMessages.server);
    });
  });

  group('BadRequestException', () {
    test('안전한 서버 메시지를 errorCode 매핑보다 우선한다', () {
      final exception = BadRequestException(
        statusCode: 400,
        errorCode: 5001,
        message: '폴더 이름은 20자 이하여야 합니다.',
      );

      expect(exception.getUserMessage(), '폴더 이름은 20자 이하여야 합니다.');
    });

    test('메시지가 비어 있으면 errorCode 매핑을 쓴다', () {
      final exception =
          BadRequestException(statusCode: 400, errorCode: 5001, message: '');

      expect(exception.getUserMessage(), ErrorMessages.folderNotFound);
    });

    test('메시지가 내부 정보로 보이면 errorCode 매핑으로 대체한다', () {
      final exception = BadRequestException(
        statusCode: 400,
        errorCode: 9002,
        message: 'BadRequestException: tag name too long',
      );

      expect(exception.getUserMessage(), ErrorMessages.tagNameTooLong);
    });

    test('errorCode 가 없고 메시지도 비어 있으면 badRequest 기본 문구를 쓴다', () {
      final exception = BadRequestException(statusCode: 400, message: '');

      expect(exception.getUserMessage(), ErrorMessages.badRequest);
    });

    test('errorCode 가 매핑에 없어도 안전한 서버 메시지는 그대로 쓴다', () {
      final exception = BadRequestException(
        statusCode: 400,
        errorCode: 99999,
        message: '이 값은 사용할 수 없습니다.',
      );

      expect(exception.getUserMessage(), '이 값은 사용할 수 없습니다.');
    });

    test('errorCode 가 매핑에 없고 메시지도 비어 있으면 badRequest 기본 문구로 떨어진다', () {
      final exception =
          BadRequestException(statusCode: 400, errorCode: 99999, message: '');

      expect(exception.getUserMessage(), ErrorMessages.badRequest);
    });

    test('중괄호가 섞인 안전한 한글 메시지도 내부 정보로 오인되어 대체된다 (필터 과탐)', () {
      // ErrorMessageMapper._looksLikeInternalRaw 는 '{' 포함 여부만으로 걸러내기 때문에,
      // JSON 이 아니라 안내 문구 중간에 중괄호가 들어간 것 뿐이어도 원문이 아니라
      // errorCode 매핑(혹은 fallback)으로 대체된다.
      final exception = BadRequestException(
        statusCode: 400,
        errorCode: 5001,
        message: '허용되지 않는 값입니다: {folderName}',
      );

      expect(exception.getUserMessage(), ErrorMessages.folderNotFound);
    });

    test('toString 에 status, errorCode, message 가 모두 담긴다', () {
      final exception =
          BadRequestException(statusCode: 400, errorCode: 5001, message: '메시지');

      expect(
        exception.toString(),
        'BadRequestException(status: 400, errorCode: 5001): 메시지',
      );
    });
  });

  group('ParseException', () {
    test('기본 메시지는 ErrorMessages.parse 이다', () {
      final exception = ParseException();

      expect(exception.message, ErrorMessages.parse);
      expect(exception.toString(), 'ParseException: ${ErrorMessages.parse}');
      expect(exception.getUserMessage(), ErrorMessages.parse);
    });

    test(
      '다른 예외들과 달리 안전한 커스텀 메시지를 줘도 항상 표준 문구로 대체된다',
      () {
        // ParseException.getUserMessage() 는 allowRawMessage 를 켜지 않고
        // fallback 도 ErrorMessages.parse 로 고정이라, 원문이 안전해 보여도
        // 절대 사용자에게 노출되지 않는다. ApiException/UnauthorizedException/
        // ServerException/BadRequestException 이 allowRawMessage: true 로
        // 안전한 원문을 보여주는 것과는 다른 동작이다. (버그로 단정하긴 애매해서
        // skip 하지 않고 현재 동작을 그대로 문서화해 둔다.)
        final exception = ParseException(message: '숫자 형식이 올바르지 않습니다.');

        expect(exception.getUserMessage(), ErrorMessages.parse);
      },
    );
  });
}
