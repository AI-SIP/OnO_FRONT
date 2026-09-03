import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteRegisterModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNotificationModel.dart';
import 'package:ono/Model/PracticeNote/RepeatType.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('PracticeNoteRegisterModel.toJson', () {
    test('practiceNotification 이 있으면 중첩된 형태로 직렬화된다', () {
      final model = PracticeNoteRegisterModel(
        practiceId: 1,
        practiceTitle: '새 복습 세트',
        registerProblemIdList: const [1, 2, 3],
        practiceNotificationModel: PracticeNotificationModel(
          intervalDays: 7,
          hour: 20,
          minute: 0,
          repeatType: RepeatType.daily,
        ),
      );

      final json = model.toJson();

      expect(json['practiceId'], 1);
      expect(json['practiceTitle'], '새 복습 세트');
      expect(json['problemIdList'], [1, 2, 3]);
      expect(json['practiceNotification'], {
        'intervalDays': 7,
        'hour': 20,
        'minute': 0,
        'repeatType': 'daily',
        'weekDays': null,
      });
    });

    test('practiceNotification 이 없으면 practiceNotification 키 자체가 빠진다', () {
      final model = PracticeNoteRegisterModel(
        practiceTitle: '새 복습 세트',
        registerProblemIdList: const [],
      );

      final json = model.toJson();

      expect(json.containsKey('practiceNotification'), isFalse);
      expect(json['practiceId'], isNull);
    });

    test('setPracticeTitle 로 제목을 바꾸면 toJson 에도 반영된다', () {
      final model = PracticeNoteRegisterModel(
        practiceTitle: '원래 제목',
        registerProblemIdList: const [],
      );

      model.setPracticeTitle('바뀐 제목');

      expect(model.toJson()['practiceTitle'], '바뀐 제목');
    });
  });
}
