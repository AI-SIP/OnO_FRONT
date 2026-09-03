import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/User/UserRegisterModel.dart';

void main() {
  group('UserRegisterModel.toJson', () {
    test('모든 필드가 채워지면 서버가 받는 키 이름으로 직렬화된다', () {
      final model = UserRegisterModel(
        email: 'test@ono.local',
        name: '기승민',
        identifier: 'apple-uid-1',
        platform: 'apple',
        password: null,
        profileImageUrl: 'https://cdn.test/profile.png',
      );

      expect(model.toJson(), {
        'email': 'test@ono.local',
        'name': '기승민',
        'identifier': 'apple-uid-1',
        'platform': 'apple',
        'password': null,
        'profileImageUrl': 'https://cdn.test/profile.png',
      });
    });

    test('기본 생성자만 쓰면 빈 문자열들로 직렬화된다 (profileImageUrl 만 null)', () {
      final model = UserRegisterModel();

      expect(model.toJson(), {
        'email': '',
        'name': '',
        'identifier': '',
        'platform': '',
        'password': '',
        'profileImageUrl': null,
      });
    });
  });
}
