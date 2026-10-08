import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/LearningReport/LearningOverviewModel.dart';

import '../../helpers/helpers.dart';

/// 학습 보고서 개편 API(`/api/learning-reports/overview`) 응답 모델.
///
/// 백엔드와 같은 계약으로 동시에 만들고 있어서, 필드가 비거나 빠졌을 때 화면이
/// 죽지 않는지가 중요하다.
void main() {
  setUpOnoTest();

  group('픽스처 파싱', () {
    test('기록이 있는 주간 보고서를 전부 읽는다', () {
      final model = LearningOverviewModel.fromJson(
        loadJsonFixture('learning_report/learning_overview_week.json'),
      );

      expect(model.period, LearningOverviewPeriod.week);
      expect(model.startDate, DateTime(2026, 10, 5));
      expect(model.endDate, DateTime(2026, 10, 11));
      expect(model.hasPrevious, isTrue);
      expect(model.hasNext, isFalse);

      expect(model.summary.reviewCount, 14);
      expect(model.summary.accuracy, 64.0);
      expect(model.summary.studyDays, 4);
      expect(model.summary.currentStreak, 5);

      expect(model.previous, isNotNull);
      expect(model.previous!.reviewCount, 9);
      expect(model.previous!.accuracy, 56.0);
      expect(model.previous!.studyDays, 3);

      final status = model.noteStatus;
      expect(status.totalCount, 86);
      expect(status.knownCount, 21);
      expect(status.unsureCount, 48);
      expect(status.unsolvedCount, 17);
      expect(status.newlyKnownCount, 3);
      expect(status.knownThreshold, 3);
      expect(
        status.knownCount + status.unsureCount + status.unsolvedCount,
        status.totalCount,
      );

      expect(model.weakFolders, hasLength(3));
      expect(model.weakFolders.first.folderId, 12);
      expect(model.weakFolders.first.name, '이차함수');
      expect(model.weakFolders.first.solveCount, 16);
      expect(model.weakFolders.first.wrongCount, 6);
      expect(model.weakFolders.first.accuracy, 38.0);

      expect(model.trend, hasLength(7));
      expect(model.trend[3].startDate, DateTime(2026, 10, 8));
      expect(model.trend[3].endDate, DateTime(2026, 10, 8));
      expect(model.trend[3].reviewCount, 7);
    });

    test('빈 기간은 정답률이 null 이고 폴더가 비어 있다', () {
      final model = LearningOverviewModel.fromJson(
        loadJsonFixture('learning_report/learning_overview_empty.json'),
      );

      expect(model.summary.reviewCount, 0);
      expect(model.summary.accuracy, isNull);
      expect(model.weakFolders, isEmpty);
      expect(model.trend.every((b) => b.reviewCount == 0), isTrue);
      expect(model.previous!.reviewCount, 11);
    });

    test('전체는 비교 기간이 없고 막대가 달마다 여섯 개다', () {
      final model = LearningOverviewModel.fromJson(
        loadJsonFixture('learning_report/learning_overview_total.json'),
      );

      expect(model.period, LearningOverviewPeriod.total);
      expect(model.previous, isNull);
      expect(model.hasPrevious, isFalse);
      expect(model.hasNext, isFalse);
      expect(model.trend, hasLength(6));
      expect(model.trend.first.startDate, DateTime(2026, 5, 1));
      expect(model.weakFolders.first.accuracy, 45.3);
    });
  });

  group('null 이거나 빠진 필드', () {
    test('빈 객체도 기본값으로 읽는다', () {
      final model = LearningOverviewModel.fromJson(const {});

      expect(model.period, LearningOverviewPeriod.week);
      expect(model.startDate, isNull);
      expect(model.endDate, isNull);
      expect(model.hasPrevious, isFalse);
      expect(model.hasNext, isFalse);
      expect(model.summary.reviewCount, 0);
      expect(model.summary.accuracy, isNull);
      expect(model.previous, isNull);
      expect(model.noteStatus.totalCount, 0);
      expect(model.noteStatus.knownThreshold, 3);
      expect(model.weakFolders, isEmpty);
      expect(model.trend, isEmpty);
    });

    test('값마다 null 이 와도 터지지 않는다', () {
      final model = LearningOverviewModel.fromJson({
        'period': null,
        'startDate': null,
        'endDate': null,
        'hasPrevious': null,
        'hasNext': null,
        'summary': {
          'reviewCount': null,
          'accuracy': null,
          'studyDays': null,
          'currentStreak': null,
        },
        'previous': null,
        'noteStatus': null,
        'weakFolders': null,
        'trend': [
          {'startDate': null, 'endDate': null, 'reviewCount': null},
        ],
      });

      expect(model.summary.studyDays, 0);
      expect(model.summary.currentStreak, 0);
      expect(model.noteStatus.knownCount, 0);
      expect(model.trend.single.startDate, isNull);
      expect(model.trend.single.reviewCount, 0);
    });

    test('폴더 이름과 정답률이 비면 빈 이름과 0 으로 읽는다', () {
      final model = LearningOverviewModel.fromJson({
        'weakFolders': [
          {'folderId': 3, 'name': null, 'accuracy': null},
        ],
      });

      expect(model.weakFolders.single.folderId, 3);
      expect(model.weakFolders.single.name, '');
      expect(model.weakFolders.single.accuracy, 0);
      expect(model.weakFolders.single.wrongCount, 0);
    });

    test('모르는 기간 값은 주간으로 본다', () {
      final model = LearningOverviewModel.fromJson({'period': 'YEAR'});
      expect(model.period, LearningOverviewPeriod.week);
    });

    test('숫자가 소수로 와도 정수로 읽는다', () {
      final model = LearningOverviewModel.fromJson({
        'summary': {'reviewCount': 14.0, 'accuracy': 64},
      });

      expect(model.summary.reviewCount, 14);
      expect(model.summary.accuracy, 64.0);
    });

    test('기준 횟수가 0 으로 오면 3 으로 둔다', () {
      final model = LearningOverviewModel.fromJson({
        'noteStatus': {'knownThreshold': 0},
      });
      expect(model.noteStatus.knownThreshold, 3);
    });

    test('목록 안에 객체가 아닌 값이 섞여 있으면 건너뛴다', () {
      final model = LearningOverviewModel.fromJson({
        'trend': [
          null,
          'x',
          {'reviewCount': 2},
        ],
      });
      expect(model.trend.single.reviewCount, 2);
    });
  });
}
