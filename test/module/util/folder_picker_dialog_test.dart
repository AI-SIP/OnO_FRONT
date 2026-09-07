// FolderPickerDialog 위젯 테스트.
//
// 실제 사용처(FolderPickerWidget.showPicker, DirectoryScreen._showMoveFolderDialog)
// 와 동일하게 `showDialog<int>` 로 띄워서 결과값(pop 되는 폴더 id)까지 검증한다.
// 이를 위해 다이얼로그를 여는 버튼과 결과를 화면에 찍어 주는 `_PickerHost` 를 둔다.
//
// FoldersProvider 는 mock 서비스를 물린 진짜 Provider 로 만든다. 이 다이얼로그가
// `foldersProvider.folderService.getSubfoldersV2` 를 Provider 를 거치지 않고
// 직접 호출하기 때문에, 다이얼로그를 여는 모든 테스트는 루트 폴더의
// getSubfoldersV2 를 반드시 stub 해야 한다(안 하면 mocktail 이 MissingStubError 를
// 던진다).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Model/Folder/FolderRegisterModel.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';
import 'package:ono/Module/Util/FolderPickerDialog.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';

import '../../helpers/helpers.dart';

/// 실제 호출부(FolderPickerWidget.showPicker)와 같은 모양으로 다이얼로그를 연다.
/// `showDialog` 의 결과값을 화면에 텍스트로 찍어서, 테스트에서 pop 된 값을
/// `find.text` 로 확인할 수 있게 한다.
class _PickerHost extends StatefulWidget {
  final int? initialFolderId;
  final bool isManagementMode;

  const _PickerHost({this.initialFolderId, this.isManagementMode = false});

  @override
  State<_PickerHost> createState() => _PickerHostState();
}

class _PickerHostState extends State<_PickerHost> {
  int? _result;
  bool _closed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final picked = await showDialog<int>(
                  context: context,
                  builder: (_) => FolderPickerDialog(
                    initialFolderId: widget.initialFolderId,
                    isManagementMode: widget.isManagementMode,
                  ),
                );
                setState(() {
                  _result = picked;
                  _closed = true;
                });
              },
              child: const Text('다이얼로그 열기'),
            ),
            if (_closed) Text('결과: ${_result ?? "null"}'),
          ],
        ),
      ),
    );
  }
}

FolderModel _buildRootFolder(int id, {String name = '책장'}) {
  return FolderModel(
    folderId: id,
    folderName: name,
    problemIdList: const [],
    subFolderList: const [],
  );
}

FolderThumbnailModel _buildSubfolder(
  int id, {
  String name = '폴더',
  int problemCount = 0,
}) {
  return FolderThumbnailModel(
    folderId: id,
    folderName: name,
    problemCount: problemCount,
  );
}

void main() {
  setUpOnoWidgetTest();

  setUpAll(() {
    registerFallbackValue(
      FolderRegisterModel(folderName: 'fallback', parentFolderId: 0),
    );
  });

  late MockFolderService folderService;
  late ProblemsProvider problemsProvider;
  late FoldersProvider foldersProvider;

  setUp(() {
    folderService = MockFolderService();
    problemsProvider = ProblemsProvider();
    foldersProvider = FoldersProvider(
      problemsProvider: problemsProvider,
      folderService: folderService,
    );
  });

  /// [folderId] 의 하위 폴더 응답을 고정 stub 한다. 페이지네이션을 보고 싶으면
  /// 개별 테스트에서 `when` 을 다시 걸어 덮어쓴다.
  void stubSubfolders(
    int folderId, {
    List<FolderThumbnailModel> children = const [],
    bool hasNext = false,
    int? nextCursor,
  }) {
    when(() => folderService.getSubfoldersV2(
          folderId: folderId,
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => PaginatedResponse(
          content: children,
          nextCursor: hasNext ? (nextCursor ?? 999) : null,
          hasNext: hasNext,
          size: children.length,
        ));
  }

  /// 루트 폴더를 [id] 로 stub 하고, 그 하위 폴더도 함께 stub 한다.
  /// 다이얼로그를 여는 거의 모든 테스트가 필요로 하는 최소 설정이다.
  void stubRoot(
    int id, {
    String name = '책장',
    List<FolderThumbnailModel> children = const [],
    bool hasNext = false,
  }) {
    when(() => folderService.getRootFolder())
        .thenAnswer((_) async => _buildRootFolder(id, name: name));
    stubSubfolders(id, children: children, hasNext: hasNext);
  }

  /// 특정 폴더명 행을 감싸는 InkWell 을 찾는다. 토글 버튼과 이름 텍스트가
  /// 같은 InkWell 아래에 있어서, 이 Finder 하나로 "행 탭"과 "토글 버튼 찾기"
  /// 둘 다에 쓸 수 있다.
  Finder folderRow(String folderName) => find.ancestor(
        of: find.text(folderName),
        matching: find.byType(InkWell),
      );

  Finder toggleButtonOf(String folderName) => find.descendant(
        of: folderRow(folderName),
        matching: find.byType(IconButton),
      );

  Future<void> openDialog(
    WidgetTester tester, {
    int? initialFolderId,
    bool isManagementMode = false,
    Size surfaceSize = OnoSurface.phone,
  }) async {
    await pumpOnoWidget(
      tester,
      _PickerHost(
        initialFolderId: initialFolderId,
        isManagementMode: isManagementMode,
      ),
      foldersProvider: foldersProvider,
      problemsProvider: problemsProvider,
      surfaceSize: surfaceSize,
    );
    await tester.tap(find.text('다이얼로그 열기'));
    await tester.pumpAndSettle();
  }

  group('로딩 상태', () {
    testWidgets('루트 폴더를 불러오는 동안에는 스피너가 보이고 공책 추가 버튼이 비활성화된다', (tester) async {
      stubRoot(1);

      await pumpOnoWidget(
        tester,
        const _PickerHost(),
        foldersProvider: foldersProvider,
        problemsProvider: problemsProvider,
      );
      await tester.tap(find.text('다이얼로그 열기'));
      // 첫 프레임만 그린다. initState 가 시작한 비동기 로딩은 아직 끝나지 않는다.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final addButton = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) => widget is IconButton && widget.tooltip == '공책 추가',
        ),
      );
      expect(addButton.onPressed, isNull);
    });

    // TODO(#174): 실제 버그. lib/Module/Util/FolderPickerDialog.dart:98-104
    // _loadRootFolder() 가 실패하면 catch 블록은 _rootNode 를 만들지 못하고,
    // finally 블록은 _isLoading 만 false 로 되돌린다. build() 의 로딩 판정은
    // `_isLoading || _rootNode == null` 이라 _rootNode 가 계속 null 인 한 에러
    // 메시지 없이 로딩 스피너가 영구히 남는다. 사용자는 헤더의 닫기(X)나 취소
    // 버튼으로 다이얼로그를 닫는 것 외에는 복구할 방법이 없다.
    // 영향 화면: FolderPickerWidget(문제 등록/수정 시 공책 선택),
    // DirectoryScreen._showMoveFolderDialog(공책 정리).
    testWidgets(
      '루트 폴더 조회가 실패하면 로딩 스피너가 사라지고 에러가 보여야 한다',
      (tester) async {
        when(() => folderService.getRootFolder())
            .thenThrow(Exception('네트워크 오류'));
        stubSubfolders(1);

        await pumpOnoWidget(
          tester,
          const _PickerHost(),
          foldersProvider: foldersProvider,
          problemsProvider: problemsProvider,
        );
        await tester.tap(find.text('다이얼로그 열기'));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
      skip: true, // #174 에서 수정 예정
    );
  });

  group('폴더 트리 표시', () {
    testWidgets('하위 폴더가 있으면 책장과 함께 트리로 보인다', (tester) async {
      stubRoot(1, children: [
        _buildSubfolder(10, name: '수학'),
        _buildSubfolder(11, name: '영어'),
      ]);

      await openDialog(tester);

      expect(find.text('책장'), findsOneWidget);
      expect(find.text('수학'), findsOneWidget);
      expect(find.text('영어'), findsOneWidget);
    });

    testWidgets('하위 폴더가 없으면 책장만 보이고 더 보기 버튼도 없다', (tester) async {
      stubRoot(1, children: const []);

      await openDialog(tester);

      expect(find.text('책장'), findsOneWidget);
      expect(find.textContaining('더 보기'), findsNothing);
    });

    testWidgets('루트는 기본적으로 펼쳐진 채로 시작해서 체크 아이콘이 보인다', (tester) async {
      stubRoot(1, children: [_buildSubfolder(10, name: '수학')]);

      await openDialog(tester);

      expect(
        find.descendant(
          of: folderRow('책장'),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
    });
  });

  group('하위 폴더 펼치기/접기', () {
    testWidgets('접혀 있는 폴더를 펼치면 자식 폴더가 로드되어 보인다', (tester) async {
      stubRoot(2, children: [_buildSubfolder(20, name: '수학')]);
      stubSubfolders(20, children: [_buildSubfolder(21, name: '기하')]);

      await openDialog(tester);

      expect(find.text('기하'), findsNothing);

      await tester.tap(toggleButtonOf('수학'));
      await tester.pumpAndSettle();

      expect(find.text('기하'), findsOneWidget);
    });

    testWidgets('펼친 폴더를 다시 누르면 접혀서 자식 폴더가 사라진다', (tester) async {
      stubRoot(3, children: [_buildSubfolder(30, name: '수학')]);
      stubSubfolders(30, children: [_buildSubfolder(31, name: '기하')]);

      await openDialog(tester);
      await tester.tap(toggleButtonOf('수학'));
      await tester.pumpAndSettle();
      expect(find.text('기하'), findsOneWidget);

      await tester.tap(toggleButtonOf('수학'));
      await tester.pumpAndSettle();

      expect(find.text('기하'), findsNothing);
      // 접었을 뿐 목록 자체가 사라진 건 아니다.
      expect(find.text('수학'), findsOneWidget);
    });

    testWidgets('더 보기를 누르면 다음 페이지가 이어서 로드된다', (tester) async {
      when(() => folderService.getRootFolder())
          .thenAnswer((_) async => _buildRootFolder(4));
      when(() => folderService.getSubfoldersV2(
            folderId: 4,
            cursor: any(named: 'cursor'),
            size: any(named: 'size'),
          )).thenAnswer((invocation) async {
        final cursor = invocation.namedArguments[#cursor] as int?;
        if (cursor == null) {
          return PaginatedResponse(
            content: [_buildSubfolder(40, name: '수학')],
            nextCursor: 1,
            hasNext: true,
            size: 1,
          );
        }
        return PaginatedResponse(
          content: [_buildSubfolder(41, name: '과학')],
          nextCursor: null,
          hasNext: false,
          size: 1,
        );
      });

      await openDialog(tester);

      expect(find.text('수학'), findsOneWidget);
      expect(find.text('과학'), findsNothing);
      expect(find.textContaining('더 보기'), findsOneWidget);

      await tester.tap(find.textContaining('더 보기'));
      await tester.pumpAndSettle();

      expect(find.text('과학'), findsOneWidget);
      expect(find.textContaining('더 보기'), findsNothing);
    });
  });

  group('폴더 선택', () {
    testWidgets('폴더 행을 탭하면 선택 표시가 그 폴더로 옮겨간다', (tester) async {
      stubRoot(5, children: [_buildSubfolder(50, name: '수학')]);

      await openDialog(tester);
      await tester.tap(folderRow('수학'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
            of: folderRow('책장'), matching: find.byIcon(Icons.check_circle)),
        findsNothing,
      );
      expect(
        find.descendant(
            of: folderRow('수학'), matching: find.byIcon(Icons.check_circle)),
        findsOneWidget,
      );
    });

    testWidgets('선택하기를 누르면 선택한 폴더 id로 다이얼로그가 닫힌다', (tester) async {
      stubRoot(6, children: [_buildSubfolder(60, name: '수학')]);

      await openDialog(tester);
      await tester.tap(folderRow('수학'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('선택하기'));
      await tester.pumpAndSettle();

      expect(find.text('결과: 60'), findsOneWidget);
    });

    testWidgets('취소를 누르면 선택을 바꿨어도 처음 폴더 id로 닫힌다', (tester) async {
      stubRoot(7, children: [_buildSubfolder(70, name: '수학')]);

      await openDialog(tester, initialFolderId: 7);
      await tester.tap(folderRow('수학'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.text('결과: 7'), findsOneWidget);
    });

    testWidgets('닫기(X) 아이콘을 눌러도 처음 폴더 id로 닫힌다', (tester) async {
      stubRoot(8, children: [_buildSubfolder(80, name: '수학')]);

      await openDialog(tester, initialFolderId: 8);
      await tester.tap(folderRow('수학'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();

      expect(find.text('결과: 8'), findsOneWidget);
    });
  });

  group('모드별 문구', () {
    testWidgets('기본 모드에서는 공책 선택 / 선택하기 문구가 보인다', (tester) async {
      stubRoot(9);

      await openDialog(tester);

      expect(find.text('공책 선택'), findsOneWidget);
      expect(find.text('선택하기'), findsOneWidget);
      expect(find.text('완료하기'), findsNothing);
    });

    testWidgets('관리 모드에서는 공책 정리 / 완료하기 문구가 보인다', (tester) async {
      stubRoot(12);

      await openDialog(tester, isManagementMode: true);

      expect(find.text('공책 정리'), findsOneWidget);
      expect(find.text('완료하기'), findsOneWidget);
      expect(find.text('선택하기'), findsNothing);
    });
  });

  group('공책 생성', () {
    testWidgets('공책 추가 버튼을 누르면 이름 입력 다이얼로그가 뜬다', (tester) async {
      stubRoot(13);

      await openDialog(tester);
      await tester.tap(find.byTooltip('공책 추가'));
      await tester.pumpAndSettle();

      expect(find.text('공책 생성'), findsOneWidget);
      expect(find.textContaining('책장 아래에 만들어요'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('이름을 입력하고 확인하면 registerFolder 가 호출된다', (tester) async {
      stubRoot(14);
      when(() => folderService.registerFolder(any()))
          .thenAnswer((_) async => 140);
      when(() => folderService.fetchFolder(140,
              showErrorSnackBar: any(named: 'showErrorSnackBar')))
          .thenAnswer((_) async => _buildRootFolder(140, name: '영어'));

      await openDialog(tester);
      await tester.tap(find.byTooltip('공책 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '영어');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      verify(() => folderService.registerFolder(any())).called(1);
      // 생성 다이얼로그는 닫히고 폴더 선택 다이얼로그로 돌아온다.
      expect(find.text('공책 생성'), findsNothing);
    });

    testWidgets('이름을 비운 채 확인을 눌러도 registerFolder 가 호출되지 않는다', (tester) async {
      stubRoot(15);

      await openDialog(tester);
      await tester.tap(find.byTooltip('공책 추가'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      verifyNever(() => folderService.registerFolder(any()));
      // 빈 값이면 다이얼로그가 닫히지 않는다.
      expect(find.text('공책 생성'), findsOneWidget);
    });
  });

  group('반응형', () {
    testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
      stubRoot(16, children: [_buildSubfolder(160, name: '수학')]);

      await openDialog(tester, surfaceSize: OnoSurface.tablet);

      expect(tester.takeException(), isNull);
      expect(find.byType(FolderPickerDialog), findsOneWidget);
    });

    testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
      stubRoot(17, children: [_buildSubfolder(170, name: '수학')]);

      await openDialog(tester, surfaceSize: OnoSurface.smallPhone);

      expect(tester.takeException(), isNull);
    });
  });
}
