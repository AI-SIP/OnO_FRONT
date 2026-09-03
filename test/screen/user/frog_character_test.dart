import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Text/StandardText.dart';
import 'package:ono/Screen/User/Widget/FrogCharacter.dart';

import '../../helpers/helpers.dart';

/// FrogCharacter 안에 있는 격려 메시지 목록을 그대로 옮겨 둔 것.
/// lib 코드를 참조(reflection)하는 대신, 탭 후 화면에 뜬 문구가 그 중
/// 하나인지만 확인하는 용도다.
const _encouragementMessages = [
  '오늘도 화이팅!',
  '잘하고 있어요!',
  '꾸준히 성장 중이에요!',
  '대단해요!',
  '멋져요!',
  '계속 이렇게!',
  '최고예요!',
  '실수는 성공의 밑거름!',
  '지금 정말 잘하고 있어요!',
  '어제보다 더 성장했네요!',
  '개굴! 만점까지 달려볼까요?',
  '집중하는 모습에 반해버렸어요!',
  '내가 지켜보고 있어요, 화이팅!',
  '고생 많았어요. 개굴!',
  '할 수 있다! 할 수 있다!',
  '내가 항상 응원하고 있어요.',
];

void main() {
  setUpOnoWidgetTest();

  Finder speechBubbleFinder() => find.byWidgetPredicate(
        (widget) =>
            widget is StandardText &&
            _encouragementMessages.contains(widget.text),
      );

  Future<void> pumpFrog(
    WidgetTester tester, {
    required int level,
    VoidCallback? onTap,
    double size = 180,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        Scaffold(
          body: FrogCharacter(level: level, onTap: onTap, size: size),
        ),
        surfaceSize: surfaceSize,
        settle: false,
      );
      await tester.pump();
    });
  }

  testWidgets('정상적으로 렌더되고 처음엔 격려 메시지가 없다', (tester) async {
    await pumpFrog(tester, level: 5);

    expect(find.byType(FrogCharacter), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(speechBubbleFinder(), findsNothing);
  });

  testWidgets('레벨 0(최하) 이어도 예외 없이 그려진다', (tester) async {
    await pumpFrog(tester, level: 0);

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('레벨이 매우 높아도 예외 없이 그려진다', (tester) async {
    await pumpFrog(tester, level: 999);

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('탭하면 onTap 콜백이 호출된다', (tester) async {
    var tapCount = 0;
    await pumpFrog(tester, level: 3, onTap: () => tapCount++);

    await tester.tap(find.byType(FrogCharacter));
    await tester.pump(const Duration(milliseconds: 50));

    expect(tapCount, 1);

    // 탭으로 예약된 2초짜리 메시지 숨김 타이머를 다 흘려보내야
    // 테스트 종료 시 "pending timer" 오류가 나지 않는다.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('탭하면 격려 메시지가 잠깐 보인다', (tester) async {
    await pumpFrog(tester, level: 3);

    await tester.tap(find.byType(FrogCharacter));
    // 확대/축소 애니메이션(300ms)이 끝날 때까지 진행시킨다.
    await tester.pump(const Duration(milliseconds: 350));

    expect(speechBubbleFinder(), findsOneWidget);

    // 메시지 숨김 타이머(2초)를 마저 흘려보낸다.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('2초 뒤에는 격려 메시지가 사라진다', (tester) async {
    await pumpFrog(tester, level: 3);

    await tester.tap(find.byType(FrogCharacter));
    await tester.pump(const Duration(milliseconds: 350));
    expect(speechBubbleFinder(), findsOneWidget);

    await tester.pump(const Duration(seconds: 2, milliseconds: 100));

    expect(speechBubbleFinder(), findsNothing);
  });

  testWidgets('onTap 이 없어도 탭하면 예외 없이 메시지만 뜬다', (tester) async {
    await pumpFrog(tester, level: 1, onTap: null);

    await tester.tap(find.byType(FrogCharacter));
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.takeException(), isNull);
    expect(speechBubbleFinder(), findsOneWidget);

    // 메시지 숨김 타이머(2초)를 마저 흘려보낸다.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpFrog(tester, level: 7, surfaceSize: OnoSurface.tablet);

    expect(tester.takeException(), isNull);
  });
}
