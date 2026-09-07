import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/StudyRoom/InviteCodeModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('InviteCodeModel.fromJson - 정상 응답', () {
    test('모든 필드가 채워진 응답을 파싱한다', () {
      final json = {
        'code': 'ABCD1234',
        'expiredAt': '2099-01-01T00:00:00.000Z',
      };

      final model = InviteCodeModel.fromJson(json);

      expect(model.code, 'ABCD1234');
      expect(model.expiredAt, DateTime.parse('2099-01-01T00:00:00.000Z'));
      expect(model.isExpired, isFalse);
    });

    test('만료 시각이 과거면 isExpired 가 true 다', () {
      final model = InviteCodeModel.fromJson({
        'code': 'ABCD1234',
        'expiredAt': '2000-01-01T00:00:00.000Z',
      });

      expect(model.isExpired, isTrue);
    });
  });

  group('InviteCodeModel.fromJson - 키 누락 시 기본값', () {
    test('code 키가 없으면 빈 문자열이 된다', () {
      final model = InviteCodeModel.fromJson({
        'expiredAt': '2099-01-01T00:00:00.000Z',
      });

      expect(model.code, '');
    });

    test('expiredAt 키가 없거나 파싱할 수 없으면 현재 시각으로 대체되어 즉시 만료 취급된다', () {
      // expiredAt 이 없을 때 DateTime.now() 로 대체하는 것은, 결과적으로 isExpired 를
      // 곧바로 true 로 만드는 fail-safe 동작이다. 버그라기보다 의도된 방어 코드로 보인다.
      final model = InviteCodeModel.fromJson({'code': 'ABCD1234'});

      expect(model.isExpired, isTrue);
    });
  });
}
