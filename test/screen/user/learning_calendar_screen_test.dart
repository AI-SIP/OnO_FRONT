// 학습 달력 일기장 개편(#290) 테스트.
//
// 화면 모양을 일기장 두 장으로 바꾸면서 데이터와 동작은 그대로 두었다.
// 칸 표시, 상태별 문구, 애널리틱스 4종, 태블릿 가로 배치가 명세서대로인지 본다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/StudyCalendar/StudyCalendarModel.dart';
import 'package:ono/Module/Emoji/OnoEmojiImage.dart';
import 'package:ono/Module/Emoji/OnoEmojiPicker.dart';
import 'package:ono/Screen/User/LearningCalendarScreen.dart';
import 'package:ono/Screen/User/Widget/CalendarDaySheet.dart';
import 'package:ono/Screen/User/Widget/CalendarMonthSheet.dart';
import 'package:ono/Screen/User/Widget/DiaryPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/helpers.dart';

DailyStudyRecord _record(
  DateTime date, {
  int reviews = 2,
  int notes = 0,
  int minutes = 12,
  List<String> items = const [],
  String? mood,
  bool studied = true,
}) {
  return DailyStudyRecord(
    date: date,
    hasStudied: studied,
    reviewCount: reviews,
    noteWriteCount: notes,
    studyMinutes: minutes,
    reviewedItems: items,
    moodEmojiKey: mood,
  );
}

void main() {
  setUpOnoWidgetTest();

  late MockStudyCalendarService service;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final prevMonth = DateTime(now.year, now.month - 1, 1);

  /// 달마다 돌려줄 기록. 없으면 빈 달이다.
  late Map<String, StudyCalendarModel> calendars;
  String keyOf(int year, int month) => '$year-$month';

  StudyCalendarModel calendar(
    DateTime month, {
    int streak = 12,
    int best = 5,
    int days = 3,
    List<DailyStudyRecord> records = const [],
  }) =>
      StudyCalendarModel(
        year: month.year,
        month: month.month,
        currentStreak: streak,
        bestStreak: best,
        thisMonthStudyDays: days,
        records: records,
      );

  setUpAll(() => registerFallbackValue(DateTime(2000)));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetAnalyticsRecorder();
    service = MockStudyCalendarService();
    calendars = {};
    when(() => service.getStudyCalendar(
          year: any(named: 'year'),
          month: any(named: 'month'),
          showErrorSnackBar: any(named: 'showErrorSnackBar'),
        )).thenAnswer((invocation) async {
      final year = invocation.namedArguments[#year] as int;
      final month = invocation.namedArguments[#month] as int;
      return calendars[keyOf(year, month)] ??
          calendar(DateTime(year, month), streak: 0, best: 0, days: 0);
    });
    when(() => service.updateMoodEmoji(
          date: any(named: 'date'),
          emojiKey: any(named: 'emojiKey'),
          showErrorSnackBar: any(named: 'showErrorSnackBar'),
        )).thenAnswer((_) async {});
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size surfaceSize = OnoSurface.phone,
  }) async {
    disableAnimationsForTest(tester);
    await pumpOnoWidget(
      tester,
      LearningCalendarScreen(service: service),
      surfaceSize: surfaceSize,
    );
  }

  /// 기록 요약 한 문장. 형광펜 조각은 글자 대신 자리표(\uFFFC)로 나온다.
  String summaryText(WidgetTester tester) => tester
      .widget<Text>(find.byKey(CalendarDaySheet.summaryKey))
      .textSpan!
      .toPlainText();

  Future<void> goPrevMonth(WidgetTester tester) async {
    await tester.tap(find.byKey(CalendarMonthSheet.prevMonthKey));
    await tester.pumpAndSettle();
  }

  Future<void> tapDay(WidgetTester tester, int day) async {
    final cell = find.byKey(CalendarMonthSheet.dayKey(day));
    await tester.ensureVisible(cell);
    await tester.tap(cell);
    await tester.pumpAndSettle();
  }

  group('달력 칸', () {
    testWidgets('공부한 날만 원을 칠하고 오늘은 테두리, 기분 스티커, 일기 연필이 붙는다', (tester) async {
      calendars[keyOf(today.year, today.month)] = calendar(
        today,
        records: [_record(today, mood: 'birthday_cake')],
      );
      SharedPreferences.setMockInitialValues({
        'diary_text_${today.year}_${today.month}_${today.day}': '오늘 일기',
      });

      await pumpScreen(tester);

      final day = today.day;
      final otherDay = day == 1 ? 2 : 1;
      expect(find.byKey(CalendarMonthSheet.studiedKey(day)), findsOneWidget);
      expect(find.byKey(CalendarMonthSheet.todayKey(day)), findsOneWidget);
      expect(find.byKey(CalendarMonthSheet.moodKey(day)), findsOneWidget);
      expect(find.byKey(CalendarMonthSheet.diaryKey(day)), findsOneWidget);
      // 공부 안 한 날은 원 없이 숫자만.
      expect(find.byKey(CalendarMonthSheet.studiedKey(otherDay)), findsNothing);
      expect(find.byKey(CalendarMonthSheet.moodKey(otherDay)), findsNothing);
      expect(find.byKey(CalendarMonthSheet.diaryKey(otherDay)), findsNothing);
      // 들어오면 오늘을 골라 두지만, 오늘은 테두리가 있어 점선을 겹치지 않는다.
      expect(find.byKey(CalendarMonthSheet.selectedKey(day)), findsNothing);
      expect(find.byKey(DiaryPage.embeddedTitleKey), findsOneWidget);
      expect(find.text('오늘의 일기'), findsOneWidget);
    });

    testWidgets('오늘이 아닌 날을 고르면 그 칸에 점선 테두리가 생긴다', (tester) async {
      calendars[keyOf(prevMonth.year, prevMonth.month)] = calendar(
        prevMonth,
        records: [_record(DateTime(prevMonth.year, prevMonth.month, 10))],
      );
      await pumpScreen(tester);
      await goPrevMonth(tester);

      await tapDay(tester, 10);

      expect(find.byKey(CalendarMonthSheet.selectedKey(10)), findsOneWidget);
      expect(find.byKey(CalendarMonthSheet.studiedKey(10)), findsOneWidget);
      expect(find.byKey(CalendarMonthSheet.selectedKey(11)), findsNothing);
      expect(find.text('${prevMonth.month}월 10일'), findsOneWidget);
      expect(find.text('이 날의 일기'), findsOneWidget);

      // 같은 날을 다시 누르면 전처럼 고른 것이 풀린다.
      await tapDay(tester, 10);
      expect(find.byKey(CalendarMonthSheet.selectedKey(10)), findsNothing);
      expect(find.byType(DiaryPage), findsNothing);
    });
  });

  group('머리 문장', () {
    testWidgets('머리는 연속 일수와 이번 달 공부한 날 두 줄만 적는다', (tester) async {
      calendars[keyOf(today.year, today.month)] =
          calendar(today, streak: 12, days: 22, best: 7);
      await pumpScreen(tester);

      expect(find.text('12일째 공부 중'), findsOneWidget);
      expect(find.text('이번 달엔 22일 공부했어요'), findsOneWidget);
      // 머리가 빽빽해 보여 최고 기록 형광펜은 뺐다.
      expect(find.textContaining('최고 기록'), findsNothing);
    });

    testWidgets('연속 0일, 기록 없는 달이면 명세서 문구로 바꾸고 최고 기록은 뺀다', (tester) async {
      calendars[keyOf(today.year, today.month)] =
          calendar(today, streak: 0, days: 0, best: 0);
      await pumpScreen(tester);

      expect(find.text('오늘 공부하면 1일째가 돼요'), findsOneWidget);
      expect(find.text('이번 달엔 아직 공부한 날이 없어요'), findsOneWidget);
      expect(find.textContaining('최고 기록'), findsNothing);
    });

    testWidgets('지난달을 보면 이번 달 대신 그 달 이름으로 적는다', (tester) async {
      calendars[keyOf(prevMonth.year, prevMonth.month)] =
          calendar(prevMonth, streak: 3, days: 9, best: 4);
      await pumpScreen(tester);
      await goPrevMonth(tester);

      expect(find.text('${prevMonth.month}월엔 9일 공부했어요'), findsOneWidget);
    });
  });

  group('기록 장', () {
    testWidgets('오늘 기록을 한 문장으로 적고 숫자에 형광펜, 복습한 문제를 체크 목록으로 적는다',
        (tester) async {
      calendars[keyOf(today.year, today.month)] = calendar(
        today,
        records: [
          _record(
            today,
            reviews: 2,
            notes: 1,
            minutes: 12,
            items: ['물리학1 역학적 에너지 7번'],
          ),
        ],
      );
      await pumpScreen(tester);

      expect(summaryText(tester), startsWith('오늘은 '));
      expect(summaryText(tester), endsWith(' 공부했어요'));
      expect(find.text('복습 2번'), findsOneWidget);
      expect(find.text('오답노트 1개'), findsOneWidget);
      expect(find.text('12분'), findsOneWidget);
      expect(find.text('복습한 문제'), findsOneWidget);
      expect(find.text('물리학1 역학적 에너지 7번'), findsOneWidget);
      expect(find.text('기분 남기기'), findsOneWidget);
    });

    testWidgets('노트를 안 쓴 날은 노트 수를 빼고, 지난 날은 이 날은 으로 시작한다', (tester) async {
      final day = DateTime(prevMonth.year, prevMonth.month, 12);
      calendars[keyOf(prevMonth.year, prevMonth.month)] = calendar(
        prevMonth,
        records: [_record(day, reviews: 3, notes: 0, minutes: 5)],
      );
      await pumpScreen(tester);
      await goPrevMonth(tester);
      await tapDay(tester, 12);

      expect(summaryText(tester), startsWith('이 날은 '));
      expect(find.text('복습 3번'), findsOneWidget);
      expect(find.textContaining('오답노트'), findsNothing);
    });

    testWidgets('기록 없는 날은 없다고 적고 복습 목록을 숨기지만 일기는 쓸 수 있다', (tester) async {
      await pumpScreen(tester);

      expect(find.text('이 날은 공부 기록이 없어요'), findsOneWidget);
      expect(find.byKey(CalendarDaySheet.reviewedListKey), findsNothing);
      expect(find.byKey(CalendarDaySheet.moodButtonKey), findsNothing);
      expect(find.byKey(DiaryPage.writeButtonKey), findsOneWidget);
    });

    testWidgets('기분이 있으면 기분 바꾸기로 적는다', (tester) async {
      calendars[keyOf(today.year, today.month)] = calendar(
        today,
        records: [_record(today, mood: 'birthday_cake')],
      );
      await pumpScreen(tester);

      expect(find.text('기분 바꾸기'), findsOneWidget);
      expect(find.text('기분 남기기'), findsNothing);
    });
  });

  group('달력 조회 실패', () {
    testWidgets('머리에 다시 불러오기를 띄우고 기록은 숨기되 일기는 쓸 수 있다', (tester) async {
      when(() => service.getStudyCalendar(
            year: any(named: 'year'),
            month: any(named: 'month'),
            showErrorSnackBar: any(named: 'showErrorSnackBar'),
          )).thenAnswer((_) async => throw Exception('서버 오류'));
      await pumpScreen(tester);

      expect(find.text('기록을 불러오지 못했어요'), findsOneWidget);
      expect(find.byKey(CalendarMonthSheet.retryKey), findsOneWidget);
      expect(find.byKey(CalendarDaySheet.summaryKey), findsNothing);
      expect(find.byKey(DiaryPage.writeButtonKey), findsOneWidget);

      // 다시 불러오기가 되면 머리 문장이 돌아온다.
      when(() => service.getStudyCalendar(
            year: any(named: 'year'),
            month: any(named: 'month'),
            showErrorSnackBar: any(named: 'showErrorSnackBar'),
          )).thenAnswer((_) async => calendar(today, streak: 4));
      await tester.tap(find.byKey(CalendarMonthSheet.retryKey));
      await tester.pumpAndSettle();

      expect(find.text('기록을 불러오지 못했어요'), findsNothing);
      expect(find.text('4일째 공부 중'), findsOneWidget);
    });
  });

  group('애널리틱스는 그대로 남긴다', () {
    Map<String, Object?>? paramsOf(String name) {
      final index = analyticsRecorder.loggedEvents.lastIndexOf(name);
      if (index < 0) return null;
      return analyticsRecorder.loggedParameters[index];
    }

    testWidgets('화면 조회와 월 이동', (tester) async {
      await pumpScreen(tester);

      expect(
        paramsOf('screen_view'),
        containsPair('screen_name', 'LearningCalendarScreen'),
      );

      await goPrevMonth(tester);
      expect(
        paramsOf('calendar_month_change'),
        containsPair('direction', 'prev'),
      );

      await tester.tap(find.byKey(CalendarMonthSheet.nextMonthKey));
      await tester.pumpAndSettle();
      expect(
        paramsOf('calendar_month_change'),
        containsPair('direction', 'next'),
      );
    });

    testWidgets('이번 달에서는 다음 달로 넘어가지 않고 이벤트도 남기지 않는다', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(CalendarMonthSheet.nextMonthKey));
      await tester.pumpAndSettle();

      expect(analyticsRecorder.loggedEvents,
          isNot(contains('calendar_month_change')));
      expect(find.text('${today.year}년 ${today.month}월'), findsOneWidget);
    });

    testWidgets('일기 저장', (tester) async {
      await pumpScreen(tester);

      await tester.ensureVisible(find.byKey(DiaryPage.writeButtonKey));
      await tester.tap(find.byKey(DiaryPage.writeButtonKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '오늘은 함수를 복습했다');
      await tester.ensureVisible(find.byKey(DiaryPage.saveButtonKey));
      await tester.tap(find.byKey(DiaryPage.saveButtonKey));
      await tester.pumpAndSettle();

      final params = paramsOf('calendar_diary_saved');
      expect(params, isNotNull);
      expect(params, containsPair('is_delete', 'false'));
      expect(find.text('오늘은 함수를 복습했다'), findsOneWidget);
      expect(
        find.byKey(CalendarMonthSheet.diaryKey(today.day)),
        findsOneWidget,
      );
      // 기록 장 안에서는 고쳐 쓰기가 머리 오른쪽 밑줄 글씨로 붙는다.
      expect(find.byKey(DiaryPage.editButtonKey), findsOneWidget);
      expect(find.byKey(DiaryPage.stampKey), findsOneWidget);
    });

    testWidgets('기분 남기기', (tester) async {
      calendars[keyOf(today.year, today.month)] = calendar(
        today,
        records: [_record(today)],
      );
      await pumpScreen(tester);

      await tester.tap(find.byKey(CalendarDaySheet.moodButtonKey));
      await tester.pumpAndSettle();
      final emoji = find.descendant(
        of: find.descendant(
          of: find.byType(OnoEmojiPicker),
          matching: find.byType(GridView),
        ),
        matching: find.byType(OnoEmojiImage),
      );
      await tester.tap(emoji.first);
      await tester.pumpAndSettle();

      verify(() => service.updateMoodEmoji(
            date: today,
            emojiKey: any(named: 'emojiKey'),
            showErrorSnackBar: false,
          )).called(1);
      final params = paramsOf('mood_set');
      expect(params, isNotNull);
      expect(params, containsPair('is_change', 'false'));
    });
  });

  group('연월 선택 창', () {
    testWidgets('다른 달을 고르면 그 달로 바뀌고, 미래 달은 눌리지 않는다', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(CalendarMonthSheet.monthLabelKey));
      await tester.pumpAndSettle();

      // 이번 해에서는 다음 해로 넘어가지 않는다.
      await tester.tap(
        find.byKey(LearningCalendarScreen.monthPickerNextYearKey),
      );
      await tester.pumpAndSettle();
      expect(find.text('${today.year}년'), findsOneWidget);

      // 미래 달은 눌러도 창이 닫히지 않고 달도 그대로다.
      if (today.month < 12) {
        await tester.tap(
          find.byKey(LearningCalendarScreen.monthPickerMonthKey(
            today.month + 1,
          )),
        );
        await tester.pumpAndSettle();
        expect(find.text('${today.year}년'), findsOneWidget);
      }

      // 지난해 3월을 고르면 창이 닫히고 그 달을 불러온다.
      await tester.tap(
        find.byKey(LearningCalendarScreen.monthPickerPrevYearKey),
      );
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(LearningCalendarScreen.monthPickerMonthKey(3)));
      await tester.pumpAndSettle();

      expect(find.text('${today.year - 1}년'), findsNothing);
      expect(find.text('${today.year - 1}년 3월'), findsOneWidget);
      verify(() => service.getStudyCalendar(
            year: today.year - 1,
            month: 3,
            showErrorSnackBar: false,
          )).called(1);
    });
  });

  group('배치', () {
    Rect sheetRect(WidgetTester tester, Type type) =>
        tester.getRect(find.byType(type));

    testWidgets('폰에서는 두 장을 위아래로 쌓는다', (tester) async {
      await pumpScreen(tester);

      final month = sheetRect(tester, CalendarMonthSheet);
      final day = sheetRect(tester, CalendarDaySheet);
      expect(day.top, greaterThan(month.bottom));
      expect(tester.takeException(), isNull);
    });

    testWidgets('가로 태블릿에서는 달력 장을 왼쪽 560 폭, 기록 장을 오른쪽에 펼친다', (tester) async {
      await pumpScreen(tester, surfaceSize: const Size(1194, 834));

      final month = sheetRect(tester, CalendarMonthSheet);
      final day = sheetRect(tester, CalendarDaySheet);
      expect(month.width, closeTo(560, 0.5));
      expect(day.left, greaterThan(month.right));
      expect(day.top, closeTo(month.top, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('세로 태블릿은 폭이 900 에 못 미쳐 위아래로 쌓는다', (tester) async {
      await pumpScreen(tester, surfaceSize: OnoSurface.tablet);

      final month = sheetRect(tester, CalendarMonthSheet);
      final day = sheetRect(tester, CalendarDaySheet);
      expect(day.top, greaterThan(month.bottom));
      expect(tester.takeException(), isNull);
    });

    testWidgets('글자를 키운 작은 폰에서도 넘치지 않는다', (tester) async {
      calendars[keyOf(today.year, today.month)] = calendar(
        today,
        records: [
          _record(today, notes: 3, items: ['아주 긴 문제 제목' * 5]),
        ],
      );
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpScreen(tester, surfaceSize: OnoSurface.smallPhone);

      expect(tester.takeException(), isNull);
    });
  });
}
