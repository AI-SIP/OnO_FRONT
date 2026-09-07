import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/PracticeNote/RepeatType.dart';

import '../../helpers/helpers.dart';

// RepeatType 자체는 fromJson/toJson 이 없는 단순 enum 이라, 서버와 주고받는 값은
// PracticeNotificationModel 이 RepeatType.name / firstWhere 로 직접 다룬다.
// 여기서는 서버가 기대하는 문자열과 enum 이름이 어긋나지 않는지만 확인한다.
void main() {
  setUpOnoTest();

  group('RepeatType', () {
    test('daily, weekly 두 값만 존재한다', () {
      expect(RepeatType.values, [RepeatType.daily, RepeatType.weekly]);
    });

    test('name 이 서버와 주고받는 문자열과 일치한다', () {
      expect(RepeatType.daily.name, 'daily');
      expect(RepeatType.weekly.name, 'weekly');
    });
  });
}
