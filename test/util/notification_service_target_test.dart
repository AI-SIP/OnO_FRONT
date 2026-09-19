// 알림 data 를 읽어 어느 화면으로 갈지 정하는 분기표 테스트 (#253).
//
// 서버가 실제로 보내는 종류는 일곱 가지인데 앱은 세 가지만 처리하고 있었다.
// 백엔드가 표기를 소문자 스네이크로 통일했지만(AI-SIP/OnO_BACKEND#312), 그 배포
// 전의 서버가 보내는 대문자 표기와 이미 예약되어 큐에 남은 알림이 당분간 같이
// 오기 때문에 두 표기가 같은 화면으로 가야 한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Util/NotificationService.dart';

import '../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('복습 요약 · 리인게이지먼트 (기존 동작)', () {
    test('review_due 는 복습 요약 화면으로 간다', () {
      final target = NotificationTarget.fromData(const {'type': 'review_due'});

      expect(target.destination, NotificationDestination.reviewDue);
    });

    test('REVIEW_DUE 처럼 대문자로 와도 같은 화면으로 간다', () {
      final target = NotificationTarget.fromData(const {'type': 'REVIEW_DUE'});

      expect(target.destination, NotificationDestination.reviewDue);
    });

    test('reengagement, reengagement_monthly 는 홈으로만 간다', () {
      expect(
        NotificationTarget.fromData(const {'type': 'reengagement'}).destination,
        NotificationDestination.home,
      );
      expect(
        NotificationTarget.fromData(const {'type': 'REENGAGEMENT_MONTHLY'})
            .destination,
        NotificationDestination.home,
      );
    });
  });

  group('복습 리마인더 (problem_review_reminder)', () {
    test('problemId 를 들고 문제 상세로 간다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'problem_review_reminder',
        'problemId': '42',
        'sequence': '2',
        'intervalDays': '7',
      });

      expect(target.destination, NotificationDestination.problemDetail);
      expect(target.problemId, 42);
    });

    test('PROBLEM_REVIEW_REMINDER 로 와도 같은 화면으로 간다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'PROBLEM_REVIEW_REMINDER',
        'problemId': '42',
      });

      expect(target.destination, NotificationDestination.problemDetail);
      expect(target.problemId, 42);
    });

    test('problemId 가 없으면 아무 데도 가지 않는다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'problem_review_reminder',
      });

      expect(target.destination, NotificationDestination.none);
    });
  });

  group('스터디룸 챌린지 (CHALLENGE_NOTIFICATION, CHALLENGE_COMPLETED)', () {
    test('roomId 를 들고 방 상세로 간다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'CHALLENGE_NOTIFICATION',
        'roomId': '7',
      });

      expect(target.destination, NotificationDestination.studyRoom);
      expect(target.roomId, 7);
    });

    test('소문자 표기도 같은 화면으로 간다', () {
      expect(
        NotificationTarget.fromData(const {
          'type': 'challenge_notification',
          'roomId': '7',
        }).destination,
        NotificationDestination.studyRoom,
      );
      expect(
        NotificationTarget.fromData(const {
          'type': 'challenge_completed',
          'roomId': '7',
        }).destination,
        NotificationDestination.studyRoom,
      );
      expect(
        NotificationTarget.fromData(const {
          'type': 'CHALLENGE_COMPLETED',
          'roomId': '7',
        }).destination,
        NotificationDestination.studyRoom,
      );
    });

    test('roomId 가 없으면 아무 데도 가지 않는다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'CHALLENGE_COMPLETED',
      });

      expect(target.destination, NotificationDestination.none);
    });
  });

  group('공유 문제 (SHARED_PROBLEM, 반응, 댓글)', () {
    test('세 종류 모두 roomId, sharedProblemId 를 들고 공유 문제 상세로 간다', () {
      for (final type in [
        'SHARED_PROBLEM',
        'SHARED_PROBLEM_REACTION',
        'SHARED_PROBLEM_COMMENT',
      ]) {
        final target = NotificationTarget.fromData({
          'type': type,
          'roomId': '7',
          'sharedProblemId': '15',
        });

        expect(
          target.destination,
          NotificationDestination.sharedProblem,
          reason: type,
        );
        expect(target.roomId, 7, reason: type);
        expect(target.sharedProblemId, 15, reason: type);
      }
    });

    test('소문자 표기도 같은 화면으로 간다', () {
      for (final type in [
        'shared_problem',
        'shared_problem_reaction',
        'shared_problem_comment',
      ]) {
        final target = NotificationTarget.fromData({
          'type': type,
          'roomId': '7',
          'sharedProblemId': '15',
        });

        expect(
          target.destination,
          NotificationDestination.sharedProblem,
          reason: type,
        );
      }
    });

    test('sharedProblemId 가 없으면 방 상세까지만 간다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'SHARED_PROBLEM_COMMENT',
        'roomId': '7',
      });

      expect(target.destination, NotificationDestination.studyRoom);
      expect(target.roomId, 7);
    });

    test('roomId 가 없으면 아무 데도 가지 않는다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'SHARED_PROBLEM',
        'sharedProblemId': '15',
      });

      expect(target.destination, NotificationDestination.none);
    });
  });

  group('복습 노트 (practice_note_reminder)', () {
    test('practiceId 를 들고 복습 노트 상세로 간다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'practice_note_reminder',
        'practiceId': '3',
      });

      expect(target.destination, NotificationDestination.practiceNote);
      expect(target.practiceId, 3);
    });

    test('PRACTICE_NOTE_REMINDER 로 와도 같은 화면으로 간다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'PRACTICE_NOTE_REMINDER',
        'practiceId': '3',
      });

      expect(target.destination, NotificationDestination.practiceNote);
      expect(target.practiceId, 3);
    });

    test('type 키가 없고 practiceId 만 와도 같은 화면으로 간다', () {
      // #312 이전에 예약되어 큐에 남은 알림은 type 없이 온다.
      final target = NotificationTarget.fromData(const {'practiceId': '3'});

      expect(target.destination, NotificationDestination.practiceNote);
      expect(target.practiceId, 3);
    });

    test('practiceId 가 없으면 아무 데도 가지 않는다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'practice_note_reminder',
      });

      expect(target.destination, NotificationDestination.none);
    });
  });

  group('알 수 없는 알림', () {
    test('모르는 type 이고 쓸 수 있는 id 도 없으면 아무 일도 일어나지 않는다', () {
      expect(
        NotificationTarget.fromData(const {'type': 'something_new'})
            .destination,
        NotificationDestination.none,
      );
      expect(
        NotificationTarget.fromData(const <String, dynamic>{}).destination,
        NotificationDestination.none,
      );
      expect(
        NotificationTarget.fromData(null).destination,
        NotificationDestination.none,
      );
    });

    test('type 이 문자열이 아니어도 크래시하지 않는다', () {
      expect(
        NotificationTarget.fromData(const {'type': 3}).destination,
        NotificationDestination.none,
      );
    });
  });

  group('id 읽기', () {
    test('숫자로 와도 읽는다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'shared_problem',
        'roomId': 7,
        'sharedProblemId': 15.0,
      });

      expect(target.roomId, 7);
      expect(target.sharedProblemId, 15);
    });

    test('숫자가 아닌 문자열이면 없는 것으로 본다', () {
      final target = NotificationTarget.fromData(const {
        'type': 'challenge_completed',
        'roomId': 'abc',
      });

      expect(target.destination, NotificationDestination.none);
    });

    test('type 과 id 앞뒤에 공백이 있어도 읽는다', () {
      final target = NotificationTarget.fromData(const {
        'type': ' Challenge_Notification ',
        'roomId': ' 7 ',
      });

      expect(target.destination, NotificationDestination.studyRoom);
      expect(target.roomId, 7);
    });
  });
}
