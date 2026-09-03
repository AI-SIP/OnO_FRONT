import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeCompletionScreen.dart';

import '../../helpers/helpers.dart';

PracticeNoteDetailModel _practice(int id, {int practiceCount = 0}) {
  return PracticeNoteDetailModel(
    practiceId: id,
    practiceTitle: 'practice-$id',
    practiceCount: practiceCount,
    createdAt: DateTime(2024, 1, 1),
    lastSolvedAt: null,
    problemIdList: const [],
  );
}

void main() {
  setUpOnoWidgetTest();

  late MockPracticeNoteService practiceNoteService;
  late ProblemPracticeProvider practiceProvider;

  setUp(() {
    practiceNoteService = MockPracticeNoteService();
    practiceProvider = ProblemPracticeProvider(
      problemsProvider: MockProblemsProvider(),
      practiceNoteService: practiceNoteService,
    );
    // addPracticeCount 성공 시 내부에서 fetchPracticeCount -> fetchPracticeNote 로
    // 다시 조회한다. 기본 응답을 깔아 둔다.
    when(() =>
            practiceNoteService.getPracticeNoteById(1, showErrorSnackBar: true))
        .thenAnswer((_) async => _practice(1));
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size surfaceSize = OnoSurface.phone,
  }) {
    return pumpOnoWidget(
      tester,
      const PracticeCompletionScreen(
        practiceId: 1,
        totalProblems: 5,
        practiceRound: 2,
      ),
      practiceProvider: practiceProvider,
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('완료 화면에 회차와 문제 수가 보인다', (tester) async {
    await pumpScreen(tester);

    expect(find.text('복습 완료'), findsOneWidget);
    expect(find.text('2회차 복습을 완료했어요'), findsOneWidget);
    expect(find.text('총 5문제를 풀었어요.'), findsOneWidget);
  });

  testWidgets('추천 기분 이모지 목록과 더보기 버튼이 보인다', (tester) async {
    // 더보기 버튼은 가로 스크롤 목록의 끝에 있어 phone 폭에서는 뷰포트 밖이라
    // 지연 빌드되지 않는다. 태블릿 폭에서는 전부 한 화면에 들어와 스크롤이
    // 필요 없다.
    await pumpScreen(tester, surfaceSize: OnoSurface.tablet);

    expect(find.text('이번 복습 어땠나요?'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
  });

  testWidgets('기분 이모지를 탭해도 예외 없이 선택·해제된다', (tester) async {
    await pumpScreen(tester);

    final moodInkWell = find.byType(InkWell).first;
    await tester.tap(moodInkWell);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 같은 이모지를 다시 탭하면 선택이 풀린다 (토글).
    await tester.tap(moodInkWell);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('더보기 버튼을 탭하면 이모지 선택 바텀시트가 뜬다', (tester) async {
    await pumpScreen(tester, surfaceSize: OnoSurface.tablet);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('확인 버튼을 탭하면 addPracticeCount 를 호출하고 완료 스낵바를 띄운다', (tester) async {
    when(() => practiceNoteService.addPracticeNoteCount(1, moodEmojiKey: null))
        .thenAnswer((_) async {});

    await pumpScreen(tester);
    await tester.tap(find.text('확인'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(() =>
            practiceNoteService.addPracticeNoteCount(1, moodEmojiKey: null))
        .called(1);
    expect(find.text('복습을 완료했습니다!'), findsOneWidget);
  });

  testWidgets('기분을 고르고 확인을 누르면 선택한 moodEmojiKey 로 저장한다', (tester) async {
    when(() => practiceNoteService.addPracticeNoteCount(1,
        moodEmojiKey: any(named: 'moodEmojiKey'))).thenAnswer((_) async {});

    await pumpScreen(tester);
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => practiceNoteService.addPracticeNoteCount(1,
        moodEmojiKey: 'success_checkmark')).called(1);
  });

  testWidgets('저장에 실패하면 에러 스낵바를 띄우고 화면을 유지한다', (tester) async {
    when(() => practiceNoteService.addPracticeNoteCount(1, moodEmojiKey: null))
        .thenThrow(Exception('network error'));

    await pumpScreen(tester);
    await tester.tap(find.text('확인'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('복습 완료를 저장하지 못했어요.'), findsOneWidget);
    expect(find.byType(PracticeCompletionScreen), findsOneWidget);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpScreen(tester, surfaceSize: OnoSurface.tablet);

    expect(tester.takeException(), isNull);
    expect(find.byType(PracticeCompletionScreen), findsOneWidget);
  });

  testWidgets('작은 폰 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpScreen(tester, surfaceSize: OnoSurface.smallPhone);

    expect(tester.takeException(), isNull);
  });
}
