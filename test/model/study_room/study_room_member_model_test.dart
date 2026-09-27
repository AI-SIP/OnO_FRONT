import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/StudyRoom/StudyRoomMemberModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('StudyRoomMemberModel.fromJson - 정상 응답', () {
    test('모든 필드가 채워진 응답을 파싱한다', () {
      final json = {
        'userId': 1,
        'name': '기승민',
        'profileImageUrl': 'https://cdn.test/p.png',
        'totalStudyLevel': 5,
        'currentStreak': 3,
        'weeklyProblemCount': 10,
        'weeklyPracticeCount': 4,
        'todayPracticeCount': 2,
        'practicedToday': true,
        'weeklyGoal': 5,
        'goalProgress': 4,
      };

      final model = StudyRoomMemberModel.fromJson(json);

      expect(model.userId, 1);
      expect(model.name, '기승민');
      expect(model.profileImageUrl, 'https://cdn.test/p.png');
      expect(model.totalStudyLevel, 5);
      expect(model.currentStreak, 3);
      expect(model.weeklyProblemCount, 10);
      expect(model.weeklyPracticeCount, 4);
      expect(model.todayPracticeCount, 2);
      expect(model.practicedToday, isTrue);
      expect(model.weeklyGoal, 5);
      expect(model.goalProgress, 4);
    });
  });

  group('StudyRoomMemberModel.fromJson - nullable / 키 누락', () {
    test('선택 필드가 모두 null 이면 null 로 파싱된다', () {
      final model = StudyRoomMemberModel.fromJson({
        'userId': 1,
        'name': '기승민',
        'totalStudyLevel': 1,
        'currentStreak': 0,
        'weeklyProblemCount': 0,
        'weeklyPracticeCount': 0,
        'profileImageUrl': null,
        'todayPracticeCount': null,
        'practicedToday': null,
        'weeklyGoal': null,
        'goalProgress': null,
      });

      expect(model.profileImageUrl, isNull);
      expect(model.todayPracticeCount, isNull);
      expect(model.practicedToday, isNull);
      expect(model.weeklyGoal, isNull);
      expect(model.goalProgress, isNull);
    });

    test('키가 모두 없으면 기본값으로 떨어진다', () {
      final model = StudyRoomMemberModel.fromJson({});

      expect(model.userId, 0);
      expect(model.name, '알 수 없음');
      expect(model.totalStudyLevel, 1);
      expect(model.currentStreak, 0);
      expect(model.weeklyProblemCount, 0);
      expect(model.weeklyPracticeCount, 0);
    });

    test('숫자 필드가 double 로 와도 int 로 변환된다', () {
      final model = StudyRoomMemberModel.fromJson({
        'userId': 1.0,
        'name': '기승민',
        'totalStudyLevel': 5.0,
        'currentStreak': 3.0,
        'weeklyProblemCount': 10.0,
        'weeklyPracticeCount': 4.0,
        'todayPracticeCount': 2.0,
        'weeklyGoal': 5.0,
        'goalProgress': 4.0,
      });

      expect(model.userId, 1);
      expect(model.totalStudyLevel, 5);
      expect(model.todayPracticeCount, 2);
      expect(model.weeklyGoal, 5);
      expect(model.goalProgress, 4);
    });
  });

  group('StudyRoomMemberModel - 오늘 복습 여부 getter', () {
    test('practicedToday 가 명시되어 있으면 그 값을 그대로 쓴다', () {
      final model = StudyRoomMemberModel.fromJson({
        'userId': 1,
        'name': '기승민',
        'totalStudyLevel': 1,
        'currentStreak': 0,
        'weeklyProblemCount': 0,
        'weeklyPracticeCount': 0,
        'todayPracticeCount': 0,
        'practicedToday': true,
      });

      expect(model.hasPracticedToday, isTrue);
    });

    test('practicedToday 가 없으면 todayPracticeCount 로 유추한다', () {
      final model = StudyRoomMemberModel.fromJson({
        'userId': 1,
        'name': '기승민',
        'totalStudyLevel': 1,
        'currentStreak': 0,
        'weeklyProblemCount': 0,
        'weeklyPracticeCount': 0,
        'todayPracticeCount': 3,
      });

      expect(model.hasPracticedToday, isTrue);
      expect(model.displayTodayPracticeCount, 3);
    });

    test('practicedToday 도 todayPracticeCount 도 없으면 false, 0 이다', () {
      final model = StudyRoomMemberModel.fromJson({
        'userId': 1,
        'name': '기승민',
        'totalStudyLevel': 1,
        'currentStreak': 0,
        'weeklyProblemCount': 0,
        'weeklyPracticeCount': 0,
      });

      expect(model.hasPracticedToday, isFalse);
      expect(model.displayTodayPracticeCount, 0);
    });

    test('practicedToday 만 true 이고 todayPracticeCount 가 없으면 표시 카운트는 1이다', () {
      final model = StudyRoomMemberModel.fromJson({
        'userId': 1,
        'name': '기승민',
        'totalStudyLevel': 1,
        'currentStreak': 0,
        'weeklyProblemCount': 0,
        'weeklyPracticeCount': 0,
        'practicedToday': true,
      });

      expect(model.displayTodayPracticeCount, 1);
    });
  });

  group('StudyRoomMemberModel.copyWith', () {
    test('weeklyGoal, goalProgress 만 바꾸고 나머지는 유지한다', () {
      final original = StudyRoomMemberModel.fromJson({
        'userId': 1,
        'name': '기승민',
        'totalStudyLevel': 5,
        'currentStreak': 3,
        'weeklyProblemCount': 10,
        'weeklyPracticeCount': 4,
      });

      final updated = original.copyWith(weeklyGoal: 7, goalProgress: 2);

      expect(updated.userId, original.userId);
      expect(updated.name, original.name);
      expect(updated.weeklyGoal, 7);
      expect(updated.goalProgress, 2);
    });
  });
}
