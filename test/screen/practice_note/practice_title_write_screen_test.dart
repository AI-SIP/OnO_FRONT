// PracticeTitleWriteScreen 위젯 테스트.
//
// 복습 세트 제목을 입력해 새로 만들거나(신규 등록), 기존 세트의 제목·알림 설정을
// 고치는(수정) 화면이다. `practiceRegisterModel` 이 있으면 등록 모드,
// `practiceNoteUpdateModel` 이 있으면 수정 모드로 갈린다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteDetailModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteRegisterModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNoteUpdateModel.dart';
import 'package:ono/Model/PracticeNote/PracticeNotificationModel.dart';
import 'package:ono/Model/PracticeNote/RepeatType.dart';
import 'package:ono/Provider/PracticeNoteProvider.dart';
import 'package:ono/Screen/PracticeNote/PracticeTitleWriteScreen.dart';

import '../../helpers/helpers.dart';

/// 실제 화면에서는 문제 선택 → 제목 입력 화면처럼 여러 단계를 거쳐 이 화면에
/// 온다. `_submitPractice` 는 성공/실패 시 그 단계 수만큼 `Navigator.pop` 을
/// 반복해서 부른다(등록 2번, 수정 3번). 화면을 곧장 `home` 에 두면 팝할 라우트가
/// 없어 `NavigatorState.pop` 이 'Bad state: No element' 로 죽으므로, 제출까지
/// 확인하는 테스트는 이 위젯으로 몇 단계 쌓은 뒤 맨 위에 대상 화면을 띄운다.
class _StackedEntry extends StatelessWidget {
  final int remaining;
  final Widget target;

  const _StackedEntry({required this.remaining, required this.target});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => remaining > 0
                  ? _StackedEntry(remaining: remaining - 1, target: target)
                  : target,
            ),
          ),
          child: const Text('다음 단계'),
        ),
      ),
    );
  }
}

/// [target] 을 4단 아래에 라우트를 쌓은 네비게이터 스택의 맨 위에 띄운다.
Future<void> _pumpTargetOntoStack(
  WidgetTester tester,
  ProblemPracticeProvider practiceProvider,
  Widget target,
) async {
  const depth = 4;
  await pumpOnoWidget(
    tester,
    _StackedEntry(remaining: depth, target: target),
    practiceProvider: practiceProvider,
  );
  for (var i = 0; i <= depth; i++) {
    await tester.tap(find.text('다음 단계'));
    await tester.pumpAndSettle();
  }
}

PracticeNoteDetailModel _detail(
  int id, {
  PracticeNotificationModel? notification,
}) {
  return PracticeNoteDetailModel(
    practiceId: id,
    practiceTitle: 'practice-$id',
    practiceCount: 0,
    createdAt: DateTime(2024, 1, 1),
    lastSolvedAt: null,
    practiceNotificationModel: notification,
    problemIdList: const [],
  );
}

void main() {
  setUpOnoWidgetTest();

  late MockPracticeNoteService practiceNoteService;
  late MockProblemsProvider problemsProvider;
  late ProblemPracticeProvider practiceProvider;

  setUpAll(() {
    registerFallbackValue(
      PracticeNoteRegisterModel(
          practiceTitle: 'fallback', registerProblemIdList: const []),
    );
    registerFallbackValue(
      PracticeNoteUpdateModel(
        practiceNoteId: 0,
        addProblemIdList: const [],
        removeProblemIdList: const [],
      ),
    );
  });

  setUp(() {
    practiceNoteService = MockPracticeNoteService();
    problemsProvider = MockProblemsProvider();
    practiceProvider = ProblemPracticeProvider(
      problemsProvider: problemsProvider,
      practiceNoteService: practiceNoteService,
    );
  });

  /// 특정 위젯(예: ElevatedButton) 안에 있는 텍스트로 찾는다. 앱바 제목과
  /// 제출 버튼 문구가 같은 문자열을 쓰는 경우가 있어 `find.text` 단독으로는
  /// 두 개가 잡힌다.
  Finder appBarTitle(String text) => find.descendant(
        of: find.byType(AppBar),
        matching: find.text(text),
      );

  group('신규 등록 모드', () {
    testWidgets('앱바 문구, 빈 입력 필드, 안내 문구가 보인다', (tester) async {
      await pumpOnoWidget(
        tester,
        PracticeTitleWriteScreen(
          practiceRegisterModel: PracticeNoteRegisterModel(
            practiceTitle: '',
            registerProblemIdList: const [],
          ),
        ),
        practiceProvider: practiceProvider,
      );

      expect(appBarTitle('복습 세트 만들기'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, '복습 세트 만들기'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty);
      expect(find.text('3회 반복 복습 시스템'), findsOneWidget);
      // 알림 사용 스위치는 기본 꺼짐 상태라 반복 주기 섹션이 안 보인다.
      expect(find.text('반복 주기'), findsNothing);
    });

    testWidgets('빈 제목으로 제출하면 경고 다이얼로그가 뜨고, 확인을 누르면 닫힌다', (tester) async {
      await pumpOnoWidget(
        tester,
        PracticeTitleWriteScreen(
          practiceRegisterModel: PracticeNoteRegisterModel(
            practiceTitle: '',
            registerProblemIdList: const [],
          ),
        ),
        practiceProvider: practiceProvider,
      );

      await tester.tap(find.widgetWithText(ElevatedButton, '복습 세트 만들기'));
      await tester.pumpAndSettle();

      expect(find.text('제목을 입력해 주세요!'), findsOneWidget);
      verifyNever(() => practiceNoteService.registerPracticeNote(any()));

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('제목을 입력해 주세요!'), findsNothing);
    });

    testWidgets('제목을 입력하고 제출하면 registerPractice 가 불리고 성공 스낵바가 뜬다',
        (tester) async {
      when(() => practiceNoteService.registerPracticeNote(any()))
          .thenAnswer((_) async => 5);
      when(() => practiceNoteService.getPracticeNoteById(5,
          showErrorSnackBar: false)).thenAnswer((_) async => _detail(5));

      await _pumpTargetOntoStack(
        tester,
        practiceProvider,
        PracticeTitleWriteScreen(
          practiceRegisterModel: PracticeNoteRegisterModel(
            practiceTitle: '',
            registerProblemIdList: const [],
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '9월 모의고사 오답');
      await tester.tap(find.widgetWithText(ElevatedButton, '복습 세트 만들기'));
      await tester.pumpAndSettle();

      final captured =
          verify(() => practiceNoteService.registerPracticeNote(captureAny()))
              .captured;
      expect(
        (captured.single as PracticeNoteRegisterModel).practiceTitle,
        '9월 모의고사 오답',
      );
      expect(find.text('복습 세트가 생성되었습니다.'), findsOneWidget);
    });

    testWidgets('등록이 실패하면 실패 스낵바가 뜨고 화면에 남는다', (tester) async {
      when(() => practiceNoteService.registerPracticeNote(any()))
          .thenThrow(Exception('network error'));

      await pumpOnoWidget(
        tester,
        PracticeTitleWriteScreen(
          practiceRegisterModel: PracticeNoteRegisterModel(
            practiceTitle: '',
            registerProblemIdList: const [],
          ),
        ),
        practiceProvider: practiceProvider,
      );

      await tester.enterText(find.byType(TextField), '실패할 제목');
      await tester.tap(find.widgetWithText(ElevatedButton, '복습 세트 만들기'));
      await tester.pumpAndSettle();

      expect(find.text('복습 세트 생성에 실패했습니다. 잠시 후 다시 시도해주세요.'), findsOneWidget);
      expect(find.byType(PracticeTitleWriteScreen), findsOneWidget);
    });
  });

  group('수정 모드', () {
    testWidgets('앱바 문구와 기존 제목이 채워져서 보인다', (tester) async {
      await pumpOnoWidget(
        tester,
        PracticeTitleWriteScreen(
          practiceNoteUpdateModel: PracticeNoteUpdateModel(
            practiceNoteId: 1,
            practiceTitle: '기존 복습 세트',
            addProblemIdList: const [],
            removeProblemIdList: const [],
          ),
        ),
        practiceProvider: practiceProvider,
      );

      expect(appBarTitle('복습 세트 수정하기'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, '복습 세트 수정하기'), findsOneWidget);
      expect(find.text('기존 복습 세트'), findsOneWidget);
    });

    testWidgets('기존 알림 설정이 있으면 스위치가 켜진 채로 반복 주기·시각이 보인다', (tester) async {
      await pumpOnoWidget(
        tester,
        PracticeTitleWriteScreen(
          practiceNoteUpdateModel: PracticeNoteUpdateModel(
            practiceNoteId: 1,
            practiceTitle: '기존 복습 세트',
            addProblemIdList: const [],
            removeProblemIdList: const [],
          ),
          practiceNoteDetailModel: _detail(
            1,
            notification: PracticeNotificationModel(
              intervalDays: 7,
              hour: 9,
              minute: 30,
              repeatType: RepeatType.weekly,
              weekDays: const [1, 3],
            ),
          ),
        ),
        practiceProvider: practiceProvider,
      );

      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text('반복 주기'), findsOneWidget);
      expect(find.text('요일 선택'), findsOneWidget); // repeatType.weekly 라 보인다.
    });

    testWidgets('제목을 고치고 제출하면 updatePractice 가 새 제목으로 불린다', (tester) async {
      when(() => practiceNoteService.updatePracticeNote(any(),
              showErrorSnackBar: any(named: 'showErrorSnackBar')))
          .thenAnswer((_) async {});
      when(() => practiceNoteService.getPracticeNoteById(1,
          showErrorSnackBar: false)).thenAnswer((_) async => _detail(1));

      await _pumpTargetOntoStack(
        tester,
        practiceProvider,
        PracticeTitleWriteScreen(
          practiceNoteUpdateModel: PracticeNoteUpdateModel(
            practiceNoteId: 1,
            practiceTitle: '기존 복습 세트',
            addProblemIdList: const [],
            removeProblemIdList: const [],
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '고친 제목');
      await tester.tap(find.widgetWithText(ElevatedButton, '복습 세트 수정하기'));
      await tester.pumpAndSettle();

      final captured = verify(() => practiceNoteService.updatePracticeNote(
            captureAny(),
            showErrorSnackBar: any(named: 'showErrorSnackBar'),
          )).captured;
      expect(
        (captured.single as PracticeNoteUpdateModel).practiceTitle,
        '고친 제목',
      );
      expect(find.text('복습 세트가 수정되었습니다.'), findsOneWidget);
    });
  });

  group('알림 설정 상호작용', () {
    testWidgets('알림 스위치를 켜면 반복 주기 선택지가 나타난다', (tester) async {
      await pumpOnoWidget(
        tester,
        PracticeTitleWriteScreen(
          practiceRegisterModel: PracticeNoteRegisterModel(
            practiceTitle: '',
            registerProblemIdList: const [],
          ),
        ),
        practiceProvider: practiceProvider,
      );

      expect(find.text('반복 주기'), findsNothing);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('반복 주기'), findsOneWidget);
      expect(find.text('매일'), findsOneWidget);
      expect(find.text('매주'), findsOneWidget);
      // 기본값은 daily 라 요일 선택 UI는 아직 안 보인다.
      expect(find.text('요일 선택'), findsNothing);
    });

    testWidgets('매주를 고르면 요일 선택 UI가 나타나고, 고른 요일이 등록 시 반영된다', (tester) async {
      when(() => practiceNoteService.registerPracticeNote(any()))
          .thenAnswer((_) async => 5);
      when(() => practiceNoteService.getPracticeNoteById(5,
          showErrorSnackBar: false)).thenAnswer((_) async => _detail(5));

      await _pumpTargetOntoStack(
        tester,
        practiceProvider,
        PracticeTitleWriteScreen(
          practiceRegisterModel: PracticeNoteRegisterModel(
            practiceTitle: '',
            registerProblemIdList: const [],
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '요일 알림 테스트');
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('매주'));
      await tester.pumpAndSettle();

      expect(find.text('요일 선택'), findsOneWidget);

      await tester.tap(find.text('화')); // 2번 요일
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, '복습 세트 만들기'));
      await tester.pumpAndSettle();

      final captured =
          verify(() => practiceNoteService.registerPracticeNote(captureAny()))
              .captured;
      final model = captured.single as PracticeNoteRegisterModel;
      expect(model.practiceNotificationModel?.repeatType, RepeatType.weekly);
      expect(model.practiceNotificationModel?.weekDays, [2]);
    });
  });

  group('알려진 프로덕션 버그', () {
    testWidgets(
      '알림이 켜져 있지만 intervalDays 가 없는 모델을 넘기면 초기화 중 크래시한다',
      (tester) async {
        // TODO(#174): 실제 버그. lib/Screen/PracticeNote/PracticeTitleWriteScreen.dart:61-66
        // initState 가 practiceNotificationModel != null 인지만 확인하고,
        // 그 안의 intervalDays/hour/minute 는 null-check(!) 연산자로 바로 풀어 쓴다.
        // 하지만 PracticeNotificationModel 의 생성자는 이 세 필드를 전부 nullable
        // 로 두고 기본값을 주지 않는다(fromJson 에만 기본값이 있다). 그래서
        // "알림은 켜져 있는데 intervalDays 는 비어 있는" 모델을 직접 만들어 넘기면
        // (서버가 부분 데이터를 내려주는 경우 등) 화면 진입 자체가
        // "Null check operator used on a null value" 로 죽는다.
        await pumpOnoWidget(
          tester,
          PracticeTitleWriteScreen(
            practiceNoteUpdateModel: PracticeNoteUpdateModel(
              practiceNoteId: 1,
              practiceTitle: '기존 복습 세트',
              addProblemIdList: const [],
              removeProblemIdList: const [],
            ),
            practiceNoteDetailModel: _detail(
              1,
              notification: PracticeNotificationModel(
                hour: 9,
                minute: 30,
                repeatType: RepeatType.daily,
                // intervalDays 를 일부러 비운다.
              ),
            ),
          ),
          practiceProvider: practiceProvider,
        );

        expect(tester.takeException(), isA<TypeError>());
      },
      skip: true, // #174 에서 수정 예정
    );
  });

  group('반응형', () {
    testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
      await pumpOnoWidget(
        tester,
        PracticeTitleWriteScreen(
          practiceRegisterModel: PracticeNoteRegisterModel(
            practiceTitle: '',
            registerProblemIdList: const [],
          ),
        ),
        practiceProvider: practiceProvider,
        surfaceSize: OnoSurface.tablet,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PracticeTitleWriteScreen), findsOneWidget);
    });

    testWidgets(
      '작은 폰(320) 폭에서도 예외 없이 그려진다',
      (tester) async {
        // TODO(#174): 실제 버그. lib/Screen/PracticeNote/PracticeTitleWriteScreen.dart:418-431
        // _buildInfoHeader 의 Row 가 24px 아이콘 + 8px 간격 + fontSize 20 고정
        // 텍스트("3회 반복 복습 시스템", 실측 243px)를 Expanded/Flexible 없이
        // 나란히 놓는다. 폭 320 기기에서 이 Row 가 쓸 수 있는 폭은 바깥 패딩
        // 20*2 와 컨테이너 패딩 20*2 를 빼면 240 남짓이라 RenderFlex 가 34px
        // 오버플로우하고, 사용자 화면에는 노란/검정 줄무늬가 그대로 보인다.
        // 폰(390)·태블릿(834) 에서는 폭이 남아 드러나지 않는다.
        await pumpOnoWidget(
          tester,
          PracticeTitleWriteScreen(
            practiceRegisterModel: PracticeNoteRegisterModel(
              practiceTitle: '',
              registerProblemIdList: const [],
            ),
          ),
          practiceProvider: practiceProvider,
          surfaceSize: OnoSurface.smallPhone,
        );

        expect(tester.takeException(), isNull);
      },
      skip: true, // #174 에서 수정 예정
    );
  });
}
