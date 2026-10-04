import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Util/ReviewScheduleText.dart';

void main() {
  final now = DateTime(2026, 10, 4, 21, 30);

  group('추천 카드 칩', () {
    test('복습일이 오늘이면 오늘, 지났으면 밀린 일수다', () {
      expect(ReviewScheduleText.dueChip(DateTime(2026, 10, 4), now: now), '오늘');
      expect(
          ReviewScheduleText.dueChip(DateTime(2026, 10, 1), now: now), '3일 밀림');
    });

    test('아직 오지 않았거나 날짜가 없으면 칩을 달지 않는다', () {
      expect(
          ReviewScheduleText.dueChip(DateTime(2026, 10, 5), now: now), isNull);
      expect(ReviewScheduleText.dueChip(null, now: now), isNull);
    });
  });

  group('저장 뒤 안내', () {
    test('다음 복습일이 있으면 날짜와 며칠 뒤인지 알려 준다', () {
      expect(
        ReviewScheduleText.afterSave(
          hasReviewSchedule: true,
          nextReviewAt: DateTime(2026, 10, 8),
          now: now,
        ),
        '복습을 기록했어요. 다음 복습은 10월 8일(4일 뒤)이에요',
      );
      expect(
        ReviewScheduleText.afterSave(
          hasReviewSchedule: true,
          nextReviewAt: DateTime(2026, 10, 5),
          now: now,
        ),
        '복습을 기록했어요. 다음 복습은 내일(10월 5일)이에요',
      );
    });

    test('추천에서 빠졌으면 그렇게 알린다', () {
      expect(
        ReviewScheduleText.afterSave(
          hasReviewSchedule: true,
          nextReviewAt: null,
          now: now,
        ),
        '복습을 기록했어요. 3번 맞혀서 추천 복습에서 빠졌어요',
      );
    });

    test('예전 서버라 다음 복습일을 모르면 예전 문구를 쓴다', () {
      expect(
        ReviewScheduleText.afterSave(
          hasReviewSchedule: false,
          nextReviewAt: null,
          now: now,
        ),
        '복습이 완료되었습니다!',
      );
    });
  });

  group('문제 응답의 다음 복습일', () {
    Map<String, dynamic> json([Map<String, dynamic> extra = const {}]) =>
        {'problemId': 1, 'folderId': 2, ...extra};

    test('있으면 읽고, 추천에서 빠져 null 이어도 서버가 준 것으로 본다', () {
      final scheduled =
          ProblemModel.fromJson(json({'nextReviewAt': '2026-10-08'}));
      expect(scheduled.nextReviewAt, DateTime(2026, 10, 8));
      expect(scheduled.hasReviewSchedule, isTrue);

      final mastered = ProblemModel.fromJson(json({'nextReviewAt': null}));
      expect(mastered.nextReviewAt, isNull);
      expect(mastered.hasReviewSchedule, isTrue);
    });

    test('예전 서버라 필드가 없으면 모르는 것으로 본다', () {
      expect(ProblemModel.fromJson(json()).hasReviewSchedule, isFalse);
    });
  });
}
