import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteThumbnailModel.dart';

import '../../helpers/helpers.dart';

// 파일명은 PracticeNoteThumbnailModel.dart 지만 실제 클래스 이름은
// PracticeNoteThumbnails 다. PracticeNoteService, PaginatedResponse 등
// lib/ 전체가 이 이름을 그대로 쓰고 있어 테스트도 실제 클래스 이름을 따른다.
void main() {
  setUpOnoTest();

  group('PracticeNoteThumbnails.fromJson - 정상 응답', () {
    test('모든 필드가 채워진 응답을 파싱한다', () {
      final json = {
        'practiceNoteId': 5,
        'practiceTitle': '단원별 복습',
        'practiceCount': 2,
        'lastSolvedAt': '2026-02-10T09:00:00.000Z',
        'lastSessionMoodEmojiKey': 'soso',
      };

      final model = PracticeNoteThumbnails.fromJson(json);

      expect(model.practiceId, 5);
      expect(model.practiceTitle, '단원별 복습');
      expect(model.practiceCount, 2);
      expect(model.lastSolvedAt, DateTime.parse('2026-02-10T09:00:00.000Z'));
      expect(model.lastSessionMoodEmojiKey, 'soso');
    });
  });

  group('PracticeNoteThumbnails.fromJson - nullable 필드', () {
    test('lastSolvedAt, lastSessionMoodEmojiKey 가 null 이면 null 로 파싱된다', () {
      final json = {
        'practiceNoteId': 5,
        'practiceTitle': '단원별 복습',
        'practiceCount': 0,
        'lastSolvedAt': null,
        'lastSessionMoodEmojiKey': null,
      };

      final model = PracticeNoteThumbnails.fromJson(json);

      expect(model.lastSolvedAt, isNull);
      expect(model.lastSessionMoodEmojiKey, isNull);
    });
  });

  group('PracticeNoteThumbnails.fromJson - 키 누락 시 기본값', () {
    test('practiceTitle 키가 없으면 "제목 없음" 으로 떨어진다', () {
      final json = {
        'practiceNoteId': 5,
        'practiceCount': 0,
        'lastSolvedAt': null,
      };

      final model = PracticeNoteThumbnails.fromJson(json);

      expect(model.practiceTitle, '제목 없음');
    });

    test('practiceCount 키가 없으면 0 으로 떨어진다', () {
      final json = {
        'practiceNoteId': 5,
        'practiceTitle': '단원별 복습',
        'lastSolvedAt': null,
      };

      final model = PracticeNoteThumbnails.fromJson(json);

      expect(model.practiceCount, 0);
    });

    test('lastSolvedAt, lastSessionMoodEmojiKey 키가 없으면 null 로 파싱된다', () {
      final json = {
        'practiceNoteId': 5,
        'practiceTitle': '단원별 복습',
        'practiceCount': 0,
      };

      final model = PracticeNoteThumbnails.fromJson(json);

      expect(model.lastSolvedAt, isNull);
      expect(model.lastSessionMoodEmojiKey, isNull);
    });
  });

  group('PracticeNoteThumbnails.fromJson - 알려진 버그', () {
    test('practiceNoteId 키가 없어도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/PracticeNote/PracticeNoteThumbnailModel.dart:20
      // `practiceId: json['practiceNoteId']` 는 캐스팅/기본값 처리가 없어서
      // 키가 없거나 null 이면 non-nullable int 필드에 null 이 대입되어 TypeError 로 크래시한다.
      // PracticeNoteDetailModel 과 완전히 같은 버그가 복붙되어 있다.
      final json = {
        'practiceTitle': '단원별 복습',
        'practiceCount': 0,
        'lastSolvedAt': null,
      };

      expect(() => PracticeNoteThumbnails.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');

    test('practiceCount 가 double 로 와도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/PracticeNote/PracticeNoteThumbnailModel.dart:22
      // `practiceCount: json['practiceCount'] ?? 0` 은 타입 변환이 없어서
      // double 값이 오면 non-nullable int 필드에 대입되다 TypeError 로 크래시한다.
      final json = {
        'practiceNoteId': 5,
        'practiceTitle': '단원별 복습',
        'practiceCount': 2.0,
        'lastSolvedAt': null,
      };

      expect(() => PracticeNoteThumbnails.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');
  });

  group('PracticeNoteThumbnails.addPracticeCount', () {
    test('호출할 때마다 practiceCount 가 1씩 증가한다', () {
      final model = PracticeNoteThumbnails.fromJson({
        'practiceNoteId': 5,
        'practiceTitle': '단원별 복습',
        'practiceCount': 0,
        'lastSolvedAt': null,
      });

      model.addPracticeCount();

      expect(model.practiceCount, 1);
    });
  });
}
