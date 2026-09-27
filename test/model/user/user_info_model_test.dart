import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/User/UserInfoModel.dart';

void main() {
  group('UserInfoModel.fromJson', () {
    test('모든 필드가 채워진 정상 응답을 파싱한다', () {
      final json = {
        'userId': 1,
        'email': 'test@ono.local',
        'name': '기승민',
        'profileImageUrl': 'https://cdn.test/profile.png',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
        'attendanceLevel': 3,
        'attendancePoint': 10,
        'noteWriteLevel': 2,
        'noteWritePoint': 5,
        'problemPracticeLevel': 4,
        'problemPracticePoint': 8,
        'notePracticeLevel': 1,
        'notePracticePoint': 0,
        'totalStudyLevel': 5,
        'totalStudyCurrentPoint': 20,
        'totalStudyNextLevelThreshold': 50,
        'notificationEnabled': false,
      };

      final user = UserInfoModel.fromJson(json);

      expect(user.userId, 1);
      expect(user.email, 'test@ono.local');
      expect(user.name, '기승민');
      expect(user.profileImageUrl, 'https://cdn.test/profile.png');
      expect(user.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(user.updatedAt, DateTime.parse('2026-01-02T00:00:00.000Z'));
      expect(user.attendanceLevel, 3);
      expect(user.attendancePoint, 10);
      expect(user.noteWriteLevel, 2);
      expect(user.noteWritePoint, 5);
      expect(user.problemPracticeLevel, 4);
      expect(user.problemPracticePoint, 8);
      expect(user.notePracticeLevel, 1);
      expect(user.notePracticePoint, 0);
      expect(user.totalStudyLevel, 5);
      expect(user.totalStudyCurrentPoint, 20);
      expect(user.totalStudyNextLevelThreshold, 50);
      expect(user.notificationEnabled, isFalse);
    });

    test('email, name, profileImageUrl 이 null 이어도 파싱된다', () {
      final user = UserInfoModel.fromJson({
        'userId': 1,
        'email': null,
        'name': null,
        'profileImageUrl': null,
      });

      expect(user.email, isNull);
      expect(user.name, isNull);
      expect(user.profileImageUrl, isNull);
    });

    test('레벨/포인트 관련 키가 없으면 기본값으로 떨어진다', () {
      final user = UserInfoModel.fromJson({'userId': 1});

      expect(user.attendanceLevel, 1);
      expect(user.attendancePoint, 0);
      expect(user.noteWriteLevel, 1);
      expect(user.noteWritePoint, 0);
      expect(user.problemPracticeLevel, 1);
      expect(user.problemPracticePoint, 0);
      expect(user.notePracticeLevel, 1);
      expect(user.notePracticePoint, 0);
      expect(user.totalStudyLevel, 0);
      expect(user.totalStudyCurrentPoint, 0);
      expect(user.totalStudyNextLevelThreshold, 40);
      expect(user.notificationEnabled, isTrue);
    });

    test('createdAt, updatedAt 키가 없으면 null 대신 현재 시각으로 채워진다', () {
      // 모델 필드는 DateTime? 로 null 을 허용하는데, fromJson 은 null 이면
      // DateTime.now() 로 대체해 절대 null 을 돌려주지 않는다. 버그라기보다는
      // "createdAt 이 없으면 지금 막 만들어진 것으로 본다"는 의도된 설계로 보이며,
      // 다만 호출부가 이 필드를 "정말 서버가 준 값"으로 오해하지 않도록 문서화해 둔다.
      final before = DateTime.now();
      final user = UserInfoModel.fromJson({'userId': 1});
      final after = DateTime.now();

      expect(user.createdAt, isNotNull);
      expect(
        user.createdAt!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        user.createdAt!.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('userId 가 없으면 예외가 난다 (필드가 non-nullable 이라 의도된 동작)', () {
      expect(
        () => UserInfoModel.fromJson({'email': 'test@ono.local'}),
        throwsA(isA<TypeError>()),
      );
    });

    test(
      'attendanceLevel 이 double(3.0)로 오면 예외가 난다',
      () {
        // TODO(#174): 실제 버그. lib/Model/User/UserInfoModel.dart:59 에서
        // attendanceLevel: json['attendanceLevel'] ?? 1 로, null 만 걸러낼 뿐
        // 실제 타입은 검사하지 않는다. 대입받는 필드가 int 인데 서버가 3.0 같은
        // double 을 내려주면 ?? 연산자를 그냥 통과해서 TypeError 로 죽는다.
        // 레벨/포인트 관련 필드 전부(noteWriteLevel, totalStudyLevel 등)가 같은 패턴이다.
        expect(
          () => UserInfoModel.fromJson({'userId': 1, 'attendanceLevel': 3.0}),
          throwsA(isA<TypeError>()),
        );
      },
      skip: '#174 에서 수정 예정',
    );
  });
}
