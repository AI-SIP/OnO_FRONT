// FolderNavigationButtons 위젯 테스트.
//
// 이름과 달리 이 위젯은 "폴더 탐색"이 아니라 문제 상세 화면 하단의
// "복습 인증" 버튼이다. 현재 문제(currentId)가 FoldersProvider 가 들고 있는
// 문제 목록(currentProblems) 안에 있을 때만 버튼을 그리고, 탭하면 복습
// 이미지를 등록하는 다이얼로그를 띄운다. 폴더 경로 표시나 상위 폴더 이동
// 버튼은 이 파일에 없다 — 최종 보고에 기록한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Module/Util/FolderNavigationButtons.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';

import '../../helpers/helpers.dart';

FolderModel _folder(int id) => FolderModel(
      folderId: id,
      folderName: 'folder-$id',
      problemIdList: const [],
      subFolderList: const [],
    );

ProblemModel _problem(int id) => ProblemModel(problemId: id, folderId: 1);

/// currentProblems 에 [problems] 가 담긴 FoldersProvider 를 만든다.
///
/// FoldersProvider.moveToFolder 는 폴더 캐시가 이미 있으면(saveProblemsToCache
/// 로 미리 채워 두면) 하위 폴더/문제를 서버에서 다시 불러오지 않고 캐시를 그대로
/// 쓴다. 그래서 getRootFolder 하나만 stub 하면 네트워크 없이 currentProblems 를
/// 채울 수 있다.
Future<FoldersProvider> _providerWithProblems(
    List<ProblemModel> problems) async {
  final folderService = MockFolderService();
  when(() => folderService.getRootFolder()).thenAnswer((_) async => _folder(1));

  final provider = FoldersProvider(
    problemsProvider: ProblemsProvider(),
    folderService: folderService,
  );
  await provider.fetchRootFolder();
  provider.saveProblemsToCache(1, problems, null, false);
  await provider.moveToFolder(1);
  return provider;
}

/// [FolderNavigationButtons.context] 필드는 생성자에만 저장되고 build 안에서는
/// 쓰이지 않는다(위젯 자체의 build context 를 따로 쓴다) — 아무 유효한
/// BuildContext 나 넘겨도 된다.
Widget _buildTarget({
  required FoldersProvider foldersProvider,
  required int currentId,
  VoidCallback? onRefresh,
}) {
  return Builder(
    builder: (context) => Scaffold(
      body: FolderNavigationButtons(
        context: context,
        foldersProvider: foldersProvider,
        currentId: currentId,
        onRefresh: onRefresh ?? () {},
      ),
    ),
  );
}

void main() {
  setUpOnoWidgetTest();

  testWidgets('문제 목록이 비어 있으면 버튼이 그려지지 않는다', (tester) async {
    final foldersProvider =
        FoldersProvider(problemsProvider: ProblemsProvider());

    await pumpOnoWidget(
      tester,
      _buildTarget(foldersProvider: foldersProvider, currentId: 1),
    );

    expect(find.byType(ElevatedButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('currentId 가 문제 목록에 없으면 버튼이 그려지지 않는다', (tester) async {
    final foldersProvider =
        await _providerWithProblems([_problem(1), _problem(2)]);

    await pumpOnoWidget(
      tester,
      _buildTarget(foldersProvider: foldersProvider, currentId: 999),
    );

    expect(find.byType(ElevatedButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('currentId 가 문제 목록 중간에 있어도 정확히 찾아 버튼을 그린다', (tester) async {
    final foldersProvider =
        await _providerWithProblems([_problem(10), _problem(20), _problem(30)]);

    await pumpOnoWidget(
      tester,
      _buildTarget(foldersProvider: foldersProvider, currentId: 20),
    );

    expect(find.text('복습 인증'), findsOneWidget);
    expect(find.byIcon(Icons.touch_app), findsOneWidget);
  });

  testWidgets('버튼을 탭하면 복습 확인 다이얼로그가 뜬다', (tester) async {
    final foldersProvider = await _providerWithProblems([_problem(1)]);

    await pumpOnoWidget(
      tester,
      _buildTarget(foldersProvider: foldersProvider, currentId: 1),
    );

    await tester.tap(find.text('복습 인증'));
    await tester.pumpAndSettle();

    expect(find.text('복습을 완료했나요?'), findsOneWidget);
  });

  testWidgets('다이얼로그를 열면 이미지 미등록 안내 문구가 보인다', (tester) async {
    final foldersProvider = await _providerWithProblems([_problem(1)]);

    await pumpOnoWidget(
      tester,
      _buildTarget(foldersProvider: foldersProvider, currentId: 1),
    );

    await tester.tap(find.text('복습 인증'));
    await tester.pumpAndSettle();

    expect(find.text('풀이 이미지를 등록하세요'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate), findsOneWidget);
  });

  testWidgets('다이얼로그에서 취소를 누르면 닫힌다', (tester) async {
    final foldersProvider = await _providerWithProblems([_problem(1)]);

    await pumpOnoWidget(
      tester,
      _buildTarget(foldersProvider: foldersProvider, currentId: 1),
    );

    await tester.tap(find.text('복습 인증'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();

    expect(find.text('복습을 완료했나요?'), findsNothing);
  });

  testWidgets('이미지 선택 없이 복습 완료를 눌러도 아무 일도 일어나지 않는다', (tester) async {
    var refreshed = false;
    final foldersProvider = await _providerWithProblems([_problem(1)]);

    await pumpOnoWidget(
      tester,
      _buildTarget(
        foldersProvider: foldersProvider,
        currentId: 1,
        onRefresh: () => refreshed = true,
      ),
    );

    await tester.tap(find.text('복습 인증'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '복습 완료'));
    await tester.pumpAndSettle();

    // selectedImage 가 null 이면 onPressed 내부의 if(selectedImage != null)
    // 가드에 막혀 아무 처리도 하지 않는다 — 다이얼로그가 그대로 열려 있어야 한다.
    expect(find.text('복습을 완료했나요?'), findsOneWidget);
    expect(refreshed, isFalse);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    final foldersProvider = await _providerWithProblems([_problem(1)]);

    await pumpOnoWidget(
      tester,
      _buildTarget(foldersProvider: foldersProvider, currentId: 1),
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('복습 인증'), findsOneWidget);
  });

  testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
    final foldersProvider = await _providerWithProblems([_problem(1)]);

    await pumpOnoWidget(
      tester,
      _buildTarget(foldersProvider: foldersProvider, currentId: 1),
      surfaceSize: OnoSurface.smallPhone,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('빈 목록 상태에서 태블릿 폭으로 바꿔도 예외가 없다', (tester) async {
    final foldersProvider =
        FoldersProvider(problemsProvider: ProblemsProvider());

    await pumpOnoWidget(
      tester,
      _buildTarget(foldersProvider: foldersProvider, currentId: 1),
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
