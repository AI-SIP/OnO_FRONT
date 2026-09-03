import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/StudyRoom/ActivityFeedModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('ActivityFeedModel.fromJson - 정상 응답 (중첩 reactions 포함)', () {
    test('모든 필드와 reactions 리스트를 파싱한다', () {
      final json = {
        'feedId': 1,
        'userId': 10,
        'userName': '기승민',
        'eventType': 'problem_registered',
        'metadata': {'count': 3},
        'createdAt': '2026-01-01T09:00:00.000Z',
        'reactions': [
          {'emoji': '👍', 'count': 2, 'reactedByMe': true},
        ],
      };

      final model = ActivityFeedModel.fromJson(json);

      expect(model.feedId, 1);
      expect(model.userId, 10);
      expect(model.userName, '기승민');
      expect(model.eventType, 'problem_registered');
      expect(model.metadata, {'count': 3});
      expect(model.createdAt, DateTime.parse('2026-01-01T09:00:00.000Z'));
      expect(model.reactions, hasLength(1));
      expect(model.reactions.first.emoji, '👍');
    });
  });

  group('ActivityFeedModel.fromJson - nullable / 키 누락', () {
    test('metadata 가 null 이거나 Map 이 아니면 null 로 파싱된다', () {
      final withNull = ActivityFeedModel.fromJson({
        'feedId': 1,
        'userId': 10,
        'userName': '기승민',
        'eventType': 'session_started',
        'metadata': null,
        'createdAt': '2026-01-01T09:00:00.000Z',
        'reactions': [],
      });
      final withWrongType = ActivityFeedModel.fromJson({
        'feedId': 1,
        'userId': 10,
        'userName': '기승민',
        'eventType': 'session_started',
        'metadata': 'not a map',
        'createdAt': '2026-01-01T09:00:00.000Z',
        'reactions': [],
      });

      expect(withNull.metadata, isNull);
      expect(withWrongType.metadata, isNull);
    });

    test('reactions 키가 없으면 빈 리스트가 된다', () {
      final model = ActivityFeedModel.fromJson({
        'feedId': 1,
        'userId': 10,
        'userName': '기승민',
        'eventType': 'session_started',
        'createdAt': '2026-01-01T09:00:00.000Z',
      });

      expect(model.reactions, isEmpty);
    });

    test('createdAt 이 파싱할 수 없는 값이면 현재 시각으로 대체된다', () {
      final model = ActivityFeedModel.fromJson({
        'feedId': 1,
        'userId': 10,
        'userName': '기승민',
        'eventType': 'session_started',
        'createdAt': 'not-a-date',
        'reactions': [],
      });

      expect(model.createdAt, isNotNull);
    });

    test('userName, eventType 키가 없으면 기본값으로 떨어진다', () {
      final model = ActivityFeedModel.fromJson({
        'feedId': 1,
        'userId': 10,
        'createdAt': '2026-01-01T09:00:00.000Z',
      });

      expect(model.userName, '알 수 없음');
      expect(model.eventType, '');
    });

    test('feedId, userId 가 double 로 와도 int 로 변환된다', () {
      final model = ActivityFeedModel.fromJson({
        'feedId': 1.0,
        'userId': 10.0,
        'userName': '기승민',
        'eventType': 'session_started',
        'createdAt': '2026-01-01T09:00:00.000Z',
      });

      expect(model.feedId, 1);
      expect(model.userId, 10);
    });
  });

  group('ActivityFeedModel.displayText', () {
    ActivityFeedModel build(String eventType,
        {Map<String, dynamic>? metadata}) {
      return ActivityFeedModel.fromJson({
        'feedId': 1,
        'userId': 10,
        'userName': '기승민',
        'eventType': eventType,
        'metadata': metadata,
        'createdAt': '2026-01-01T09:00:00.000Z',
        'reactions': [],
      });
    }

    test('problem_registered 는 등록한 문제 수를 표시한다', () {
      final model = build('problem_registered', metadata: {'count': 5});
      expect(model.displayText, '기승민 님이 오답노트 5문제를 등록했어요');
    });

    test('problem_registered 인데 count 가 없으면 1문제로 표시한다', () {
      final model = build('problem_registered');
      expect(model.displayText, '기승민 님이 오답노트 1문제를 등록했어요');
    });

    test('practice_completed 는 고정 문구를 표시한다', () {
      final model = build('practice_completed');
      expect(model.displayText, '기승민 님이 복습 세트를 완료했어요');
    });

    test('streak_milestone 은 연속 일수를 표시한다', () {
      final model = build('streak_milestone', metadata: {'days': 14});
      expect(model.displayText, '기승민 님이 14일 연속 공부 중이에요');
    });

    test('level_up 은 레벨을 표시한다', () {
      final model = build('level_up', metadata: {'level': 3});
      expect(model.displayText, '기승민 님이 레벨 3이 됐어요');
    });

    test('challenge_cleared, session_started, problem_shared 는 고정 문구를 표시한다',
        () {
      expect(build('challenge_cleared').displayText, '기승민 님이 이번 주 챌린지를 완료했어요');
      expect(build('session_started').displayText, '기승민 님이 공부 세션을 시작했어요');
      expect(build('problem_shared').displayText, '기승민 님이 문제를 공유했어요');
    });

    test('서버가 모르는 eventType 이 오면 기본 문구로 대체된다', () {
      final model = build('unknown_event');
      expect(model.displayText, '기승민 님의 활동');
    });
  });
}
