import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/PracticeNote/RepeatType.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('PracticeNoteDetailModel.fromJson - 정상 응답', () {
    test('모든 필드가 채워진 응답을 파싱한다', () {
      final json = {
        'practiceNoteId': 1,
        'practiceTitle': '오답노트 복습',
        'practiceCount': 3,
        'createdAt': '2026-01-01T09:00:00.000Z',
        'lastSolvedAt': '2026-01-05T09:00:00.000Z',
        'lastSessionMoodEmojiKey': 'happy',
        'practiceNotification': {
          'intervalDays': 3,
          'hour': 20,
          'minute': 30,
          'repeatType': 'weekly',
          'weekDays': [1, 3, 5],
        },
        'problemIdList': [10, 11, 12],
      };

      final model = PracticeNoteDetailModel.fromJson(json);

      expect(model.practiceId, 1);
      expect(model.practiceTitle, '오답노트 복습');
      expect(model.practiceCount, 3);
      expect(model.createdAt, DateTime.parse('2026-01-01T09:00:00.000Z'));
      expect(model.lastSolvedAt, DateTime.parse('2026-01-05T09:00:00.000Z'));
      expect(model.lastSessionMoodEmojiKey, 'happy');
      expect(model.practiceNotificationModel?.repeatType, RepeatType.weekly);
      expect(model.problemIdList, [10, 11, 12]);
      // practiceSize 는 problemIdList 의 길이로 계산된다
      expect(model.practiceSize, 3);
    });
  });

  group('PracticeNoteDetailModel.fromJson - nullable 필드', () {
    test(
        'lastSolvedAt, lastSessionMoodEmojiKey, practiceNotification 이 null 이면 null 로 파싱된다',
        () {
      final json = {
        'practiceNoteId': 1,
        'practiceTitle': '오답노트 복습',
        'practiceCount': 0,
        'createdAt': '2026-01-01T09:00:00.000Z',
        'lastSolvedAt': null,
        'lastSessionMoodEmojiKey': null,
        'practiceNotification': null,
        'problemIdList': [],
      };

      final model = PracticeNoteDetailModel.fromJson(json);

      expect(model.lastSolvedAt, isNull);
      expect(model.lastSessionMoodEmojiKey, isNull);
      expect(model.practiceNotificationModel, isNull);
    });
  });

  group('PracticeNoteDetailModel.fromJson - 키 누락 시 기본값', () {
    test('practiceTitle 키가 없으면 "제목 없음" 으로 떨어진다', () {
      final json = {
        'practiceNoteId': 1,
        'practiceCount': 0,
        'createdAt': '2026-01-01T09:00:00.000Z',
        'lastSolvedAt': null,
        'problemIdList': [],
      };

      final model = PracticeNoteDetailModel.fromJson(json);

      expect(model.practiceTitle, '제목 없음');
    });

    test('practiceCount 키가 없으면 0 으로 떨어진다', () {
      final json = {
        'practiceNoteId': 1,
        'practiceTitle': '오답노트 복습',
        'createdAt': '2026-01-01T09:00:00.000Z',
        'lastSolvedAt': null,
        'problemIdList': [],
      };

      final model = PracticeNoteDetailModel.fromJson(json);

      expect(model.practiceCount, 0);
    });

    test('problemIdList 키가 없으면 빈 리스트가 된다', () {
      final json = {
        'practiceNoteId': 1,
        'practiceTitle': '오답노트 복습',
        'practiceCount': 0,
        'createdAt': '2026-01-01T09:00:00.000Z',
        'lastSolvedAt': null,
      };

      final model = PracticeNoteDetailModel.fromJson(json);

      expect(model.problemIdList, isEmpty);
      expect(model.practiceSize, 0);
    });
  });

  group('PracticeNoteDetailModel.fromJson - 알려진 버그', () {
    test('practiceNoteId 키가 없어도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/PracticeNote/PracticeNoteDetailModel.dart:36
      // `practiceId: json['practiceNoteId']` 는 캐스팅이나 기본값 처리가 없어서,
      // 키가 없거나 값이 null 이면 non-nullable int 필드에 null 이 대입되어
      // "type 'Null' is not a subtype of type 'int'" TypeError 로 크래시한다.
      final json = {
        'practiceTitle': '오답노트 복습',
        'practiceCount': 0,
        'createdAt': '2026-01-01T09:00:00.000Z',
        'lastSolvedAt': null,
        'problemIdList': [],
      };

      expect(() => PracticeNoteDetailModel.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');

    test('practiceCount 가 double 로 와도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/PracticeNote/PracticeNoteDetailModel.dart:38
      // `practiceCount: json['practiceCount'] ?? 0` 은 타입 변환이 없어서,
      // 서버가 3.0 처럼 double 을 내려주면 non-nullable int 필드에 double 이 대입되어
      // TypeError 로 크래시한다.
      final json = {
        'practiceNoteId': 1,
        'practiceTitle': '오답노트 복습',
        'practiceCount': 3.0,
        'createdAt': '2026-01-01T09:00:00.000Z',
        'lastSolvedAt': null,
        'problemIdList': [],
      };

      expect(() => PracticeNoteDetailModel.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');

    test('createdAt 키가 없어도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/PracticeNote/PracticeNoteDetailModel.dart:39
      // `createdAt: DateTime.parse(json['createdAt'])` 은 null 검사가 없어서,
      // createdAt 키가 없으면 DateTime.parse(null) 호출로 TypeError 가 난다.
      // lastSolvedAt 처럼 null 체크와 tryParse 를 쓰지 않는다.
      final json = {
        'practiceNoteId': 1,
        'practiceTitle': '오답노트 복습',
        'practiceCount': 0,
        'lastSolvedAt': null,
        'problemIdList': [],
      };

      expect(() => PracticeNoteDetailModel.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');
  });

  group('PracticeNoteDetailModel.addPracticeCount', () {
    test('호출할 때마다 practiceCount 가 1씩 증가한다', () {
      final model = PracticeNoteDetailModel.fromJson({
        'practiceNoteId': 1,
        'practiceTitle': '오답노트 복습',
        'practiceCount': 0,
        'createdAt': '2026-01-01T09:00:00.000Z',
        'lastSolvedAt': null,
        'problemIdList': [],
      });

      model.addPracticeCount();
      model.addPracticeCount();

      expect(model.practiceCount, 2);
    });
  });
}
