// ScreenIndexProvider 상태 전이 테스트.
//
// 의존성이 없는 가장 단순한 Provider 다. setSelectedIndex 가 매번
// FirebaseAnalytics 를 fire-and-forget 으로 부르므로, 이 스텁이 없으면
// 인덱스 변경 자체는 성공해도 테스트 프로세스가 처리되지 않은 예외로 실패한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Provider/ScreenIndexProvider.dart';

import '../helpers/helpers.dart';
import 'support/provider_test_env.dart';

void main() {
  setUpOnoTest();

  setUpAll(setUpProviderTestEnv);

  late ScreenIndexProvider provider;
  late NotifyRecorder notified;

  setUp(() {
    provider = ScreenIndexProvider();
    notified = NotifyRecorder();
    provider.addListener(notified.call);
  });

  test('초기 상태는 0번 탭이다', () {
    expect(provider.screenIndex, 0);
  });

  test('setSelectedIndex 는 인덱스를 바꾸고 notifyListeners 를 부른다', () {
    provider.setSelectedIndex(2);

    expect(provider.screenIndex, 2);
    expect(notified.count, greaterThan(0));
  });

  test('같은 인덱스를 다시 넣어도 notifyListeners 는 그대로 불린다 (조건 없는 무조건 알림)', () {
    provider.setSelectedIndex(1);
    notified.reset();

    provider.setSelectedIndex(1);

    expect(provider.screenIndex, 1);
    expect(notified.count, greaterThan(0));
  });

  test('정의되지 않은 인덱스(예: 99)도 그대로 저장된다 (범위 검증이 없다)', () {
    provider.setSelectedIndex(99);

    expect(provider.screenIndex, 99);
  });
}
