import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Common/LoginStatus.dart';

void main() {
  group('LoginStatus', () {
    // LoginStatus 는 fromJson/toJson 없이 앱 내부 상태로만 쓰인다.
    // 값 자체가 실수로 지워지거나 이름이 바뀌지 않는지만 확인한다.
    test('login, logout, waiting 세 값을 갖는다', () {
      expect(LoginStatus.values, [
        LoginStatus.login,
        LoginStatus.logout,
        LoginStatus.waiting,
      ]);
    });
  });
}
