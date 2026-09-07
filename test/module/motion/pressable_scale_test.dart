// PressableScale 위젯 테스트.
//
// 눌림 축소는 AnimatedScale 의 목표값(widget.scale)으로 확인한다. 실제로
// 그려진 크기를 재려면 애니메이션이 끝날 때까지 pump 해야 하는데, 목표값이
// 바뀌는 순간을 보는 쪽이 "손가락이 닿자마자 줄기 시작하는가"를 더 정확히
// 검증한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Motion/AppHaptic.dart';
import 'package:ono/Module/Motion/AppMotion.dart';
import 'package:ono/Module/Motion/PressableScale.dart';

import '../../helpers/helpers.dart';

/// 지금 PressableScale 이 목표로 삼고 있는 크기 비율.
double _targetScale(WidgetTester tester) {
  return tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
}

Widget _target({
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  bool enabled = true,
  HapticLevel haptic = HapticLevel.secondary,
}) {
  return Scaffold(
    body: Center(
      child: PressableScale(
        onTap: onTap,
        onLongPress: onLongPress,
        enabled: enabled,
        haptic: haptic,
        child: const SizedBox(width: 120, height: 60, child: Text('버튼')),
      ),
    ),
  );
}

void main() {
  setUpOnoWidgetTest();

  testWidgets('손가락이 닿으면 줄어들고 떼면 원래 크기로 돌아온다', (tester) async {
    await pumpOnoWidget(tester, _target(onTap: () {}));

    expect(_targetScale(tester), 1.0);

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('버튼')));
    await tester.pump();
    expect(_targetScale(tester), AppMotion.pressedScale);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_targetScale(tester), 1.0);
  });

  testWidgets('탭하면 onTap 이 한 번 불린다', (tester) async {
    var tapped = 0;
    await pumpOnoWidget(tester, _target(onTap: () => tapped++));

    await tester.tap(find.text('버튼'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
  });

  testWidgets('enabled 가 false 면 줄어들지도 않고 onTap 도 안 불린다', (tester) async {
    var tapped = 0;
    await pumpOnoWidget(tester, _target(onTap: () => tapped++, enabled: false));

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('버튼')));
    await tester.pump();
    expect(_targetScale(tester), 1.0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tapped, 0);
  });

  testWidgets('onTap 이 없으면 눌러도 줄어들지 않는다', (tester) async {
    await pumpOnoWidget(tester, _target());

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('버튼')));
    await tester.pump();

    expect(_targetScale(tester), 1.0);
    await gesture.up();
  });

  testWidgets('길게 누르면 onLongPress 가 불린다', (tester) async {
    var longPressed = 0;
    await pumpOnoWidget(
      tester,
      _target(onTap: () {}, onLongPress: () => longPressed++),
    );

    await tester.longPress(find.text('버튼'));
    await tester.pumpAndSettle();

    expect(longPressed, 1);
  });

  testWidgets('목록 안에서 스크롤을 시작하면 축소가 취소된다', (tester) async {
    // 스크롤되는 곳에서 손가락을 대고 끌면 탭이 취소되는데, 그때 원래 크기로
    // 돌아오지 않으면 항목이 줄어든 채로 남는다.
    var tapped = 0;
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: ListView(
          children: [
            PressableScale(
              onTap: () => tapped++,
              child: const SizedBox(height: 200, child: Text('항목')),
            ),
            const SizedBox(height: 1200),
          ],
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('항목')));
    await tester.pump();
    expect(_targetScale(tester), AppMotion.pressedScale);

    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    expect(_targetScale(tester), 1.0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tapped, 0, reason: '스크롤한 것이지 탭한 것이 아니다');
  });
}
