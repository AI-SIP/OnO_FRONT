import 'dart:math';
import 'package:ono/Config/AppConfig.dart';
import 'package:ono/Model/StudyCalendar/StudyCalendarModel.dart';

import '../HttpService.dart';

class StudyCalendarService {
  final HttpService httpService = HttpService();
  final String baseUrl = '${AppConfig.baseUrl}/api/learning-calendar';

  Future<StudyCalendarModel> getStudyCalendar({
    required int year,
    required int month,
  }) async {
    // TODO: 백엔드 API 준비 완료 시 아래 더미 데이터 제거 후 실제 API 호출로 교체
    return _generateDummyData(year, month);

    // 실제 API 호출 (백엔드 준비 후 활성화)
    // final data = await httpService.sendRequest(
    //   method: 'GET',
    //   url: baseUrl,
    //   queryParams: {'year': '$year', 'month': '$month'},
    // ) as Map<String, dynamic>;
    // return StudyCalendarModel.fromJson(data);
  }

  static StudyCalendarModel _generateDummyData(int year, int month) {
    final now = DateTime.now();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final records = <DailyStudyRecord>[];
    final random = Random(year * 100 + month); // 같은 월은 동일한 더미 생성

    // 더미 복습 항목 이름들
    final dummyItems = [
      '이차방정식 오답노트',
      '삼각함수 풀이',
      '수열의 극한 오답노트',
      '확률과 통계',
      '미적분 오답노트',
      '벡터의 내적',
      '지수로그함수 오답노트',
      '집합과 명제',
      '도형의 방정식',
      '함수의 극한 오답노트',
    ];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final isFuture =
          date.isAfter(DateTime(now.year, now.month, now.day));

      if (isFuture) {
        records.add(DailyStudyRecord(
          date: date,
          hasStudied: false,
          reviewCount: 0,
          noteWriteCount: 0,
          studyMinutes: 0,
          reviewedItems: [],
        ));
        continue;
      }

      // 오늘은 반드시 학습함 (더미 시연용)
      final hasStudied = isToday || random.nextInt(10) < 7;
      final reviewCount = hasStudied ? random.nextInt(19) + 1 : 0;
      final noteWriteCount = hasStudied ? random.nextInt(4) : 0;
      final studyMinutes = hasStudied ? random.nextInt(71) + 10 : 0;

      List<String> reviewedItems = [];
      if (hasStudied) {
        final itemCount = random.nextInt(4) + 1;
        final shuffled = List<String>.from(dummyItems)..shuffle(random);
        reviewedItems = shuffled.take(itemCount).toList();
      }

      records.add(DailyStudyRecord(
        date: date,
        hasStudied: hasStudied,
        reviewCount: reviewCount,
        noteWriteCount: noteWriteCount,
        studyMinutes: studyMinutes,
        reviewedItems: reviewedItems,
      ));
    }

    // currentStreak 계산 (오늘 기준 연속 학습일)
    int currentStreak = 0;
    final todayOrLastDay =
        now.month == month && now.year == year ? now.day : daysInMonth;
    for (int d = todayOrLastDay; d >= 1; d--) {
      final rec = records.firstWhere((r) => r.date.day == d,
          orElse: () => records.first);
      if (rec.hasStudied) {
        currentStreak++;
      } else {
        break;
      }
    }

    // bestStreak 계산 (이 달 내)
    int bestStreak = 0;
    int tempStreak = 0;
    for (final rec in records) {
      if (rec.hasStudied) {
        tempStreak++;
        if (tempStreak > bestStreak) bestStreak = tempStreak;
      } else {
        tempStreak = 0;
      }
    }

    final thisMonthStudyDays = records.where((r) => r.hasStudied).length;

    return StudyCalendarModel(
      year: year,
      month: month,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      thisMonthStudyDays: thisMonthStudyDays,
      records: records,
    );
  }
}
