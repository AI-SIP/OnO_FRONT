import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/StudyRoom/WeeklyReportModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('WeeklyReportModel.fromJson - 정상 응답', () {
    test('모든 필드가 채워진 응답을 파싱한다', () {
      final json = {
        'reportId': 1,
        'topMemberName': '기승민',
        'topMemberProfileImageUrl': 'https://cdn.test/p1.png',
        'topMemberProblemCount': 15,
        'longestStreakName': '홍길동',
        'longestStreakProfileImageUrl': 'https://cdn.test/p2.png',
        'longestStreakDays': 7,
        'totalProblems': 40,
        'challengesCompleted': 2,
        'cheerMessage': '이번 주도 수고했어요!',
        'weekStart': '2026-01-01',
        'weekEnd': '2026-01-07',
        'isRead': true,
      };

      final model = WeeklyReportModel.fromJson(json);

      expect(model.reportId, 1);
      expect(model.topMemberName, '기승민');
      expect(model.topMemberProblemCount, 15);
      expect(model.longestStreakName, '홍길동');
      expect(model.longestStreakDays, 7);
      expect(model.totalProblems, 40);
      expect(model.challengesCompleted, 2);
      expect(model.cheerMessage, '이번 주도 수고했어요!');
      expect(model.weekStart, DateTime.parse('2026-01-01'));
      expect(model.weekEnd, DateTime.parse('2026-01-07'));
      expect(model.isRead, isTrue);
    });
  });

  group('WeeklyReportModel.fromJson - nullable / 키 누락', () {
    test('weekStart, weekEnd, 프로필 이미지가 null 이면 null 로 파싱된다', () {
      final model = WeeklyReportModel.fromJson({
        'reportId': 1,
        'topMemberName': '기승민',
        'topMemberProblemCount': 15,
        'longestStreakName': '홍길동',
        'longestStreakDays': 7,
        'totalProblems': 40,
        'challengesCompleted': 2,
        'cheerMessage': '메시지',
        'weekStart': null,
        'weekEnd': null,
      });

      expect(model.weekStart, isNull);
      expect(model.weekEnd, isNull);
      expect(model.topMemberProfileImageUrl, isNull);
      expect(model.longestStreakProfileImageUrl, isNull);
    });

    test('키가 모두 없으면 기본값으로 떨어진다', () {
      final model = WeeklyReportModel.fromJson({});

      expect(model.reportId, 0);
      expect(model.topMemberName, '없음');
      expect(model.longestStreakName, '없음');
      expect(model.totalProblems, 0);
      expect(model.cheerMessage, '');
      expect(model.isRead, isFalse);
    });

    test('숫자 필드가 double 로 와도 int 로 변환된다', () {
      final model = WeeklyReportModel.fromJson({
        'reportId': 1.0,
        'topMemberProblemCount': 15.0,
        'longestStreakDays': 7.0,
        'totalProblems': 40.0,
        'challengesCompleted': 2.0,
      });

      expect(model.reportId, 1);
      expect(model.topMemberProblemCount, 15);
      expect(model.longestStreakDays, 7);
      expect(model.totalProblems, 40);
      expect(model.challengesCompleted, 2);
    });
  });
}
