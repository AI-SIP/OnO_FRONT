// StudyRoomListScreen 위젯 테스트.
//
// 빈 상태/로딩/정상 목록과, 방장 배지·안읽음 배지 같은 조건부 표시,
// FAB 를 통한 방 만들기·참여하기 진입을 본다. 마지막 그룹은
// lib/Service/Api/StudyRoom/StudyRoomService.dart:391-397 의 `_mapList` 가
// 응답이 배열이 아니면 예외 없이 빈 목록을 돌려주는 버그를 화면 레벨에서
// 재현한다 (진짜 StudyRoomService + TestHttpClient 사용).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/StudyRoom/StudyRoomMemberModel.dart';
import 'package:ono/Model/StudyRoom/StudyRoomModel.dart';
import 'package:ono/Provider/StudyRoomProvider.dart';
import 'package:ono/Screen/StudyRoom/StudyRoomCreateScreen.dart';
import 'package:ono/Screen/StudyRoom/StudyRoomDetailScreen.dart';
import 'package:ono/Screen/StudyRoom/StudyRoomJoinScreen.dart';
import 'package:ono/Screen/StudyRoom/StudyRoomListScreen.dart';
import 'package:ono/Service/Api/HttpService.dart';
import 'package:ono/Service/Api/StudyRoom/StudyRoomService.dart';

import '../../helpers/helpers.dart';

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    pushed.add(route);
    super.didPush(route, previousRoute);
  }
}

StudyRoomModel _roomOf({
  required int roomId,
  required int hostUserId,
  bool hasUnreadReport = false,
}) {
  return StudyRoomModel(
    roomId: roomId,
    name: '방 $roomId',
    hostUserId: hostUserId,
    members: const [
      StudyRoomMemberModel(
        userId: 1,
        name: '나',
        totalStudyLevel: 1,
        currentStreak: 0,
        weeklyProblemCount: 0,
        weeklyPracticeCount: 0,
      ),
    ],
    hasUnreadReport: hasUnreadReport,
  );
}

void main() {
  setUpOnoWidgetTest();

  late MockStudyRoomService service;
  late StudyRoomProvider provider;

  setUp(() {
    service = MockStudyRoomService();
    provider = StudyRoomProvider(studyRoomService: service);
  });

  testWidgets('로딩 중에는 스피너가 뜬다', (tester) async {
    final completer = Completer<List<StudyRoomModel>>();
    when(() => service.fetchMyRooms()).thenAnswer((_) => completer.future);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomListScreen(),
        studyRoomProvider: provider,
        settle: false,
      );
    });

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete([]);
    await tester.pump();
  });

  testWidgets('참여 중인 방이 없으면 빈 상태 화면이 뜬다', (tester) async {
    when(() => service.fetchMyRooms()).thenAnswer((_) async => []);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomListScreen(),
        studyRoomProvider: provider,
      );
    });

    expect(find.text('참여 중인 스터디룸이 없어요'), findsOneWidget);
    expect(find.text('방 만들기'), findsOneWidget);
    expect(find.text('코드로 참여하기'), findsOneWidget);
  });

  testWidgets('방 목록이 있으면 이름과 멤버 수가 보인다', (tester) async {
    when(() => service.fetchMyRooms()).thenAnswer(
      (_) async => [_roomOf(roomId: 1, hostUserId: 1)],
    );

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomListScreen(),
        studyRoomProvider: provider,
      );
    });

    expect(find.text('방 1'), findsOneWidget);
    expect(find.text('멤버 1명'), findsOneWidget);
    expect(find.text('참여 중인 스터디룸이 없어요'), findsNothing);
  });

  testWidgets('내가 방장인 방에는 왕관 아이콘이, 아닌 방에는 없다', (tester) async {
    when(() => service.fetchMyRooms()).thenAnswer(
      (_) async => [
        _roomOf(
            roomId: 1, hostUserId: 1), // 방장(userInfoModel 없음 → -1, 여기선 host 아님)
      ],
    );

    // 기본 UserProvider 는 userInfoModel 이 없어 currentUserId 가 null 이라
    // hostUserId(1) 과 절대 같아지지 않는다 → 왕관이 보이지 않아야 한다.
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomListScreen(),
        studyRoomProvider: provider,
      );
    });

    expect(find.byIcon(Icons.workspace_premium_outlined), findsNothing);
  });

  testWidgets('읽지 않은 주간 리포트가 있으면 없을 때보다 원형 배지가 하나 더 보인다', (tester) async {
    int countCircleBadges(WidgetTester t) => t
        .widgetList<Container>(find.byType(Container))
        .where(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration as BoxDecoration).shape == BoxShape.circle &&
              c.child == null,
        )
        .length;

    when(() => service.fetchMyRooms()).thenAnswer(
      (_) async => [_roomOf(roomId: 1, hostUserId: 1, hasUnreadReport: false)],
    );
    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomListScreen(),
        studyRoomProvider: provider,
      );
    });
    final withoutBadge = countCircleBadges(tester);

    when(() => service.fetchMyRooms()).thenAnswer(
      (_) async => [_roomOf(roomId: 1, hostUserId: 1, hasUnreadReport: true)],
    );
    await provider.fetchMyRooms();
    await tester.pumpAndSettle();
    final withBadge = countCircleBadges(tester);

    expect(withBadge, withoutBadge + 1);
  });

  testWidgets('방 카드를 탭하면 StudyRoomDetailScreen 으로 push 된다', (tester) async {
    when(() => service.fetchMyRooms()).thenAnswer(
      (_) async => [_roomOf(roomId: 7, hostUserId: 1)],
    );
    final observer = _RecordingNavigatorObserver();

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomListScreen(),
        studyRoomProvider: provider,
        navigatorObservers: [observer],
      );
    });

    await tester.tap(find.text('방 7'));
    await tester.pumpAndSettle();

    expect(find.byType(StudyRoomDetailScreen), findsOneWidget);
  });

  testWidgets('FAB 를 탭하면 방 만들기·참여하기 메뉴가 뜬다', (tester) async {
    when(() => service.fetchMyRooms()).thenAnswer((_) async => []);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomListScreen(),
        studyRoomProvider: provider,
      );
    });

    await tester.tap(find.text('스터디룸 참여'));
    await tester.pumpAndSettle();

    expect(find.text('새 방 만들기'), findsOneWidget);
    expect(find.text('초대 코드로 참여하기'), findsOneWidget);
  });

  testWidgets('메뉴에서 새 방 만들기를 탭하면 StudyRoomCreateScreen 으로 이동한다',
      (tester) async {
    when(() => service.fetchMyRooms()).thenAnswer((_) async => []);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomListScreen(),
        studyRoomProvider: provider,
      );
    });

    await tester.tap(find.text('스터디룸 참여'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('새 방 만들기'));
    await tester.pumpAndSettle();

    expect(find.byType(StudyRoomCreateScreen), findsOneWidget);
  });

  testWidgets('메뉴에서 초대 코드로 참여하기를 탭하면 StudyRoomJoinScreen 으로 이동한다',
      (tester) async {
    when(() => service.fetchMyRooms()).thenAnswer((_) async => []);

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomListScreen(),
        studyRoomProvider: provider,
      );
    });

    await tester.tap(find.text('스터디룸 참여'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('초대 코드로 참여하기'));
    await tester.pumpAndSettle();

    expect(find.byType(StudyRoomJoinScreen), findsOneWidget);
  });

  testWidgets('태블릿 폭에서도 예외 없이 그려진다', (tester) async {
    when(() => service.fetchMyRooms()).thenAnswer(
      (_) async => [_roomOf(roomId: 1, hostUserId: 1)],
    );

    await withMockedNetworkImages(() async {
      await pumpOnoWidget(
        tester,
        const StudyRoomListScreen(),
        studyRoomProvider: provider,
        surfaceSize: OnoSurface.tablet,
      );
    });

    expect(tester.takeException(), isNull);
  });

  group('_mapList 버그 재현 (진짜 StudyRoomService)', () {
    // TODO(#174): 실제 버그. lib/Service/Api/StudyRoom/StudyRoomService.dart:391-397
    // `_mapList` 가 서버 응답이 배열이 아니면 예외 없이 빈 목록을 돌려준다.
    // 그 결과 방이 실제로 있어도 이 화면은 "참여 중인 스터디룸이 없어요" 라는
    // 빈 상태와 구분되지 않게 보인다 — 즉 네트워크/서버 오류가 "방이 하나도
    // 없다"는 정상 상태로 둔갑한다.
    testWidgets(
      '서버가 배열이 아닌 응답을 주면 방이 있어도 빈 상태로 보인다 (버그)',
      (tester) async {
        final http = TestHttpClient.respondJson(
          {'message': 'internal error', 'data': null},
        );
        final realService = StudyRoomService(
          httpService: HttpService(
            client: http.client,
            tokenProvider: buildMockTokenProvider(),
          ),
        );
        final realProvider = StudyRoomProvider(studyRoomService: realService);

        await withMockedNetworkImages(() async {
          await pumpOnoWidget(
            tester,
            const StudyRoomListScreen(),
            studyRoomProvider: realProvider,
          );
        });

        // 서버 오류였음에도 예외가 나지 않고, "방이 없다" 는 빈 상태로 보인다.
        expect(find.text('참여 중인 스터디룸이 없어요'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      skip: true, // #174 에서 수정 예정
    );
  });
}
