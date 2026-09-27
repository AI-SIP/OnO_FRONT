// MotionReplayScope 테스트.
//
// 홈은 탭 넷을 IndexedStack 으로 들고 있어서 앱을 켜는 순간 마이 페이지까지
// 함께 만들어진다. 그대로 두면 게이지가 탭을 누르기도 전에 다 차 있고 정작
// 화면에 들어갔을 때는 아무것도 움직이지 않는다. 그 상황을 그대로 재현한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Motion/AnimatedGauge.dart';
import 'package:ono/Module/Motion/AppMotion.dart';
import 'package:ono/Module/Motion/AppearTransition.dart';
import 'package:ono/Module/Motion/MotionReplayScope.dart';

import '../../helpers/helpers.dart';

/// 화면에 안 보이는 탭에 있어도 찾을 수 있어야 해서 offstage 를 포함한다.
double _fill(WidgetTester tester) {
  return tester
          .widget<FractionallySizedBox>(
              find.byType(FractionallySizedBox, skipOffstage: false))
          .widthFactor ??
      0.0;
}

/// 탭 둘을 IndexedStack 으로 들고 있고, 둘째 탭에 게이지가 있는 화면.
class _TabbedHome extends StatefulWidget {
  /// 감싸지 않으면 지금까지처럼 미리 다 차 버린다.
  final bool wrapWithScope;

  const _TabbedHome({this.wrapWithScope = true});

  @override
  State<_TabbedHome> createState() => _TabbedHomeState();
}

class _TabbedHomeState extends State<_TabbedHome> {
  int _index = 0;

  /// 이 탭에 몇 번째로 들어왔는지. 들어올 때마다 늘어난다.
  int _visitSequence = 0;

  void _goToGaugeTab() {
    setState(() {
      _index = 1;
      _visitSequence++;
    });
  }

  @override
  Widget build(BuildContext context) {
    const gaugeTab = AnimatedLinearGauge(value: 1.0, color: Colors.blue);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const Text('첫 탭'),
          widget.wrapWithScope
              ? MotionReplayScope(token: _visitSequence, child: gaugeTab)
              : gaugeTab,
        ],
      ),
      bottomNavigationBar: TextButton(
        onPressed: _goToGaugeTab,
        child: const Text('게이지 탭으로'),
      ),
    );
  }
}

void main() {
  setUpOnoWidgetTest();

  testWidgets('감싸지 않으면 탭에 들어가기 전에 이미 다 차 있다', (tester) async {
    // 이 이슈를 만든 이유를 남겨 두는 테스트다.
    await pumpOnoWidget(
      tester,
      const _TabbedHome(wrapWithScope: false),
    );

    expect(_fill(tester), closeTo(1.0, 0.001));

    await tester.tap(find.text('게이지 탭으로'));
    await tester.pump();
    expect(_fill(tester), closeTo(1.0, 0.001), reason: '차오르는 것을 볼 수 없다');
  });

  testWidgets('감싸면 탭에 들어갈 때 0 에서 다시 차오른다', (tester) async {
    await pumpOnoWidget(tester, const _TabbedHome());
    expect(_fill(tester), closeTo(1.0, 0.001));

    await tester.tap(find.text('게이지 탭으로'));
    await tester.pump();
    expect(_fill(tester), 0.0, reason: '들어온 순간에는 비어 있어야 한다');

    // 0 을 한 프레임 그린 다음 프레임부터 차오르기 시작한다.
    await tester.pump();
    await tester.pump(AppMotion.gauge ~/ 2);
    final midway = _fill(tester);
    expect(midway, greaterThan(0.0));
    expect(midway, lessThan(1.0));

    await tester.pumpAndSettle();
    expect(_fill(tester), closeTo(1.0, 0.001));
  });

  testWidgets('다시 들어갈 때마다 되풀이된다', (tester) async {
    await pumpOnoWidget(tester, const _TabbedHome());

    for (var visit = 0; visit < 3; visit++) {
      await tester.tap(find.text('게이지 탭으로'));
      await tester.pump();
      expect(_fill(tester), 0.0, reason: '${visit + 1}번째 진입');
      await tester.pumpAndSettle();
      expect(_fill(tester), closeTo(1.0, 0.001));
    }
  });

  testWidgets('등장 모션도 함께 다시 재생된다', (tester) async {
    var token = 0;

    Widget build(int token) => MotionReplayScope(
          token: token,
          child: const Scaffold(body: AppearTransition(child: Text('카드'))),
        );

    await pumpOnoWidget(tester, build(token));

    double opacity() => tester
        .widget<Opacity>(
          find.ancestor(of: find.text('카드'), matching: find.byType(Opacity)),
        )
        .opacity;

    expect(opacity(), 1.0);

    token++;
    await pumpOnoWidget(tester, build(token), settle: false);
    expect(opacity(), 0.0);

    await tester.pumpAndSettle();
    expect(opacity(), 1.0);
  });

  testWidgets('감싸지 않은 화면에서도 게이지는 그대로 동작한다', (tester) async {
    await pumpOnoWidget(
      tester,
      const Scaffold(body: AnimatedLinearGauge(value: 0.4, color: Colors.blue)),
    );

    expect(_fill(tester), closeTo(0.4, 0.001));
  });
}
