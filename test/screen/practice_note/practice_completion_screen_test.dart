import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Module/Emoji/OnoEmojiImage.dart';
import 'package:ono/Module/Motion/PressableScale.dart';
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

    final moodButton = find.byType(PressableScale).first;
    await tester.tap(moodButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 같은 이모지를 다시 탭하면 선택이 풀린다 (토글).
    await tester.tap(moodButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('더보기 버튼을 탭하면 이모지 선택 바텀시트가 뜬다', (tester) async {
    await pumpScreen(tester, surfaceSize: OnoSurface.tablet);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('더보기에서 추천에 없는 것을 고르면 목록 맨 앞에 보인다', (tester) async {
    // 폰에서는 더보기 칸이 화면 밖이라, 그 칸에만 골라 둔 모양을 그리면
    // 돌아왔을 때 무엇을 골랐는지 보이지 않았다.
    await pumpScreen(tester);
    await tester.dragUntilVisible(
      find.byIcon(Icons.more_horiz),
      find.byType(ListView).first,
      const Offset(-200, 0),
    );
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('슬픔'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    final picked = find.byWidgetPredicate(
      (w) => w is OnoEmojiImage && w.emoji?.key == 'crying_in_rain',
    );
    expect(picked.hitTestable(), findsWidgets);
    // 제목 줄 오른쪽에도 고른 기분이 그림으로 뜬다. 이름 글자는 적지 않는다.
    expect(picked.hitTestable(), findsNWidgets(2));
    expect(find.text('슬픔'), findsNothing);
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

  // 완료 요청은 보낼 때마다 복습 횟수를 하나씩 올린다. 버튼이 잠기는 것은 화면을
  // 다시 그린 뒤라, 같은 프레임에 두 번 눌려도 한 번만 나가야 한다.
  testWidgets('확인 버튼을 연달아 두 번 눌러도 한 번만 저장한다', (tester) async {
    when(() => practiceNoteService.addPracticeNoteCount(1, moodEmojiKey: null))
        .thenAnswer((_) async {});

    await pumpScreen(tester);
    await tester.tap(find.text('확인'));
    await tester.tap(find.text('확인'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(() =>
            practiceNoteService.addPracticeNoteCount(1, moodEmojiKey: null))
        .called(1);
  });

  testWidgets('기분을 고르고 확인을 누르면 선택한 moodEmojiKey 로 저장한다', (tester) async {
    when(() => practiceNoteService.addPracticeNoteCount(1,
        moodEmojiKey: any(named: 'moodEmojiKey'))).thenAnswer((_) async {});

    await pumpScreen(tester);
    await tester.tap(find.byType(PressableScale).first);
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

  testWidgets('저장을 기다리는 동안 확인을 또 눌러도 한 번만 보낸다', (tester) async {
    final completer = Completer<void>();
    when(() => practiceNoteService.addPracticeNoteCount(1, moodEmojiKey: null))
        .thenAnswer((_) => completer.future);

    await pumpScreen(tester);
    await tester.tap(find.text('확인'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
    await tester.pump();

    verify(() =>
            practiceNoteService.addPracticeNoteCount(1, moodEmojiKey: null))
        .called(1);

    // 성공으로 끝내면 완료 알림이 뜨는데, AppToast 는 같은 문구를 0.8초
    // 안에 두 번 띄우지 않아서 바로 다음 테스트의 알림이 삼켜진다. 실패로
    // 끝내고 이 테스트를 맨 끝에 둔다.
    completer.completeError(Exception('network error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
