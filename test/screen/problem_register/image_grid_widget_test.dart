import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemRegister/Widget/ImageGridWidget.dart';

import '../../helpers/helpers.dart';
import '_test_support.dart';

Widget _wrap(Widget child) => Scaffold(
        body: Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    ));

void main() {
  setUpOnoWidgetTest();

  testWidgets('이미지가 없으면 추가 타일만 보인다', (tester) async {
    await pumpOnoWidget(
      tester,
      _wrap(ImageGridWidget(
        label: '문제 이미지',
        files: const [],
        onAdd: () {},
        onRemove: (_) {},
      )),
    );

    expect(find.text('문제 이미지'), findsOneWidget);
    expect(find.text('추가'), findsOneWidget);
    // 개수 배지는 이미지가 0장일 때 보이지 않는다.
    expect(find.text('0'), findsNothing);
  });

  testWidgets('로컬 파일 이미지가 그리드에 표시되고 개수 배지가 보인다', (tester) async {
    final file1 = writeFakePngFile('local1');
    final file2 = writeFakePngFile('local2');

    await pumpOnoWidget(
      tester,
      _wrap(ImageGridWidget(
        label: '문제 이미지',
        files: [file1, file2],
        onAdd: () {},
        onRemove: (_) {},
      )),
    );

    expect(find.text('2'), findsOneWidget); // 개수 배지
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('기존 이미지 URL 이 함께 있으면 총 개수가 합산된다', (tester) async {
    final file1 = writeFakePngFile('local1');

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        _wrap(ImageGridWidget(
          label: '문제 이미지',
          files: [file1],
          existingImageUrls: const [
            'https://example.com/a.png',
            'https://example.com/b.png',
          ],
          onAdd: () {},
          onRemove: (_) {},
          onRemoveExisting: (_) {},
        )),
      );
    });

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('추가 타일을 탭하면 onAdd 가 불린다', (tester) async {
    var addCount = 0;
    await pumpOnoWidget(
      tester,
      _wrap(ImageGridWidget(
        label: '문제 이미지',
        files: const [],
        onAdd: () => addCount++,
        onRemove: (_) {},
      )),
    );

    await tester.tap(find.text('추가'));
    await tester.pump();

    expect(addCount, 1);
  });

  testWidgets('로컬 이미지의 삭제 아이콘을 탭하면 onRemove 가 해당 인덱스로 불린다', (tester) async {
    final file1 = writeFakePngFile('local1');
    final file2 = writeFakePngFile('local2');
    int? removedIndex;

    await pumpOnoWidget(
      tester,
      _wrap(ImageGridWidget(
        label: '문제 이미지',
        files: [file1, file2],
        onAdd: () {},
        onRemove: (i) => removedIndex = i,
      )),
    );

    // 삭제(X) 아이콘이 로컬 이미지 2장에 대해 2개 있어야 한다.
    final closeIcons = find.byIcon(Icons.close);
    expect(closeIcons, findsNWidgets(2));

    await tester.tap(closeIcons.first);
    await tester.pump();

    expect(removedIndex, 0);
  });

  testWidgets('기존 이미지의 삭제 아이콘을 탭하면 onRemoveExisting 이 해당 인덱스로 불린다',
      (tester) async {
    int? removedIndex;

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        _wrap(ImageGridWidget(
          label: '문제 이미지',
          files: const [],
          existingImageUrls: const ['https://example.com/a.png'],
          onAdd: () {},
          onRemove: (_) {},
          onRemoveExisting: (i) => removedIndex = i,
        )),
      );
    });

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(removedIndex, 0);
  });

  testWidgets('showHeader 가 false 면 라벨 영역이 보이지 않는다', (tester) async {
    await pumpOnoWidget(
      tester,
      _wrap(ImageGridWidget(
        label: '문제 이미지',
        files: const [],
        onAdd: () {},
        onRemove: (_) {},
        showHeader: false,
      )),
    );

    expect(find.text('문제 이미지'), findsNothing);
    expect(find.text('추가'), findsOneWidget);
  });

  testWidgets('로컬 이미지를 탭하면 전체 화면 뷰어로 이동한다', (tester) async {
    final file1 = writeFakePngFile('local1');

    await pumpOnoWidget(
      tester,
      _wrap(ImageGridWidget(
        label: '문제 이미지',
        files: [file1],
        onAdd: () {},
        onRemove: (_) {},
      )),
    );

    // 삭제 아이콘이 아닌, 이미지 자체(GestureDetector)를 탭한다.
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    final file1 = writeFakePngFile('local1');

    await pumpOnoWidget(
      tester,
      _wrap(ImageGridWidget(
        label: '문제 이미지',
        files: [file1],
        onAdd: () {},
        onRemove: (_) {},
      )),
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
