// 복습을 마치고 기분을 고르는 줄. 복습 세트 완료 화면과 문제 복습 인증
// 화면이 같이 쓴다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Emoji/MoodPicker.dart';
import 'package:ono/Module/Emoji/OnoEmojiImage.dart';

import '../../helpers/helpers.dart';

/// 줄과 제목 옆 표를 함께 띄우고, 고른 것을 들고 있는 부모 흉내.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SelectedMoodChip(selectedKey: selected, color: Colors.pink),
          MoodPickerRow(
            selectedKey: selected,
            color: Colors.pink,
            onChanged: (key) => setState(() => selected = key),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpOnoWidgetTest();

  Finder emojiImage(String key) => find.byWidgetPredicate(
        (w) => w is OnoEmojiImage && w.emoji?.key == key,
      );

  testWidgets('더보기에서 추천에 없는 것을 고르면 창을 닫은 뒤에도 보인다', (tester) async {
    // 폰에서는 더보기 칸이 줄 맨 끝이라 화면 밖이다. 거기서 고른 것은 어느
    // 칸에도 없어서 창을 닫으면 무엇을 골랐는지 보이지 않았다.
    await pumpOnoWidget(tester, const _Host());
    await tester.scrollUntilVisible(
      find.byIcon(Icons.more_horiz),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('슬픔'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    // 제목 옆 그림과 줄 맨 앞 칸, 두 곳 모두 화면 안에 보인다. 이름 글자는
    // 적지 않는다.
    expect(find.text('슬픔'), findsNothing);
    expect(emojiImage('crying_in_rain').hitTestable(), findsNWidgets(2));
  });

  testWidgets('추천 칸을 고르면 제목 옆에 그림이 뜨고 다시 누르면 사라진다', (tester) async {
    await pumpOnoWidget(tester, const _Host());

    final first = emojiImage(MoodPickerRow.recommendedKeys.first);
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(find.byType(SelectedMoodChip), findsOneWidget);
    expect(first, findsNWidgets(2));

    await tester.tap(first.last);
    await tester.pumpAndSettle();
    expect(first, findsOneWidget);
  });
}
