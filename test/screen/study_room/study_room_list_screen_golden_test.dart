// 스터디룸 목록 화면 골든 테스트.
//
// 기준 이미지를 다시 뜨는 방법은 test/README.md 의 「골든 테스트」 절에 있다.
import 'package:mocktail/mocktail.dart';
import 'package:ono/Model/StudyRoom/StudyRoomMemberModel.dart';
import 'package:ono/Model/StudyRoom/StudyRoomModel.dart';
import 'package:ono/Provider/StudyRoomProvider.dart';
import 'package:ono/Screen/StudyRoom/StudyRoomListScreen.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpOnoWidgetTest();

  StudyRoomMemberModel member(int userId, String name) => StudyRoomMemberModel(
        userId: userId,
        name: name,
        totalStudyLevel: 3,
        currentStreak: 2,
        weeklyProblemCount: 5,
        weeklyPracticeCount: 1,
      );

  screenGoldenTest(
    '스터디룸 목록 화면',
    fileName: 'study_room_list_screen',
    surfaces: GoldenSurface.layouts,
    buildApp: () async {
      final service = MockStudyRoomService();
      when(() => service.fetchMyRooms()).thenAnswer(
        (_) async => [
          StudyRoomModel(
            roomId: 1,
            name: '알고리즘 스터디',
            hostUserId: 1,
            members: [member(1, '나'), member(2, '친구')],
            hasUnreadReport: true,
          ),
          StudyRoomModel(
            roomId: 2,
            name: '수능 준비방',
            hostUserId: 3,
            members: [member(1, '나'), member(3, '방장'), member(4, '멤버')],
          ),
        ],
      );

      return buildOnoApp(
        const StudyRoomListScreen(),
        cosmeticProvider: await loadedCosmeticProvider(),
        studyRoomProvider: StudyRoomProvider(studyRoomService: service),
      );
    },
  );
}
