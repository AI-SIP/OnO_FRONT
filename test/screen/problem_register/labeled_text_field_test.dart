import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemRegister/Widget/LabeledTextField.dart';

import '../../helpers/helpers.dart';

/// LabeledTextField 는 Scaffold 없이 그대로 `home:` 에 넣으면 Column 이
/// 화면 크기에 따라 무한대로 늘어나며 RenderFlex overflow 가 난다(태블릿 폭에서
/// 재현됨). Scaffold 로 감싸 정상적인 레이아웃 경계를 만들어 준다.
Widget _wrap(Widget child) => Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    ));

void main() {
  setUpOnoWidgetTest();

  testWidgets('라벨과 힌트 텍스트가 보인다', (tester) async {
    final controller = TextEditingController();
    await pumpOnoWidget(
      tester,
      _wrap(LabeledTextField(
        label: '제목',
        hintText: '오답노트의 제목을 작성해주세요!',
        controller: controller,
      )),
    );

    expect(find.text('제목'), findsOneWidget);
    expect(find.text('오답노트의 제목을 작성해주세요!'), findsOneWidget);
  });

  testWidgets('기존 controller 값이 필드에 그대로 보인다', (tester) async {
    final controller = TextEditingController(text: '기존 제목');
    await pumpOnoWidget(
      tester,
      _wrap(LabeledTextField(
          label: '제목', hintText: '힌트', controller: controller)),
    );

    expect(find.text('기존 제목'), findsOneWidget);
  });

  testWidgets('입력하면 controller 와 onChanged 둘 다 반영된다', (tester) async {
    final controller = TextEditingController();
    String? changed;
    await pumpOnoWidget(
      tester,
      _wrap(LabeledTextField(
        label: '메모',
        hintText: '힌트',
        controller: controller,
        onChanged: (v) => changed = v,
      )),
    );

    await tester.enterText(find.byType(TextField), '새로운 메모');
    await tester.pump();

    expect(controller.text, '새로운 메모');
    expect(changed, '새로운 메모');
  });

  testWidgets('showClearButton 이 false 면 X 아이콘이 없다', (tester) async {
    final controller = TextEditingController(text: '내용');
    await pumpOnoWidget(
      tester,
      _wrap(LabeledTextField(
        label: '메모',
        hintText: '힌트',
        controller: controller,
        showClearButton: false,
      )),
    );

    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('X 아이콘을 탭하면 controller 를 비우고 onChanged("") 를 부른다',
      (tester) async {
    final controller = TextEditingController(text: '지울 내용');
    String? changed;
    await pumpOnoWidget(
      tester,
      _wrap(LabeledTextField(
        label: '제목',
        hintText: '힌트',
        controller: controller,
        showClearButton: true,
        onChanged: (v) => changed = v,
      )),
    );

    expect(find.byIcon(Icons.close), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(controller.text, '');
    expect(changed, '');
  });

  testWidgets('maxLines 를 넘겨주면 TextField 에 그대로 반영된다', (tester) async {
    final controller = TextEditingController();
    await pumpOnoWidget(
      tester,
      _wrap(LabeledTextField(
        label: '메모',
        hintText: '힌트',
        controller: controller,
        maxLines: 3,
      )),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLines, 3);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    final controller = TextEditingController();
    await pumpOnoWidget(
      tester,
      _wrap(LabeledTextField(
          label: '제목', hintText: '힌트', controller: controller)),
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
