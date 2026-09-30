import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Screen/User/LearningCalendarScreen.dart';
import 'package:ono/Screen/User/Widget/StreakCard.dart';
import 'package:ono/Util/AppClock.dart';

import '../../helpers/helpers.dart';

/// StreakCard 는 didChangeDependencies/initState 에서 곧바로
/// `StudyCalendarService()` 를 직접 생성해 호출한다. 이 서비스를 테스트에서
/// 주입할 방법이 없어서(생성자 파라미터가 없음), 항상 진짜 HttpService 가
/// 만들어진다. 다만 테스트 환경에서는 TokenProvider 가 액세스 토큰을 못 찾아
/// UnauthorizedException 을 즉시 던지므로(실제 네트워크 요청까지는 가지 않는다),
/// 위젯은 "데이터 없음" 상태(currentStreak 등 null)로 안전하게 렌더링된다.
/// 그래서 이 파일에서는 "정상 데이터가 있을 때" 그림은 검증하지 못하고,
/// 데이터가 없는 상태(로딩 실패 상태)의 렌더링만 확인한다.
class _RecordingNavigatorObserver extends NavigatorObserver {
  int pushedRoutes = 0;

  @override
  void didPush(Route route, Route? previousRoute) {
    pushedRoutes++;
    super.didPush(route, previousRoute);
  }
}

void main() {
  setUpOnoWidgetTest();

  Future<void> pumpStreakCard(
    WidgetTester tester, {
    double horizontalMarginFactor = 0.04,
    Size surfaceSize = OnoSurface.phone,
    List<NavigatorObserver> navigatorObservers = const [],
  }) async {
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: StreakCard(
          themeProvider: ThemeHandler(),
          horizontalMarginFactor: horizontalMarginFactor,
        ),
      ),
      surfaceSize: surfaceSize,
      navigatorObservers: navigatorObservers,
    );
  }

  group('weekOfMonth 는 일요일 시작 주로 그 달의 몇 번째 주인지 센다', () {
    test('2026-09-30 은 9월 5주차다', () {
      expect(weekOfMonth(DateTime(2026, 9, 30)), 5);
    });

    test('1일이 일요일인 달은 7일까지가 1주차다', () {
      // 2026-02-01 은 일요일
      expect(weekOfMonth(DateTime(2026, 2, 1)), 1);
      expect(weekOfMonth(DateTime(2026, 2, 7)), 1);
      expect(weekOfMonth(DateTime(2026, 2, 8)), 2);
      expect(weekOfMonth(DateTime(2026, 2, 28)), 4);
    });

    test('1일이 토요일인 달은 1일 하루가 1주차이고 말일이 6주차일 수 있다', () {
      // 2026-08-01 은 토요일
      expect(weekOfMonth(DateTime(2026, 8, 1)), 1);
      expect(weekOfMonth(DateTime(2026, 8, 2)), 2);
      expect(weekOfMonth(DateTime(2026, 8, 31)), 6);
    });

    test('윤년 2월 29일', () {
      // 2028-02-01 은 화요일
      expect(weekOfMonth(DateTime(2028, 2, 29)), 5);
    });
  });

  testWidgets('데이터 로딩에 실패해도 제목과 이번 달 몇 주차인지가 보인다', (tester) async {
    await pumpStreakCard(tester);
    final now = AppClock.now();

    expect(find.text('학습 달력'), findsOneWidget);
    expect(find.text('${now.month}월 ${weekOfMonth(now)}주차'), findsOneWidget);
    // 화살표는 제목 줄 오른쪽 끝 하나뿐이다.
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('한 달 보기를 탭하면 펼쳐지고 접기 버튼으로 바뀐다', (tester) async {
    await pumpStreakCard(tester);

    expect(find.text('접기'), findsNothing);

    await tester.tap(find.text('한 달 보기'));
    await tester.pumpAndSettle();

    expect(find.text('접기'), findsOneWidget);
    // 조회에 실패했으면 펼쳐도 달력 대신 안내만 남는다.
    expect(find.text('기록을 불러오지 못했어요'), findsOneWidget);
  });

  testWidgets('접기를 탭하면 접힌다', (tester) async {
    await pumpStreakCard(tester);

    await tester.tap(find.text('한 달 보기'));
    await tester.pumpAndSettle();
    expect(find.text('접기'), findsOneWidget);

    await tester.tap(find.text('접기'));
    await tester.pumpAndSettle();
    expect(find.text('한 달 보기'), findsOneWidget);
    expect(find.text('접기'), findsNothing);
  });

  testWidgets('제목 줄을 탭하면 학습 달력 화면으로 이동한다', (tester) async {
    final observer = _RecordingNavigatorObserver();
    await pumpStreakCard(tester, navigatorObservers: [observer]);

    await tester.tap(find.text('학습 달력'));
    await tester.pumpAndSettle();

    expect(observer.pushedRoutes, greaterThanOrEqualTo(1));
    expect(find.byType(LearningCalendarScreen), findsOneWidget);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpStreakCard(tester, surfaceSize: OnoSurface.tablet);

    expect(tester.takeException(), isNull);
    expect(find.byType(StreakCard), findsOneWidget);
  });

  testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpStreakCard(tester, surfaceSize: OnoSurface.smallPhone);

    expect(tester.takeException(), isNull);
  });

  testWidgets('가로 여백이 0이어도(태블릿 그리드에서 쓰는 값) 예외 없이 그려진다', (tester) async {
    await pumpStreakCard(tester, horizontalMarginFactor: 0);

    expect(tester.takeException(), isNull);
  });
}
