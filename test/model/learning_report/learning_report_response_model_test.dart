import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/LearningReport/LearningReportResponseModel.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoTest();

  group('LearningReportResponseModel.fromJson - 정상 응답 (깊은 중첩)', () {
    test('픽스처로 받은 전체 리포트를 weekly/monthly/total/추천까지 전부 파싱한다', () {
      final json = loadJsonFixture('learning_report/learning_report_full.json');

      final model = LearningReportResponseModel.fromJson(json);

      expect(model.weekly.periodLabel, '이번 주');
      expect(model.weekly.startDate, DateTime.parse('2026-02-23'));
      expect(model.weekly.trend, hasLength(2));
      expect(model.weekly.trend[1].label, '화');
      expect(model.weekly.weakAreas, hasLength(1));
      expect(model.weekly.weakAreas.first.topic, '이차방정식');
      expect(model.weekly.averageAccuracy, 0.82);

      expect(model.monthly.reviewCount, 48);
      expect(model.monthly.trend, isEmpty);

      expect(model.total.startDate, isNull);
      expect(model.total.reviewCount, 300);

      expect(model.weeklyComparison, isNotNull);
      expect(model.weeklyComparison!.basePeriod, '이번 주');
      expect(model.weeklyComparison!.reviewCountChangeRate, 0.2);
      expect(model.monthlyComparison, isNull);

      expect(model.recommendations.strengths, ['꾸준한 복습 습관']);
      expect(model.recommendations.nextWeekGoal, '복습 15회 달성하기');
      expect(model.recommendations.confidence, 0.9);
    });
  });

  group('LearningPeriodReport.fromJson - nullable / 키 누락', () {
    test('startDate, endDate 가 null 이면 null 로 파싱된다', () {
      final report = LearningPeriodReport.fromJson({
        'periodLabel': '이번 주',
        'startDate': null,
        'endDate': null,
        'noteWriteCount': 0,
        'notePracticeCount': 0,
        'reviewCount': 0,
        'averageAccuracy': 0,
        'consecutiveLearningDays': 0,
        'averageStudyTimeMinutes': 0,
        'trend': [],
        'weakAreas': [],
      });

      expect(report.startDate, isNull);
      expect(report.endDate, isNull);
    });

    test('startDate 가 빈 문자열이면 null 로 파싱된다', () {
      final report = LearningPeriodReport.fromJson({
        'periodLabel': '이번 주',
        'startDate': '',
        'noteWriteCount': 0,
        'notePracticeCount': 0,
        'reviewCount': 0,
        'averageAccuracy': 0,
        'consecutiveLearningDays': 0,
        'averageStudyTimeMinutes': 0,
      });

      expect(report.startDate, isNull);
    });

    test('trend, weakAreas 키가 없으면 빈 리스트가 된다', () {
      final report = LearningPeriodReport.fromJson({
        'periodLabel': '이번 주',
        'noteWriteCount': 0,
        'notePracticeCount': 0,
        'reviewCount': 0,
        'averageAccuracy': 0,
        'consecutiveLearningDays': 0,
        'averageStudyTimeMinutes': 0,
      });

      expect(report.trend, isEmpty);
      expect(report.weakAreas, isEmpty);
    });

    test('averageAccuracy 가 정수(int)로 와도 double 로 변환된다', () {
      final report = LearningPeriodReport.fromJson({
        'periodLabel': '이번 주',
        'noteWriteCount': 0,
        'notePracticeCount': 0,
        'reviewCount': 0,
        'averageAccuracy': 1,
        'consecutiveLearningDays': 0,
        'averageStudyTimeMinutes': 40,
      });

      expect(report.averageAccuracy, 1.0);
      expect(report.averageStudyTimeMinutes, 40.0);
    });

    test('키가 모두 없으면 기본값으로 떨어진다', () {
      final report = LearningPeriodReport.fromJson({});

      expect(report.periodLabel, '');
      expect(report.noteWriteCount, 0);
      expect(report.averageAccuracy, 0.0);
      expect(report.trend, isEmpty);
      expect(report.weakAreas, isEmpty);
    });
  });

  group('LearningReportRecommendations.fromJson - 키 누락', () {
    test('strengths, gaps, actions 키가 없으면 빈 리스트가 된다', () {
      final recommendations = LearningReportRecommendations.fromJson({
        'nextWeekGoal': '목표',
        'confidence': 0.5,
      });

      expect(recommendations.strengths, isEmpty);
      expect(recommendations.gaps, isEmpty);
      expect(recommendations.actions, isEmpty);
    });
  });

  group('LearningReportComparison.fromJson - 키 누락', () {
    test('키가 모두 없으면 기본값으로 떨어진다', () {
      final comparison = LearningReportComparison.fromJson({});

      expect(comparison.basePeriod, '');
      expect(comparison.compareTo, '');
      expect(comparison.reviewCountChangeRate, 0.0);
      expect(comparison.averageAccuracyChangeRate, 0.0);
      expect(comparison.consecutiveLearningDaysChangeRate, 0.0);
      expect(comparison.averageStudyTimeChangeRate, 0.0);
    });
  });

  group('LearningReportResponseModel.fromJson - 알려진 버그', () {
    test('weekly 키가 없어도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/LearningReport/LearningReportResponseModel.dart:20
      // `LearningPeriodReport.fromJson(json['weekly'])` 는 null 체크가 없어서,
      // weekly 키가 없으면 non-nullable Map 파라미터에 null 을 넘기게 되어
      // TypeError 로 크래시한다. weeklyComparison/monthlyComparison 은 null 체크가
      // 있는데 weekly/monthly/total/recommendations 만 빠져 있다.
      final json = {
        'monthly': {
          'periodLabel': '이번 달',
          'noteWriteCount': 0,
          'notePracticeCount': 0,
          'reviewCount': 0,
          'averageAccuracy': 0,
          'consecutiveLearningDays': 0,
          'averageStudyTimeMinutes': 0,
        },
        'total': {
          'periodLabel': '전체',
          'noteWriteCount': 0,
          'notePracticeCount': 0,
          'reviewCount': 0,
          'averageAccuracy': 0,
          'consecutiveLearningDays': 0,
          'averageStudyTimeMinutes': 0,
        },
        'recommendations': {
          'nextWeekGoal': '',
          'confidence': 0,
        },
      };

      expect(() => LearningReportResponseModel.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');

    test('recommendations 키가 없어도 크래시하지 않아야 한다', () {
      // TODO(#174): 실제 버그. lib/Model/LearningReport/LearningReportResponseModel.dart:29
      // `LearningReportRecommendations.fromJson(json['recommendations'])` 도
      // 마찬가지로 null 체크 없이 non-nullable Map 파라미터에 null 을 넘겨 크래시한다.
      final period = {
        'periodLabel': '리포트',
        'noteWriteCount': 0,
        'notePracticeCount': 0,
        'reviewCount': 0,
        'averageAccuracy': 0,
        'consecutiveLearningDays': 0,
        'averageStudyTimeMinutes': 0,
      };
      final json = {
        'weekly': period,
        'monthly': period,
        'total': period,
      };

      expect(() => LearningReportResponseModel.fromJson(json), returnsNormally);
    }, skip: '#174 에서 수정 예정');
  });
}
