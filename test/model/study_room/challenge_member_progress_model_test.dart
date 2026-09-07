import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/StudyRoom/ChallengeMemberProgressModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('ChallengeMemberProgressModel.fromJson - 정상 응답', () {
    test('모든 필드가 채워진 응답을 파싱한다', () {
      final json = {
        'userId': 1,
        'name': '기승민',
        'profileImageUrl': 'https://cdn.test/profile.png',
        'current': 5,
        'cleared': true,
      };

      final model = ChallengeMemberProgressModel.fromJson(json);

      expect(model.userId, 1);
      expect(model.name, '기승민');
      expect(model.profileImageUrl, 'https://cdn.test/profile.png');
      expect(model.current, 5);
      expect(model.cleared, isTrue);
    });

    test('current 가 double 로 와도 int 로 변환된다', () {
      final model = ChallengeMemberProgressModel.fromJson({
        'userId': 1,
        'name': '기승민',
        'current': 5.0,
        'cleared': false,
      });

      expect(model.current, 5);
    });
  });

  group('ChallengeMemberProgressModel.fromJson - nullable / 키 누락', () {
    test('profileImageUrl 이 null 이거나 키가 없으면 null 로 파싱된다', () {
      final model = ChallengeMemberProgressModel.fromJson({
        'userId': 1,
        'name': '기승민',
        'current': 0,
        'cleared': false,
      });

      expect(model.profileImageUrl, isNull);
    });

    test('userId, name, current, cleared 키가 모두 없으면 기본값으로 떨어진다', () {
      final model = ChallengeMemberProgressModel.fromJson({});

      expect(model.userId, 0);
      expect(model.name, '알 수 없음');
      expect(model.current, 0);
      expect(model.cleared, isFalse);
    });
  });
}
