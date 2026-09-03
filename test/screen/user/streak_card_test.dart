import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Screen/User/LearningCalendarScreen.dart';
import 'package:ono/Screen/User/Widget/StreakCard.dart';

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

  testWidgets('데이터 로딩에 실패해도 헤더와 스트릭 배너가 보인다', (tester) async {
    await pumpStreakCard(tester);

    expect(find.textContaining('학습 달력'), findsOneWidget);
    expect(find.text('--'), findsOneWidget);
    expect(find.textContaining('일 연속 학습중'), findsOneWidget);
  });

  testWidgets('헤더를 탭하면 달력이 펼쳐지고 하단 통계가 보인다', (tester) async {
    await pumpStreakCard(tester);

    expect(find.textContaining('이번 달 최장 복습'), findsNothing);

    await tester.tap(find.textContaining('학습 달력'));
    await tester.pumpAndSettle();

    expect(find.textContaining('이번 달 최장 복습: --'), findsOneWidget);
    expect(find.textContaining('복습 일수: --'), findsOneWidget);
  });

  testWidgets('헤더를 다시 탭하면 접힌다', (tester) async {
    await pumpStreakCard(tester);

    await tester.tap(find.textContaining('학습 달력'));
    await tester.pumpAndSettle();
    expect(find.textContaining('이번 달 최장 복습'), findsOneWidget);

    await tester.tap(find.textContaining('학습 달력'));
    await tester.pumpAndSettle();
    expect(find.textContaining('이번 달 최장 복습'), findsNothing);
  });

  testWidgets('스트릭 배너를 탭하면 학습 달력 화면으로 이동한다', (tester) async {
    final observer = _RecordingNavigatorObserver();
    await pumpStreakCard(tester, navigatorObservers: [observer]);

    await tester.tap(find.textContaining('일 연속 학습중'));
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
