import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/StudyCalendar/StudyCalendarModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('StudyCalendarModel.fromJson - 정상 응답 (중첩 records 포함)', () {
    test('모든 필드와 일별 기록을 파싱한다', () {
      final json = {
        'year': 2026,
        'month': 1,
        'currentStreak': 5,
        'bestStreak': 10,
        'thisMonthStudyDays': 12,
        'records': [
          {
            'date': '2026-01-01',
            'hasStudied': true,
            'reviewCount': 3,
            'noteWriteCount': 2,
            'studyMinutes': 30,
            'reviewedItems': ['문제1', '문제2'],
            'moodEmojiKey': 'happy',
          },
          {
            'date': '2026-01-02',
            'hasStudied': false,
            'reviewCount': 0,
            'noteWriteCount': 0,
            'studyMinutes': 0,
            'reviewedItems': [],
          },
        ],
      };

      final model = StudyCalendarModel.fromJson(json);

      expect(model.year, 2026);
      expect(model.month, 1);
      expect(model.currentStreak, 5);
      expect(model.bestStreak, 10);
      expect(model.thisMonthStudyDays, 12);
      expect(model.records, hasLength(2));

      final firstRecord = model.records.first;
      expect(firstRecord.date, DateTime.parse('2026-01-01'));
      expect(firstRecord.hasStudied, isTrue);
      expect(firstRecord.reviewCount, 3);
      expect(firstRecord.noteWriteCount, 2);
      expect(firstRecord.studyMinutes, 30);
      expect(firstRecord.reviewedItems, ['문제1', '문제2']);
      expect(firstRecord.moodEmojiKey, 'happy');
      // total(5) >= 5 이므로 강도는 2 단계
      expect(firstRecord.intensityLevel, 2);
    });

    test('recordFor 는 연/월/일이 모두 일치하는 기록만 찾는다', () {
      final model = StudyCalendarModel.fromJson({
        'year': 2026,
        'month': 1,
        'currentStreak': 0,
        'bestStreak': 0,
        'thisMonthStudyDays': 0,
        'records': [
          {
            'date': '2026-01-05',
            'hasStudied': true,
            'reviewCount': 1,
            'noteWriteCount': 0,
            'studyMinutes': 5,
            'reviewedItems': [],
          },
        ],
      });

      expect(model.recordFor(5), isNotNull);
      expect(model.recordFor(6), isNull);
    });
  });

  group('StudyCalendarModel.fromJson - nullable / 키 누락', () {
    test('records 키가 없으면 빈 리스트가 된다', () {
      final model = StudyCalendarModel.fromJson({
        'year': 2026,
        'month': 1,
        'currentStreak': 0,
        'bestStreak': 0,
        'thisMonthStudyDays': 0,
      });

      expect(model.records, isEmpty);
    });

    test('숫자 필드가 double 로 와도 int 로 변환된다', () {
      final model = StudyCalendarModel.fromJson({
        'year': 2026.0,
        'month': 1.0,
        'currentStreak': 5.0,
        'bestStreak': 10.0,
        'thisMonthStudyDays': 12.0,
      });

      expect(model.year, 2026);
      expect(model.month, 1);
      expect(model.currentStreak, 5);
      expect(model.bestStreak, 10);
      expect(model.thisMonthStudyDays, 12);
    });
  });

  group('DailyStudyRecord.fromJson - nullable / 키 누락', () {
    test('moodEmojiKey 가 null 이거나 키가 없으면 null 로 파싱된다', () {
      final record = DailyStudyRecord.fromJson({
        'date': '2026-01-01',
        'hasStudied': false,
        'reviewCount': 0,
        'noteWriteCount': 0,
        'studyMinutes': 0,
        'reviewedItems': [],
      });

      expect(record.moodEmojiKey, isNull);
    });

    test('reviewedItems 키가 없으면 빈 리스트가 된다', () {
      final record = DailyStudyRecord.fromJson({
        'date': '2026-01-01',
        'hasStudied': false,
        'reviewCount': 0,
        'noteWriteCount': 0,
        'studyMinutes': 0,
      });

      expect(record.reviewedItems, isEmpty);
    });

    test('date 를 파싱할 수 없으면 DateTime(0) 으로 대체된다', () {
      final record = DailyStudyRecord.fromJson({
        'hasStudied': false,
        'reviewCount': 0,
        'noteWriteCount': 0,
        'studyMinutes': 0,
        'reviewedItems': [],
      });

      expect(record.date, DateTime(0));
    });
  });

  group('DailyStudyRecord.intensityLevel', () {
    test('공부하지 않은 날은 0 단계다', () {
      final record = DailyStudyRecord.fromJson({
        'date': '2026-01-01',
        'hasStudied': false,
        'reviewCount': 10,
        'noteWriteCount': 10,
        'studyMinutes': 0,
        'reviewedItems': [],
      });

      expect(record.intensityLevel, 0);
    });

    test('reviewCount + noteWriteCount 합이 10 이상이면 3 단계다', () {
      final record = DailyStudyRecord.fromJson({
        'date': '2026-01-01',
        'hasStudied': true,
        'reviewCount': 6,
        'noteWriteCount': 5,
        'studyMinutes': 0,
        'reviewedItems': [],
      });

      expect(record.intensityLevel, 3);
    });

    test('합이 5 미만이면 1 단계다', () {
      final record = DailyStudyRecord.fromJson({
        'date': '2026-01-01',
        'hasStudied': true,
        'reviewCount': 1,
        'noteWriteCount': 1,
        'studyMinutes': 0,
        'reviewedItems': [],
      });

      expect(record.intensityLevel, 1);
    });
  });
}
