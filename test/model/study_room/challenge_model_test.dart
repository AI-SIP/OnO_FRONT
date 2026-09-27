import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/StudyRoom/ChallengeModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('ChallengeModel.fromJson - 정상 응답 (중첩 memberProgress 포함)', () {
    test('모든 필드와 memberProgress 리스트를 파싱한다', () {
      final json = {
        'challengeId': 1,
        'title': '이번 주 10문제 풀기',
        'type': 'group',
        'metric': 'problem_count',
        'period': 'weekly',
        'periodDays': 7,
        'targetValue': 10,
        'startAt': '2026-01-01T00:00:00.000Z',
        'endAt': '2026-01-08T00:00:00.000Z',
        'status': 'in_progress',
        'groupCurrent': 4,
        'memberProgress': [
          {
            'userId': 1,
            'name': '기승민',
            'current': 4,
            'cleared': false,
          },
          {
            'userId': 2,
            'name': '홍길동',
            'current': 10,
            'cleared': true,
          },
        ],
      };

      final model = ChallengeModel.fromJson(json);

      expect(model.challengeId, 1);
      expect(model.title, '이번 주 10문제 풀기');
      expect(model.type, 'group');
      expect(model.metric, 'problem_count');
      expect(model.period, 'weekly');
      expect(model.periodDays, 7);
      expect(model.targetValue, 10);
      expect(model.startAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(model.endAt, DateTime.parse('2026-01-08T00:00:00.000Z'));
      expect(model.status, 'in_progress');
      expect(model.groupCurrent, 4);
      expect(model.memberProgress, hasLength(2));
      expect(model.memberProgress[1].cleared, isTrue);
      expect(model.isInProgress, isTrue);
      expect(model.isCompleted, isFalse);
      expect(model.clearedCount, 1);
    });
  });

  group('ChallengeModel.fromJson - nullable 필드', () {
    test('period, periodDays, startAt, groupCurrent 가 null 이면 null 로 파싱된다', () {
      final json = {
        'challengeId': 1,
        'title': '개인 챌린지',
        'type': 'individual',
        'metric': 'practice_count',
        'period': null,
        'periodDays': null,
        'targetValue': 5,
        'startAt': null,
        'endAt': '2026-01-08T00:00:00.000Z',
        'status': 'in_progress',
        'groupCurrent': null,
        'memberProgress': [],
      };

      final model = ChallengeModel.fromJson(json);

      expect(model.period, isNull);
      expect(model.periodDays, isNull);
      expect(model.startAt, isNull);
      expect(model.groupCurrent, isNull);
    });
  });

  group('ChallengeModel.fromJson - 키 누락 시 기본값', () {
    test('memberProgress 키가 없으면 빈 리스트가 된다', () {
      final json = {
        'challengeId': 1,
        'title': '개인 챌린지',
        'targetValue': 5,
        'endAt': '2026-01-08T00:00:00.000Z',
      };

      final model = ChallengeModel.fromJson(json);

      expect(model.memberProgress, isEmpty);
      expect(model.clearedCount, 0);
    });

    test('endAt 키가 없으면 현재 시각으로 대체된다', () {
      final model = ChallengeModel.fromJson({
        'challengeId': 1,
        'title': '개인 챌린지',
        'targetValue': 5,
      });

      expect(model.endAt, isNotNull);
    });

    test('type, metric, status 키가 없으면 각각 기본값으로 떨어진다', () {
      final model = ChallengeModel.fromJson({
        'challengeId': 1,
        'title': '개인 챌린지',
        'targetValue': 5,
        'endAt': '2026-01-08T00:00:00.000Z',
      });

      expect(model.type, 'individual');
      expect(model.metric, 'problem_count');
      expect(model.status, 'in_progress');
    });
  });

  group('ChallengeModel - status getter', () {
    test('status 가 completed 면 isCompleted 가 true 다', () {
      final model = ChallengeModel.fromJson({
        'challengeId': 1,
        'title': '완료된 챌린지',
        'targetValue': 5,
        'endAt': '2026-01-08T00:00:00.000Z',
        'status': 'completed',
      });

      expect(model.isCompleted, isTrue);
      expect(model.isInProgress, isFalse);
    });
  });
}
