// SharedProblemCommentsSection 위젯 테스트.
//
// 이 영역의 핵심은 권한별 조건부 표시다: 내가 쓴 댓글에는 수정·삭제가 모두
// 보이고, 남이 쓴 댓글은 canDelete(방장 권한 등)가 아니면 더보기 버튼 자체가
// 없어야 한다. 실제 StudyRoomProvider 에 MockStudyRoomService 를 물려 쓴다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/StudyRoom/SharedProblemCommentModel.dart';
import 'package:ono/Model/StudyRoom/StudyRoomModel.dart';
import 'package:ono/Module/Theme/ThemeHandler.dart';
import 'package:ono/Provider/StudyRoomProvider.dart';
import 'package:ono/Screen/StudyRoom/Widget/SharedProblemCommentsSection.dart';
import 'package:ono/Service/Api/StudyRoom/StudyRoomService.dart';

import '../../helpers/helpers.dart';

SharedProblemCommentModel _comment({
  required int id,
  required String author,
  required bool isMine,
  required bool canDelete,
  String content = '댓글 내용',
}) {
  return SharedProblemCommentModel(
    commentId: id,
    content: content,
    authorId: isMine ? 1 : 2,
    authorName: author,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    isEdited: false,
    isMine: isMine,
    canDelete: canDelete,
    reactions: const [],
  );
}

void main() {
  setUpOnoWidgetTest();

  late MockStudyRoomService service;
  late StudyRoomProvider provider;

  setUp(() {
    service = MockStudyRoomService();
    provider = StudyRoomProvider(studyRoomService: service)
      // fetchSharedProblemComments 는 selectedRoom(또는 activeRoomId)이 있어야
      // roomId 를 알 수 있다.
      ..selectedRoom = const StudyRoomModel(
        roomId: 1,
        name: '스터디룸',
        hostUserId: 1,
        members: [],
      );
  });

  void stubComments(List<SharedProblemCommentModel> comments) {
    when(() => service.fetchSharedProblemComments(
          roomId: 1,
          sharedProblemId: 10,
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) async => CursorPage(
          content: comments,
          nextCursor: null,
          hasNext: false,
        ));
  }

  Future<void> pumpSection(
    WidgetTester tester, {
    bool initiallyExpanded = true,
    int? initialCommentCount,
  }) async {
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: SharedProblemCommentsSection(
          sharedProblemId: 10,
          initialCommentCount: initialCommentCount,
          themeProvider: ThemeHandler(),
          initiallyExpanded: initiallyExpanded,
        ),
      ),
      studyRoomProvider: provider,
    );
  }

  testWidgets('펼쳐진 상태로 로딩 중이면 스피너가 뜬다', (tester) async {
    final completer = Completer<CursorPage<SharedProblemCommentModel>>();
    when(() => service.fetchSharedProblemComments(
          roomId: 1,
          sharedProblemId: 10,
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenAnswer((_) => completer.future);

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: SharedProblemCommentsSection(
          sharedProblemId: 10,
          initialCommentCount: null,
          themeProvider: ThemeHandler(),
          initiallyExpanded: true,
        ),
      ),
      studyRoomProvider: provider,
      settle: false,
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const CursorPage(content: [], nextCursor: null, hasNext: false),
    );
    await tester.pump();
  });

  testWidgets('로드에 실패하면 안내와 다시 시도 버튼이 뜬다', (tester) async {
    when(() => service.fetchSharedProblemComments(
          roomId: 1,
          sharedProblemId: 10,
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        )).thenThrow(Exception('network'));

    await pumpSection(tester);

    expect(find.text('풀이 의견을 불러오지 못했어요'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('댓글이 없으면 안내 문구가 뜬다', (tester) async {
    stubComments([]);

    await pumpSection(tester);

    expect(find.text('아직 풀이 의견이 없어요'), findsOneWidget);
  });

  testWidgets('댓글이 있으면 작성자와 내용이 보인다', (tester) async {
    stubComments([
      _comment(
          id: 1,
          author: '기승민',
          isMine: true,
          canDelete: true,
          content: '이렇게 풀었어요'),
    ]);

    await pumpSection(tester);

    expect(find.text('기승민'), findsOneWidget);
    expect(find.text('이렇게 풀었어요'), findsOneWidget);
  });

  group('권한별 조건부 표시', () {
    testWidgets('내가 쓴 댓글은 더보기 메뉴에 수정·삭제가 모두 보인다', (tester) async {
      stubComments([
        _comment(id: 1, author: '나', isMine: true, canDelete: true),
      ]);

      await pumpSection(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('수정'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('남이 쓴 댓글이고 삭제 권한도 없으면 더보기 버튼 자체가 없다', (tester) async {
      stubComments([
        _comment(id: 1, author: '다른 사람', isMine: false, canDelete: false),
      ]);

      await pumpSection(tester);

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('남이 쓴 댓글이라도 방장이라 삭제 권한이 있으면 삭제만 보이고 수정은 없다', (tester) async {
      stubComments([
        _comment(id: 1, author: '다른 사람', isMine: false, canDelete: true),
      ]);

      await pumpSection(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('삭제'), findsOneWidget);
      expect(find.text('수정'), findsNothing);
    });

    testWidgets('내 댓글 삭제를 확정하면 deleteSharedProblemComment 가 호출된다',
        (tester) async {
      stubComments([
        _comment(id: 1, author: '나', isMine: true, canDelete: true),
      ]);
      when(() => service.deleteSharedProblemComment(
            roomId: 1,
            sharedProblemId: 10,
            commentId: 1,
          )).thenAnswer((_) async {});

      await pumpSection(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제').last);
      await tester.pumpAndSettle();

      verify(() => service.deleteSharedProblemComment(
            roomId: 1,
            sharedProblemId: 10,
            commentId: 1,
          )).called(1);
    });
  });

  group('댓글 입력 검증', () {
    testWidgets('빈 값으로 전송하면 아무 일도 일어나지 않는다', (tester) async {
      stubComments([]);
      await pumpSection(tester);

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      verifyNever(() => service.createSharedProblemComment(
            roomId: any(named: 'roomId'),
            sharedProblemId: any(named: 'sharedProblemId'),
            content: any(named: 'content'),
          ));
    });

    testWidgets('공백만 입력하고 전송하면 아무 일도 일어나지 않는다', (tester) async {
      stubComments([]);
      await pumpSection(tester);

      await tester.enterText(find.byType(TextField).last, '   ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      verifyNever(() => service.createSharedProblemComment(
            roomId: any(named: 'roomId'),
            sharedProblemId: any(named: 'sharedProblemId'),
            content: any(named: 'content'),
          ));
    });

    testWidgets('입력창은 300자로 길이가 제한된다', (tester) async {
      stubComments([]);
      await pumpSection(tester);

      await tester.enterText(find.byType(TextField).last, 'x' * 350);
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.controller!.text.length, lessThanOrEqualTo(300));
    });

    testWidgets('유효한 값을 입력하고 전송하면 createSharedProblemComment 가 호출된다',
        (tester) async {
      stubComments([]);
      when(() => service.createSharedProblemComment(
            roomId: 1,
            sharedProblemId: 10,
            content: '좋은 풀이네요',
          )).thenAnswer(
        (_) async =>
            _comment(id: 2, author: '나', isMine: true, canDelete: true),
      );

      await pumpSection(tester);
      await tester.enterText(find.byType(TextField).last, '좋은 풀이네요');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      verify(() => service.createSharedProblemComment(
            roomId: 1,
            sharedProblemId: 10,
            content: '좋은 풀이네요',
          )).called(1);
    });
  });

  testWidgets('접혀 있으면 로드하지 않고, 토글하면 펼쳐지며 댓글을 불러온다', (tester) async {
    stubComments([
      _comment(id: 1, author: '나', isMine: true, canDelete: true),
    ]);

    await pumpSection(tester, initiallyExpanded: false, initialCommentCount: 1);

    expect(find.text('댓글 내용'), findsNothing);
    verifyNever(() => service.fetchSharedProblemComments(
          roomId: any(named: 'roomId'),
          sharedProblemId: any(named: 'sharedProblemId'),
          cursor: any(named: 'cursor'),
          size: any(named: 'size'),
        ));

    await tester.tap(find.text('풀이 의견'));
    await tester.pumpAndSettle();

    expect(find.text('댓글 내용'), findsOneWidget);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    stubComments([
      _comment(id: 1, author: '나', isMine: true, canDelete: true),
    ]);

    await pumpOnoWidget(
      tester,
      Scaffold(
        body: SharedProblemCommentsSection(
          sharedProblemId: 10,
          initialCommentCount: null,
          themeProvider: ThemeHandler(),
          initiallyExpanded: true,
        ),
      ),
      studyRoomProvider: provider,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
