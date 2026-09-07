// FolderPickerWidget 위젯 테스트.
//
// FolderPickerWidget 자체는 "선택된 폴더 이름을 보여주는 한 줄짜리 요약 행"이다.
// 실제 폴더 트리 표시·하위 폴더 펼치기·선택 UI는 탭했을 때 뜨는
// FolderPickerDialog(lib/Module/Util/FolderPickerDialog.dart) 가 담당한다.
// 이 파일은 FolderPickerWidget 이 진입점 역할을 하는 만큼, 요약 행 자체의
// 상태별 표시와 함께 "탭 → 다이얼로그 → 콜백" 흐름까지 확인한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/Common/PaginatedResponse.dart';
import 'package:ono/Model/Folder/FolderModel.dart';
import 'package:ono/Model/Folder/FolderThumbnailModel.dart';
import 'package:ono/Module/Util/FolderPickerWidget.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:ono/Provider/ProblemsProvider.dart';

import '../../helpers/helpers.dart';

FolderModel _folder(int id, {String? name}) => FolderModel(
      folderId: id,
      folderName: name ?? 'folder-$id',
      problemIdList: const [],
      subFolderList: const [],
    );

FolderThumbnailModel _thumb(int id, String name) =>
    FolderThumbnailModel(folderId: id, folderName: name);

/// 루트(1) - 수학(2) - 미적분(3) 트리를 흉내 내는 FolderService mock.
/// 루트를 펼치면 수학이, 수학을 펼치면 미적분이 로드된다.
MockFolderService _treeFolderService() {
  final service = MockFolderService();
  when(() => service.getRootFolder()).thenAnswer((_) async => _folder(1));
  when(() => service.getSubfoldersV2(folderId: 1, cursor: null, size: 20))
      .thenAnswer((_) async => PaginatedResponse(
            content: [_thumb(2, '수학')],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
  when(() => service.getSubfoldersV2(folderId: 2, cursor: null, size: 20))
      .thenAnswer((_) async => PaginatedResponse(
            content: [_thumb(3, '미적분')],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
  when(() => service.getSubfoldersV2(folderId: 3, cursor: null, size: 20))
      .thenAnswer((_) async => PaginatedResponse(
            content: const [],
            nextCursor: null,
            hasNext: false,
            size: 20,
          ));
  return service;
}

void main() {
  setUpOnoWidgetTest();

  group('선택된 폴더 이름 표시', () {
    testWidgets('폴더 데이터가 아직 없으면 로딩 스피너와 안내 문구만 보인다', (tester) async {
      final foldersProvider =
          FoldersProvider(problemsProvider: ProblemsProvider());

      // 로딩 스피너(CircularProgressIndicator)는 끝나지 않는 애니메이션이라
      // pumpAndSettle 이 타임아웃난다. settle: false 로 띄우고 직접 pump 한다.
      await pumpOnoWidget(
        tester,
        FolderPickerWidget(onPicked: (_) {}),
        foldersProvider: foldersProvider,
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('공책 선택'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selectedId 가 null 이면 책장으로 표시된다', (tester) async {
      final folderService = MockFolderService();
      when(() => folderService.getRootFolder())
          .thenAnswer((_) async => _folder(1));
      final foldersProvider = FoldersProvider(
        problemsProvider: ProblemsProvider(),
        folderService: folderService,
      );
      await foldersProvider.fetchRootFolder();

      await pumpOnoWidget(
        tester,
        FolderPickerWidget(onPicked: (_) {}),
        foldersProvider: foldersProvider,
      );

      expect(find.text('책장'), findsOneWidget);
    });

    testWidgets('selectedId 가 루트 폴더 id 와 같으면 책장으로 표시된다', (tester) async {
      final folderService = MockFolderService();
      when(() => folderService.getRootFolder())
          .thenAnswer((_) async => _folder(1));
      final foldersProvider = FoldersProvider(
        problemsProvider: ProblemsProvider(),
        folderService: folderService,
      );
      await foldersProvider.fetchRootFolder();

      await pumpOnoWidget(
        tester,
        FolderPickerWidget(selectedId: 1, onPicked: (_) {}),
        foldersProvider: foldersProvider,
      );

      expect(find.text('책장'), findsOneWidget);
    });

    testWidgets('selectedId 가 현재 폴더(currentFolder) 와 같으면 그 폴더 이름이 보인다',
        (tester) async {
      // currentFolder 가 root 와 같은 폴더면 rootFolderId 체크가 먼저 걸려
      // "책장"을 반환해버리므로, root(1) 과는 다른 폴더(5)로 이동해 둔다.
      final folderService = MockFolderService();
      when(() => folderService.getRootFolder())
          .thenAnswer((_) async => _folder(1));
      when(() => folderService.fetchFolder(5, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(5, name: '수학'));
      final foldersProvider = FoldersProvider(
        problemsProvider: ProblemsProvider(),
        folderService: folderService,
      );
      await foldersProvider.fetchRootFolder();
      // 캐시를 미리 채워 두면 moveToFolder 가 네트워크 없이 캐시를 그대로 쓴다.
      foldersProvider.saveProblemsToCache(5, const [], null, false);
      await foldersProvider.moveToFolder(5);

      await pumpOnoWidget(
        tester,
        FolderPickerWidget(selectedId: 5, onPicked: (_) {}),
        foldersProvider: foldersProvider,
      );

      expect(find.text('수학'), findsOneWidget);
    });

    testWidgets('selectedId 가 folders 목록에 있는 다른 폴더면 그 폴더 이름이 보인다',
        (tester) async {
      final folderService = MockFolderService();
      when(() => folderService.getRootFolder())
          .thenAnswer((_) async => _folder(1));
      when(() => folderService.fetchFolder(2, showErrorSnackBar: true))
          .thenAnswer((_) async => _folder(2, name: '수학'));
      final foldersProvider = FoldersProvider(
        problemsProvider: ProblemsProvider(),
        folderService: folderService,
      );
      await foldersProvider.fetchRootFolder();
      await foldersProvider
          .getFolder(2); // folders 목록에 추가되지만 currentFolder 는 아님

      await pumpOnoWidget(
        tester,
        FolderPickerWidget(selectedId: 2, onPicked: (_) {}),
        foldersProvider: foldersProvider,
      );

      expect(find.text('수학'), findsOneWidget);
    });

    testWidgets('selectedId 가 어디에도 없으면 책장으로 폴백한다', (tester) async {
      final folderService = MockFolderService();
      when(() => folderService.getRootFolder())
          .thenAnswer((_) async => _folder(1));
      final foldersProvider = FoldersProvider(
        problemsProvider: ProblemsProvider(),
        folderService: folderService,
      );
      await foldersProvider.fetchRootFolder();

      await pumpOnoWidget(
        tester,
        // 이 테스트 파일의 다른 어떤 케이스에서도 쓰지 않는 id 로, 다이얼로그를
        // 연 적이 없어 FolderPickerDialog 의 static 이름 캐시에도 없다.
        FolderPickerWidget(selectedId: 987654, onPicked: (_) {}),
        foldersProvider: foldersProvider,
      );

      expect(find.text('책장'), findsOneWidget);
    });
  });

  group('반응형', () {
    testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
      final folderService = MockFolderService();
      when(() => folderService.getRootFolder())
          .thenAnswer((_) async => _folder(1));
      final foldersProvider = FoldersProvider(
        problemsProvider: ProblemsProvider(),
        folderService: folderService,
      );
      await foldersProvider.fetchRootFolder();

      await pumpOnoWidget(
        tester,
        FolderPickerWidget(onPicked: (_) {}),
        foldersProvider: foldersProvider,
        surfaceSize: OnoSurface.tablet,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FolderPickerWidget), findsOneWidget);
    });

    testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
      final folderService = MockFolderService();
      when(() => folderService.getRootFolder())
          .thenAnswer((_) async => _folder(1));
      final foldersProvider = FoldersProvider(
        problemsProvider: ProblemsProvider(),
        folderService: folderService,
      );
      await foldersProvider.fetchRootFolder();

      await pumpOnoWidget(
        tester,
        FolderPickerWidget(onPicked: (_) {}),
        foldersProvider: foldersProvider,
        surfaceSize: OnoSurface.smallPhone,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('탭 → 폴더 선택 다이얼로그', () {
    testWidgets('선택 영역을 탭하면 폴더 선택 다이얼로그가 뜨고 트리가 보인다', (tester) async {
      final folderService = _treeFolderService();
      final foldersProvider = FoldersProvider(
        problemsProvider: ProblemsProvider(),
        folderService: folderService,
      );
      await foldersProvider.fetchRootFolder();

      await pumpOnoWidget(
        tester,
        FolderPickerWidget(onPicked: (_) {}),
        foldersProvider: foldersProvider,
      );

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      expect(find.text('오답노트를 넣을 공책을 골라주세요'), findsOneWidget);
      expect(find.text('책장'), findsWidgets); // 헤더가 아닌 트리의 루트 노드
      expect(find.text('수학'), findsOneWidget);
    });

    testWidgets('하위 폴더를 펼치면 그 안의 폴더가 보인다', (tester) async {
      final folderService = _treeFolderService();
      final foldersProvider = FoldersProvider(
        problemsProvider: ProblemsProvider(),
        folderService: folderService,
      );
      await foldersProvider.fetchRootFolder();

      await pumpOnoWidget(
        tester,
        FolderPickerWidget(onPicked: (_) {}),
        foldersProvider: foldersProvider,
      );

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      expect(find.text('미적분'), findsNothing);

      // 수학 노드는 아직 펼쳐지지 않아 keyboard_arrow_right 아이콘이 하나뿐이다
      // (루트는 이미 펼쳐져 있어 keyboard_arrow_down 을 쓴다).
      await tester
          .tap(find.widgetWithIcon(IconButton, Icons.keyboard_arrow_right));
      await tester.pumpAndSettle();

      expect(find.text('미적분'), findsOneWidget);
    });

    testWidgets('폴더를 선택하고 선택하기를 누르면 onPicked 가 새 폴더 id 로 불린다', (tester) async {
      final folderService = _treeFolderService();
      final foldersProvider = FoldersProvider(
        problemsProvider: ProblemsProvider(),
        folderService: folderService,
      );
      await foldersProvider.fetchRootFolder();

      int? picked;
      await pumpOnoWidget(
        tester,
        FolderPickerWidget(onPicked: (id) => picked = id),
        foldersProvider: foldersProvider,
      );

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      await tester.tap(find.text('수학'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '선택하기'));
      await tester.pumpAndSettle();

      expect(picked, 2);
      expect(find.text('오답노트를 넣을 공책을 골라주세요'), findsNothing);
    });

    testWidgets('다이얼로그에서 취소를 누르면 onPicked 가 기존 selectedId 로 불린다',
        (tester) async {
      final folderService = _treeFolderService();
      final foldersProvider = FoldersProvider(
        problemsProvider: ProblemsProvider(),
        folderService: folderService,
      );
      await foldersProvider.fetchRootFolder();

      int? picked = -1; // null 로 불렸는지 구분하기 위해 -1 로 초기화
      await pumpOnoWidget(
        tester,
        FolderPickerWidget(onPicked: (id) => picked = id),
        foldersProvider: foldersProvider,
      );

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '취소'));
      await tester.pumpAndSettle();

      // selectedId 를 넘기지 않았으므로(null) 취소해도 null 이 그대로 돌아온다.
      expect(picked, isNull);
    });
  });
}
