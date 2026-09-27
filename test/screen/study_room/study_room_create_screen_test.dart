// StudyRoomCreateScreen 위젯 테스트.
//
// 방 이름 폼 검증(빈 값)과, 생성 성공 시 provider.createRoom 호출 및 화면
// pop, 실패 시 에러 스낵바를 본다. Navigator.pop 이 실제로 동작하도록,
// 화면을 곧바로 home 에 두지 않고 버튼을 눌러 push 한 뒤 접근한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/StudyRoom/StudyRoomModel.dart';
import 'package:ono/Provider/StudyRoomProvider.dart';
import 'package:ono/Screen/StudyRoom/StudyRoomCreateScreen.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  late MockStudyRoomService service;
  late StudyRoomProvider provider;

  setUp(() {
    service = MockStudyRoomService();
    provider = StudyRoomProvider(studyRoomService: service);
  });

  /// StudyRoomCreateScreen 을 '열기' 버튼을 눌러 push 한다.
  /// Navigator.pop 이 되돌아갈 곳이 있어야 정상 동작하기 때문이다.
  Future<void> pumpPushed(WidgetTester tester) async {
    // 실제 앱에서는 항상 Scaffold 가 있는 화면 위에서 push 되므로, pop 이후에도
    // 스낵바를 받아줄 Scaffold 를 남겨 둔다.
    await pumpOnoWidget(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudyRoomCreateScreen()),
            ),
            child: const Text('열기'),
          ),
        ),
      ),
      studyRoomProvider: provider,
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  testWidgets('이름을 비운 채 만들기를 누르면 검증 다이얼로그가 뜨고 createRoom 은 안 불린다',
      (tester) async {
    await pumpPushed(tester);

    await tester.tap(find.widgetWithText(TextButton, '방 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('방 이름을 입력해 주세요.'), findsOneWidget);
    verifyNever(() => service.createRoom(any()));

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('방 이름을 입력해 주세요.'), findsNothing);
  });

  testWidgets('공백만 입력하면 trim 후 빈 값으로 취급되어 검증 다이얼로그가 뜬다', (tester) async {
    await pumpPushed(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(TextButton, '방 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('방 이름을 입력해 주세요.'), findsOneWidget);
    verifyNever(() => service.createRoom(any()));
  });

  testWidgets('이름을 입력하고 만들기를 누르면 createRoom 이 호출되고 화면이 닫힌다', (tester) async {
    when(() => service.createRoom('알고리즘 스터디')).thenAnswer(
      (_) async => const StudyRoomModel(
        roomId: 1,
        name: '알고리즘 스터디',
        hostUserId: 1,
        members: [],
      ),
    );

    await pumpPushed(tester);
    await tester.enterText(find.byType(TextField), '알고리즘 스터디');
    await tester.tap(find.widgetWithText(TextButton, '방 만들기'));
    await tester.pumpAndSettle();

    verify(() => service.createRoom('알고리즘 스터디')).called(1);
    expect(find.byType(StudyRoomCreateScreen), findsNothing);
  });

  testWidgets('이름 앞뒤 공백은 trim 되어 전달된다', (tester) async {
    when(() => service.createRoom('스터디')).thenAnswer(
      (_) async => const StudyRoomModel(
        roomId: 1,
        name: '스터디',
        hostUserId: 1,
        members: [],
      ),
    );

    await pumpPushed(tester);
    await tester.enterText(find.byType(TextField), '  스터디  ');
    await tester.tap(find.widgetWithText(TextButton, '방 만들기'));
    await tester.pumpAndSettle();

    verify(() => service.createRoom('스터디')).called(1);
  });

  testWidgets('생성에 실패하면 에러 스낵바가 뜨고 화면은 닫히지 않는다', (tester) async {
    when(() => service.createRoom(any())).thenThrow(Exception('network'));

    await pumpPushed(tester);
    await tester.enterText(find.byType(TextField), '스터디');
    await tester.tap(find.widgetWithText(TextButton, '방 만들기'));
    // pumpAndSettle 은 스낵바의 3초 자동 소멸 타이머까지 흘려보내 버리므로,
    // 스낵바가 뜬 직후의 상태만 짧게 pump 해서 확인한다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('방 생성에 실패했습니다'), findsOneWidget);
    expect(find.byType(StudyRoomCreateScreen), findsOneWidget);
  });

  testWidgets('이름 입력 필드는 20자로 길이가 제한된다', (tester) async {
    await pumpPushed(tester);

    await tester.enterText(
      find.byType(TextField),
      '가나다라마바사아자차카타파하거너더러머버서어저처커터퍼허', // 20자 초과
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, lessThanOrEqualTo(20));
  });

  testWidgets('닫기 버튼을 누르면 화면이 닫힌다', (tester) async {
    await pumpPushed(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(StudyRoomCreateScreen), findsNothing);
  });

  testWidgets('사진을 아직 선택하지 않았으면 "사진 선택 취소" 버튼이 없다', (tester) async {
    await pumpPushed(tester);

    expect(find.text('사진 선택 취소'), findsNothing);
    expect(find.text('사진 선택'), findsOneWidget);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    await pumpOnoWidget(
      tester,
      const StudyRoomCreateScreen(),
      studyRoomProvider: provider,
      surfaceSize: OnoSurface.tablet,
    );

    expect(tester.takeException(), isNull);
  });
}
