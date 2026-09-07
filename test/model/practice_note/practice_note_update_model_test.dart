import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNotificationModel.dart';
import 'package:ono/Model/PracticeNote/RepeatType.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('PracticeNoteUpdateModel.toJson', () {
    test('practiceNotification 이 있으면 중첩된 형태로 직렬화된다', () {
      final model = PracticeNoteUpdateModel(
        practiceNoteId: 1,
        practiceTitle: '수정된 제목',
        addProblemIdList: const [4, 5],
        removeProblemIdList: const [1],
        practiceNotificationModel: PracticeNotificationModel(
          repeatType: RepeatType.weekly,
          weekDays: const [2, 4],
        ),
      );

      final json = model.toJson();

      expect(json['practiceNoteId'], 1);
      expect(json['practiceTitle'], '수정된 제목');
      expect(json['addProblemIdList'], [4, 5]);
      expect(json['removeProblemIdList'], [1]);
      expect(json['practiceNotification'], isNotNull);
      expect(json['practiceNotification']['repeatType'], 'weekly');
    });

    test('practiceNotification 이 없으면 practiceNotification 키 자체가 빠진다', () {
      final model = PracticeNoteUpdateModel(
        practiceNoteId: 1,
        addProblemIdList: const [],
        removeProblemIdList: const [],
      );

      final json = model.toJson();

      expect(json.containsKey('practiceNotification'), isFalse);
      expect(json['practiceTitle'], isNull);
    });

    test('addProblemIdList, removeProblemIdList 가 빈 배열이어도 키는 유지된다', () {
      final model = PracticeNoteUpdateModel(
        practiceNoteId: 1,
        addProblemIdList: const [],
        removeProblemIdList: const [],
      );

      final json = model.toJson();

      expect(json['addProblemIdList'], isEmpty);
      expect(json['removeProblemIdList'], isEmpty);
    });

    test('setPracticeTitle 로 제목을 바꾸면 toJson 에도 반영된다', () {
      final model = PracticeNoteUpdateModel(
        practiceNoteId: 1,
        addProblemIdList: const [],
        removeProblemIdList: const [],
      );

      model.setPracticeTitle('새 제목');

      expect(model.toJson()['practiceTitle'], '새 제목');
    });
  });
}
