import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Screen/ProblemRegister/TagSelectionScreen.dart';

import '../../helpers/helpers.dart';
import '_test_support.dart';

/// TagSelectionScreen 은 TagService 를 상태 필드에서 직접
/// `TagService()` 로 만들어(TagSelectionScreen.dart:35) Provider 로도, 생성자로도
/// 주입할 수 없다. initState 가 곧바로 `_loadTags()` 를 fire-and-forget 으로
/// 부르기 때문에, 이 화면을 그리려면 실제로 HTTP 요청이 나가고 응답을 받아야
/// 한다(그렇지 않으면 인증/네트워크 예외가 잡히지 않고 그대로 튀어나와 테스트가
/// 즉시 실패한다 — TagSelectionScreen 의 _loadTags 에는 catch 가 없다).
/// `_test_support.dart` 의 `withFakeJsonApi` 로 dart:io 수준에서 HTTP 를
/// 가로채 고정된 JSON 을 돌려준다.
void main() {
  setUpOnoWidgetTest();

  setUp(() {
    seedValidAuthToken();
  });

  testWidgets('서버 태그가 없고 initialTags 도 없으면 빈 안내 문구가 보인다', (tester) async {
    await withFakeJsonApi(() async {
      await pumpOnoWidget(
        tester,
        const TagSelectionScreen(initialTags: [], initialSelectedTagIds: {}),
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }, json: []);

    expect(find.text('생성된 태그가 없습니다.'), findsOneWidget);
  });

  testWidgets('서버에서 받아온 태그 목록이 보인다', (tester) async {
    await withFakeJsonApi(() async {
      await pumpOnoWidget(
        tester,
        const TagSelectionScreen(initialTags: [], initialSelectedTagIds: {}),
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }, json: [
      {'tagId': 1, 'name': '수학'},
      {'tagId': 2, 'name': '영어'},
    ]);

    expect(find.text('수학'), findsOneWidget);
    expect(find.text('영어'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
  });

  testWidgets('initialSelectedTagIds 로 넘긴 태그가 처음부터 선택되어 표시된다', (tester) async {
    await withFakeJsonApi(() async {
      await pumpOnoWidget(
        tester,
        const TagSelectionScreen(
          initialTags: [],
          initialSelectedTagIds: {1},
        ),
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }, json: [
      {'tagId': 1, 'name': '수학'},
      {'tagId': 2, 'name': '영어'},
    ]);

    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('태그를 탭하면 선택 개수가 올라간다', (tester) async {
    await withFakeJsonApi(() async {
      await pumpOnoWidget(
        tester,
        const TagSelectionScreen(initialTags: [], initialSelectedTagIds: {}),
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('수학'));
      await tester.pump();
    }, json: [
      {'tagId': 1, 'name': '수학'},
    ]);

    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('선택된 태그를 다시 탭하면 선택이 풀린다', (tester) async {
    await withFakeJsonApi(() async {
      await pumpOnoWidget(
        tester,
        const TagSelectionScreen(
          initialTags: [],
          initialSelectedTagIds: {1},
        ),
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('1/5'), findsOneWidget);

      await tester.tap(find.text('수학'));
      await tester.pump();
    }, json: [
      {'tagId': 1, 'name': '수학'},
    ]);

    expect(find.text('0/5'), findsOneWidget);
  });

  testWidgets('태그를 6개 선택하고 확인을 누르면 5개 제한 경고 다이얼로그가 뜬다', (tester) async {
    final tags = List.generate(6, (i) => {'tagId': i + 1, 'name': '태그$i'});

    await withFakeJsonApi(() async {
      await pumpOnoWidget(
        tester,
        const TagSelectionScreen(initialTags: [], initialSelectedTagIds: {}),
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text('태그$i'));
        await tester.pump();
      }

      await tester.tap(find.text('확인'));
      await tester.pump();
    }, json: tags);

    expect(find.text('태그는 최대 5개까지만 선택할 수 있어요.'), findsOneWidget);
  });

  testWidgets('5개 이하로 선택하고 확인을 누르면 선택 결과를 반환하며 화면이 닫힌다', (tester) async {
    TagSelectionResult? result;

    await withFakeJsonApi(() async {
      await pumpOnoWidget(
        tester,
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<TagSelectionResult>(
                MaterialPageRoute(
                  builder: (_) => const TagSelectionScreen(
                    initialTags: [],
                    initialSelectedTagIds: {},
                  ),
                ),
              );
            },
            child: const Text('열기'),
          );
        }),
        settle: false,
      );
      await tester.pump();

      await tester.tap(find.text('열기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('수학'));
      await tester.pump();

      await tester.tap(find.text('확인'));
      await tester.pump();
    }, json: [
      {'tagId': 1, 'name': '수학'},
    ]);

    expect(result, isNotNull);
    expect(result!.selectedTagIds, [1]);
    expect(result!.availableTags.map((t) => t.name), contains('수학'));
  });

  testWidgets('새 태그 이름을 입력하고 생성을 누르면 목록에 추가된다', (tester) async {
    // GET(목록 조회)과 POST(생성)의 응답 모양이 다르므로 메서드별로 분기한다.
    await withFakeApi(() async {
      await pumpOnoWidget(
        tester,
        const TagSelectionScreen(initialTags: [], initialSelectedTagIds: {}),
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(find.byType(TextField), '새태그');
      await tester.tap(find.text('생성'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }, responder: (method, url) {
      if (method == 'POST') {
        return const ApiResponse({'tagId': 99, 'name': '새태그'});
      }
      return const ApiResponse(<Map<String, dynamic>>[]);
    });

    expect(find.text('새태그'), findsOneWidget);
  });

  testWidgets('더보기 메뉴에서 태그 삭제를 열면 삭제 대상 목록이 보인다', (tester) async {
    await withFakeJsonApi(() async {
      await pumpOnoWidget(
        tester,
        const TagSelectionScreen(initialTags: [], initialSelectedTagIds: {}),
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('태그 관리'), findsOneWidget);

      await tester.tap(find.text('태그 삭제'));
      await tester.pumpAndSettle();
    }, json: [
      {'tagId': 1, 'name': '수학'},
    ]);

    expect(find.text('삭제할 태그를 선택하세요'), findsOneWidget);
    expect(find.text('수학'), findsWidgets);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await withFakeJsonApi(() async {
      await pumpOnoWidget(
        tester,
        const TagSelectionScreen(initialTags: [], initialSelectedTagIds: {}),
        settle: false,
        surfaceSize: OnoSurface.tablet,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }, json: [
      {'tagId': 1, 'name': '수학'},
    ]);

    expect(tester.takeException(), isNull);
  });
}
