import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/StudyRoom/StudyRoomModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('StudyRoomModel.fromJson - 정상 응답 (스터디룸 → 멤버 중첩)', () {
    test('픽스처로 받은 방 상세 응답을 멤버까지 전부 파싱한다', () {
      final json = loadJsonFixture('study_room/study_room_detail_full.json');

      final model = StudyRoomModel.fromJson(json);

      expect(model.roomId, 100);
      expect(model.name, '수학 스터디룸');
      expect(model.hostUserId, 1);
      expect(model.thumbnailImagePath, 'https://cdn.test/room-thumb.png');
      expect(model.hasUnreadReport, isTrue);
      expect(model.members, hasLength(2));
      expect(model.members[0].name, '기승민');
      expect(model.members[1].profileImageUrl, isNull);
      expect(model.memberCount, 2);
      expect(model.displayTodayPracticeMemberCount, 1);
      expect(model.displayTodayPracticeCount, 3);
    });
  });

  group('StudyRoomModel.fromJson - nullable / 키 누락', () {
    test('members 키가 없으면 빈 리스트가 된다', () {
      final model = StudyRoomModel.fromJson({
        'roomId': 1,
        'name': '빈 스터디룸',
        'hostUserId': 1,
      });

      expect(model.members, isEmpty);
    });

    test(
        'serverMemberCount, todayPracticeMemberCount, todayPracticeCount 가 없으면 멤버 리스트로 계산한다',
        () {
      final model = StudyRoomModel.fromJson({
        'roomId': 1,
        'name': '스터디룸',
        'hostUserId': 1,
        'members': [
          {
            'userId': 1,
            'name': '기승민',
            'totalStudyLevel': 1,
            'currentStreak': 0,
            'weeklyProblemCount': 0,
            'weeklyPracticeCount': 0,
            'todayPracticeCount': 2,
            'practicedToday': true,
          },
          {
            'userId': 2,
            'name': '홍길동',
            'totalStudyLevel': 1,
            'currentStreak': 0,
            'weeklyProblemCount': 0,
            'weeklyPracticeCount': 0,
            'practicedToday': false,
          },
        ],
      });

      // memberCount 는 서버 값이 없으면 members.length 로 대체
      expect(model.memberCount, 2);
      // todayPracticeMemberCount 는 서버 값이 없으면 오늘 복습한 멤버 수로 계산
      expect(model.displayTodayPracticeMemberCount, 1);
      // todayPracticeCount 는 서버 값이 없으면 멤버별 표시 카운트의 합으로 계산
      expect(model.displayTodayPracticeCount, 2);
    });

    test('hasUnreadReport 키가 없으면 false 로 떨어진다', () {
      final model = StudyRoomModel.fromJson({
        'roomId': 1,
        'name': '스터디룸',
        'hostUserId': 1,
      });

      expect(model.hasUnreadReport, isFalse);
    });

    test('roomId, hostUserId 가 double 로 와도 int 로 변환된다', () {
      final model = StudyRoomModel.fromJson({
        'roomId': 1.0,
        'name': '스터디룸',
        'hostUserId': 1.0,
      });

      expect(model.roomId, 1);
      expect(model.hostUserId, 1);
    });
  });

  group('StudyRoomModel.copyWith', () {
    test('일부 필드만 바꾸고 나머지는 유지한다', () {
      final original = StudyRoomModel.fromJson({
        'roomId': 1,
        'name': '스터디룸',
        'hostUserId': 1,
        'members': [],
      });

      final updated = original.copyWith(name: '새 이름', hasUnreadReport: true);

      expect(updated.roomId, original.roomId);
      expect(updated.name, '새 이름');
      expect(updated.hasUnreadReport, isTrue);
    });
  });
}
