import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Constants/ErrorMessages.dart';
import 'package:ono/Exception/ApiException.dart';
import 'package:ono/Util/ErrorMessageMapper.dart';

void main() {
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
}
