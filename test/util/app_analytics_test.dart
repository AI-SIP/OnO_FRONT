import 'package:flutter_test/flutter_test.dart';
import 'package:ono/Model/User/UserInfoModel.dart';
import 'package:ono/Util/AppAnalytics.dart';

import '../helpers/helpers.dart';

/// Analytics 에 유저 정보를 어디까지 보내는지 잠가 둔다.
///
/// 여기서 중요한 것은 두 가지다. 사람을 직접 가리키는 값(이메일, 이름,
/// 프로필 이미지 주소)이 절대 나가지 않는 것, 그리고 로그아웃하면 앞 사람의
/// 흔적이 남지 않는 것이다.
void main() {
  setUpOnoTest();
  setUpAll(stubFirebaseAnalytics);
  setUp(resetAnalyticsRecorder);

  UserInfoModel buildUser({
    int userId = 42,
    String? email = 'someone@example.com',
    String? name = '기승민',
    String? profileImageUrl,
    DateTime? createdAt,
    bool notificationEnabled = true,
  }) {
    return UserInfoModel(
      userId: userId,
      email: email,
      name: name,
      profileImageUrl: profileImageUrl,
      createdAt: createdAt ?? DateTime.now().subtract(const Duration(days: 12)),
      totalStudyLevel: 7,
      attendanceLevel: 3,
      noteWriteLevel: 4,
      problemPracticeLevel: 5,
      notePracticeLevel: 6,
      notificationEnabled: notificationEnabled,
    );
  }

  group('identify', () {
    test('유저 번호로 식별하고 학습 단계를 유저 속성으로 남긴다', () async {
      await AppAnalytics.identify(buildUser(), loginMethod: 'kakao');

      final recorder = analyticsRecorder;
      expect(recorder.userId, '42');
      expect(recorder.userProperties['login_method'], 'kakao');
      expect(recorder.userProperties['total_study_level'], '7');
      expect(recorder.userProperties['attendance_level'], '3');
      expect(recorder.userProperties['note_write_level'], '4');
      expect(recorder.userProperties['problem_practice_level'], '5');
      expect(recorder.userProperties['note_practice_level'], '6');
      expect(recorder.userProperties['notification_enabled'], 'true');
      expect(recorder.userProperties['days_since_signup'], '12');
    });

    test('이메일, 이름, 프로필 이미지 주소는 절대 보내지 않는다', () async {
      await AppAnalytics.identify(
        buildUser(profileImageUrl: 'https://cdn.ono/u/42/face.png'),
        loginMethod: 'google',
      );

      final sent =
          analyticsRecorder.userProperties.values.whereType<String>().join('|');
      expect(sent, isNot(contains('someone@example.com')));
      expect(sent, isNot(contains('기승민')));
      expect(sent, isNot(contains('cdn.ono')));
      expect(analyticsRecorder.userId, isNot(contains('@')));
    });

    test('프로필 이미지는 주소 대신 넣었는지 여부만 남긴다', () async {
      await AppAnalytics.identify(
          buildUser(profileImageUrl: 'https://a/b.png'));
      expect(analyticsRecorder.userProperties['has_profile_image'], 'true');

      resetAnalyticsRecorder();
      await AppAnalytics.identify(buildUser(profileImageUrl: null));
      expect(analyticsRecorder.userProperties['has_profile_image'], 'false');
    });

    test('유저 속성 이름은 Firebase 제한인 24자를 넘지 않는다', () async {
      await AppAnalytics.identify(buildUser(), loginMethod: 'apple');

      for (final name in analyticsRecorder.userProperties.keys) {
        expect(name.length, lessThanOrEqualTo(24), reason: '$name 이 24자를 넘는다');
      }
    });

    test('유저 속성 값은 Firebase 제한인 36자를 넘지 않는다', () async {
      await AppAnalytics.identify(
        buildUser(),
        loginMethod: 'a' * 100,
      );

      for (final entry in analyticsRecorder.userProperties.entries) {
        expect(
          entry.value?.length ?? 0,
          lessThanOrEqualTo(36),
          reason: '${entry.key} 값이 36자를 넘는다',
        );
      }
    });

    test('유저 정보가 없으면 아무것도 보내지 않는다', () async {
      await AppAnalytics.identify(null, loginMethod: 'guest');

      expect(analyticsRecorder.userId, isNull);
      expect(analyticsRecorder.userProperties, isEmpty);
    });

    test('가입 시각이 없으면 경과일을 비워 둔다', () async {
      final user = buildUser();
      user.createdAt = null;

      await AppAnalytics.identify(user);

      expect(analyticsRecorder.userProperties['days_since_signup'], isNull);
    });

    test('가입 시각이 미래로 잡혀 있어도 음수를 보내지 않는다', () async {
      // 기기 시계가 서버보다 앞서 있으면 경과일이 음수가 된다.
      await AppAnalytics.identify(
        buildUser(createdAt: DateTime.now().add(const Duration(days: 3))),
      );

      expect(analyticsRecorder.userProperties['days_since_signup'], '0');
    });
  });

  group('clear', () {
    test('식별자와 유저 속성을 모두 지운다', () async {
      await AppAnalytics.identify(buildUser(), loginMethod: 'kakao');
      expect(analyticsRecorder.userId, '42');

      await AppAnalytics.clear();

      expect(analyticsRecorder.userId, isNull);
      expect(
        analyticsRecorder.userProperties.values.where((v) => v != null),
        isEmpty,
        reason: '남아 있는 속성이 있으면 다음 로그인 유저의 통계와 섞인다',
      );
    });

    test('앞서 식별한 적이 없어도 조용히 지나간다', () async {
      await AppAnalytics.clear();

      expect(analyticsRecorder.userId, isNull);
    });
  });
}
