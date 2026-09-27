// 오답노트 상세 → "복습 세트에 추가하기" 흐름 테스트.
//
// 서버는 PATCH /api/practiceNotes 요청 body 에 practiceNotification 키가 없으면
// 그 세트의 복습 알림을 지운다. 문제만 담는 요청이라도 세트가 이미 가진 알림
// 설정을 그대로 실어 보내야 알림이 살아남는다 (#255).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNotificationModel.dart';
import 'package:ono/Model/PracticeNote/RepeatType.dart';
import 'package:ono/Model/Problem/ProblemModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/ProblemDetail/ProblemDetailScreen.dart';

import '../../helpers/helpers.dart';
import 'problem_detail_fixtures.dart';

PracticeNoteDetailModel _practice(
  int id, {
  PracticeNotificationModel? notification,
  List<int> problemIds = const [],
}) {
  return PracticeNoteDetailModel(
    practiceId: id,
    practiceTitle: '복습 세트 $id',
    practiceCount: 0,
    createdAt: DateTime(2026, 1, 1),
    lastSolvedAt: null,
    practiceNotificationModel: notification,
    problemIdList: [...problemIds],
  );
}

void main() {
  setUpOnoWidgetTest();

  late MockProblemsProvider problemsProvider;
  late MockPracticeNoteService practiceNoteService;
  late ProblemPracticeProvider practiceProvider;
  late ProblemModel problem;

  setUpAll(() {
    registerFallbackValue(
      PracticeNoteUpdateModel(
        practiceNoteId: 0,
        addProblemIdList: const [],
        removeProblemIdList: const [],
      ),
    );
  });

  setUp(() {
    problem = buildProblem(problemId: 11, reference: '이차방정식 1번');
    problemsProvider = MockProblemsProvider();
    when(() => problemsProvider.problems).thenReturn([problem]);
    when(() => problemsProvider.getProblem(11))
        .thenAnswer((_) async => problem);

    practiceNoteService = MockPracticeNoteService();
    when(() => practiceNoteService.updatePracticeNote(any(),
        showErrorSnackBar: any(named: 'showErrorSnackBar'))).thenAnswer(
      (_) async {},
    );

    practiceProvider = ProblemPracticeProvider(
      problemsProvider: problemsProvider,
      practiceNoteService: practiceNoteService,
    );
  });

  /// 상세 화면을 띄우고 "복습 세트에 추가하기" 시트에서 [practiceTitle] 을 골라
  /// 추가까지 누른다.
  Future<void> addProblemToPractice(
    WidgetTester tester,
    String practiceTitle,
  ) async {
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const ProblemDetailScreen(problemId: 11),
        problemsProvider: problemsProvider,
        practiceProvider: practiceProvider,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('복습 세트에 추가하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(practiceTitle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('추가'));
      await tester.pumpAndSettle();
    });
  }

  Map<String, dynamic> capturedRequestBody() {
    final captured = verify(() => practiceNoteService.updatePracticeNote(
          captureAny(),
          showErrorSnackBar: any(named: 'showErrorSnackBar'),
        )).captured;

    expect(captured, hasLength(1));
    return (captured.single as PracticeNoteUpdateModel).toJson();
  }

  testWidgets('알림이 설정된 세트에 문제를 담으면 요청 body 에 practiceNotification 이 그대로 실린다',
      (tester) async {
    final notification = PracticeNotificationModel(
      intervalDays: 3,
      hour: 21,
      minute: 30,
      repeatType: RepeatType.weekly,
      weekDays: const [1, 5],
    );
    when(() => practiceNoteService.getAllPracticeNoteDetails())
        .thenAnswer((_) async => [_practice(5, notification: notification)]);

    await addProblemToPractice(tester, '복습 세트 5');

    final body = capturedRequestBody();

    expect(body['practiceNoteId'], 5);
    expect(body['addProblemIdList'], [11]);
    expect(
      body['practiceNotification'],
      {
        'intervalDays': 3,
        'hour': 21,
        'minute': 30,
        'repeatType': 'weekly',
        'weekDays': [1, 5],
      },
    );
  });

  testWidgets('알림이 없는 세트에 담을 때는 practiceNotification 키를 넣지 않는다',
      (tester) async {
    when(() => practiceNoteService.getAllPracticeNoteDetails())
        .thenAnswer((_) async => [_practice(5)]);

    await addProblemToPractice(tester, '복습 세트 5');

    final body = capturedRequestBody();

    expect(body['practiceNoteId'], 5);
    expect(body.containsKey('practiceNotification'), isFalse);
  });
}
