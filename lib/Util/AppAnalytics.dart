import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../Model/User/UserInfoModel.dart';

/// Firebase Analytics 에 "누가" 쓰고 있는지를 남긴다.
///
/// 그동안은 `logEvent` 로 무슨 일이 있었는지만 보냈다. 유저를 식별하는
/// `setUserId` 와 유저 속성인 `setUserProperty` 는 앱 어디에서도 부르지
/// 않아서, 콘솔에서 이벤트는 보여도 어떤 사용자층이 그 행동을 하는지
/// 갈라 볼 수가 없었다.
///
/// **개인정보는 보내지 않는다.** 이메일, 이름, 프로필 이미지 주소처럼 사람을
/// 직접 가리키는 값은 Firebase Analytics 정책에서도 금지된다. 여기서 보내는
/// 것은 서버가 이미 내려주는 학습 단계와 설정값뿐이고, 유저 식별자도 우리
/// 서버의 내부 번호라 그 자체로는 누구인지 알 수 없다.
///
/// 수집은 실패해도 앱 동작에 영향이 없어야 한다. 모든 호출에서 예외를 삼킨다.
class AppAnalytics {
  const AppAnalytics._();

  /// Firebase 는 유저 속성 이름 24자, 값 36자까지만 받는다. 아래 이름은
  /// 모두 그 안에 들어간다.
  static const String _loginMethod = 'login_method';
  static const String _totalStudyLevel = 'total_study_level';
  static const String _attendanceLevel = 'attendance_level';
  static const String _noteWriteLevel = 'note_write_level';
  static const String _problemPracticeLevel = 'problem_practice_level';
  static const String _notePracticeLevel = 'note_practice_level';
  static const String _notificationEnabled = 'notification_enabled';
  static const String _daysSinceSignup = 'days_since_signup';
  static const String _hasProfileImage = 'has_profile_image';

  static const List<String> _allProperties = [
    _loginMethod,
    _totalStudyLevel,
    _attendanceLevel,
    _noteWriteLevel,
    _problemPracticeLevel,
    _notePracticeLevel,
    _notificationEnabled,
    _daysSinceSignup,
    _hasProfileImage,
  ];

  /// 로그인한 유저를 식별시키고 유저 속성을 갱신한다.
  ///
  /// 유저 정보를 새로 받아올 때마다 부르면 된다. 레벨이나 알림 설정이
  /// 바뀌어도 다음 조회에서 따라온다.
  static Future<void> identify(
    UserInfoModel? user, {
    String? loginMethod,
  }) async {
    if (user == null) return;

    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.setUserId(id: user.userId.toString());

      await _set(_loginMethod, loginMethod);
      await _set(_totalStudyLevel, user.totalStudyLevel.toString());
      await _set(_attendanceLevel, user.attendanceLevel.toString());
      await _set(_noteWriteLevel, user.noteWriteLevel.toString());
      await _set(_problemPracticeLevel, user.problemPracticeLevel.toString());
      await _set(_notePracticeLevel, user.notePracticeLevel.toString());
      await _set(_notificationEnabled, user.notificationEnabled.toString());
      await _set(_daysSinceSignup, _daysSince(user.createdAt));
      // 이미지 주소 자체는 사람을 가리킬 수 있어서 보내지 않고, 넣었는지
      // 여부만 남긴다.
      await _set(
        _hasProfileImage,
        ((user.profileImageUrl ?? '').isNotEmpty).toString(),
      );
    } catch (error) {
      debugPrint('[AppAnalytics] 유저 식별 실패: $error');
    }
  }

  /// 로그아웃과 탈퇴 때 유저 식별 정보를 지운다.
  ///
  /// 지우지 않으면 같은 기기에서 다른 계정으로 로그인했을 때 앞 사람의
  /// 속성이 그대로 남아 통계가 섞인다.
  static Future<void> clear() async {
    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.setUserId(id: null);
      for (final name in _allProperties) {
        await _set(name, null);
      }
    } catch (error) {
      debugPrint('[AppAnalytics] 유저 정보 초기화 실패: $error');
    }
  }

  static Future<void> _set(String name, String? value) {
    return FirebaseAnalytics.instance.setUserProperty(
      name: name,
      // 값은 36자까지다. 넘을 일은 없지만 잘라서 보낸다.
      value:
          value == null || value.length <= 36 ? value : value.substring(0, 36),
    );
  }

  /// 가입한 지 며칠 지났는지. 가입 시각 자체가 아니라 경과일만 남긴다.
  static String? _daysSince(DateTime? createdAt) {
    if (createdAt == null) return null;
    final days = DateTime.now().difference(createdAt).inDays;
    return days < 0 ? '0' : days.toString();
  }
}
