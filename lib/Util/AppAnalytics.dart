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

  /// 지금 쓰는 테마 색 이름. 기기에 저장되는 값이라 로그아웃해도 지우지 않는다.
  static const String themeColorProperty = 'theme_color';

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

  /// 이 빌드가 Analytics 를 보내도 되는지.
  ///
  /// Firebase 프로젝트가 운영과 개발에 하나뿐이라, 개발 서버 빌드나 로컬
  /// 디버그 실행에서 누른 것까지 운영 통계에 섞였다. 운영 서버를 붙인 릴리즈
  /// 빌드만 보낸다. 기준은 Sentry 가 `production` 으로 치는 빌드와 같다.
  static bool shouldCollect({
    required String appEnv,
    required bool isReleaseMode,
  }) {
    return isReleaseMode && appEnv == 'prod';
  }

  /// [shouldCollect] 에 따라 수집을 켜거나 끈다. Firebase 초기화 직후에 부른다.
  ///
  /// 네이티브 SDK 가 앱 시작과 함께 보내는 자동 이벤트는 이 호출보다 먼저
  /// 나갈 수 있다. 끄는 값은 기기에 남아서 다음 실행부터는 처음부터 꺼진다.
  static Future<void> applyCollectionPolicy() async {
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
        shouldCollect(
          appEnv: const String.fromEnvironment('ENV', defaultValue: 'local'),
          isReleaseMode: kReleaseMode,
        ),
      );
    } catch (error) {
      debugPrint('[AppAnalytics] 수집 설정 실패: $error');
    }
  }

  /// 이벤트를 남긴다. 새로 더하는 이벤트는 모두 이것을 거친다.
  ///
  /// 이름 규칙과 파라미터 이름은 `docs/애널리틱스 지표/이벤트 목록.md` 에
  /// 모아 두었다. 파라미터는 콘솔에 맞춤 측정기준으로 등록해야 보고서에
  /// 나오고 등록 한도가 50개라, 새 이름을 만들기 전에 목록에 있는 것을
  /// 먼저 쓴다.
  ///
  /// Firebase 는 파라미터 값으로 문자열과 숫자만 받는다. bool 은 문자열로
  /// 바꾸고, 100자를 넘는 문자열은 잘라서 보낸다. 수집에 실패해도 앱 동작에
  /// 영향이 없도록 예외를 삼킨다.
  static void logEvent(String name, [Map<String, Object?>? parameters]) {
    try {
      FirebaseAnalytics.instance
          .logEvent(name: name, parameters: _sanitize(parameters))
          .catchError((Object error) {
        debugPrint('[AppAnalytics] $name 기록 실패: $error');
      });
    } catch (error) {
      debugPrint('[AppAnalytics] $name 기록 실패: $error');
    }
  }

  static Map<String, Object>? _sanitize(Map<String, Object?>? parameters) {
    if (parameters == null) return null;
    final result = <String, Object>{};
    parameters.forEach((key, value) {
      if (value == null) return;
      if (value is bool) {
        result[key] = value.toString();
      } else if (value is num) {
        result[key] = value;
      } else {
        final text = value.toString();
        result[key] = text.length <= 100 ? text : text.substring(0, 100);
      }
    });
    return result;
  }

  /// 방금 가입한 계정으로 보이는지.
  ///
  /// 서버가 로그인 응답에 신규 가입 여부를 실어 주지 않아서 계정이 만들어진
  /// 시각으로 판단한다. 튜토리얼을 자동으로 띄우는 기준(30분)보다 좁게 잡아서
  /// 가입하고 바로 다시 로그인한 사람을 가입으로 두 번 세지 않는다.
  static bool looksLikeSignUp(DateTime? createdAt, {DateTime? now}) {
    if (createdAt == null) return false;
    final elapsed = (now ?? DateTime.now()).difference(createdAt);
    return !elapsed.isNegative && elapsed < const Duration(minutes: 10);
  }

  /// 로그인과 상관없는 앱 설정을 유저 속성으로 남긴다. 값이 null 이면 지운다.
  ///
  /// 지금 쓰는 테마처럼 기기에 저장되는 값이라 [identify] 와 따로 둔다.
  static void setUserProperty(String name, String? value) {
    try {
      _set(name, value).catchError((Object error) {
        debugPrint('[AppAnalytics] $name 속성 저장 실패: $error');
      });
    } catch (error) {
      debugPrint('[AppAnalytics] $name 속성 저장 실패: $error');
    }
  }

  /// 하단 탭이 아닌 화면에 들어왔음을 남긴다. 화면의 `initState` 에서 부른다.
  ///
  /// 화면 이동에 이름을 주지 않아서 `FirebaseAnalyticsObserver` 가 하위 화면을
  /// 하나도 기록하지 못했다. 들어오는 경로가 여러 곳이라 이동마다 이름을
  /// 다는 대신 화면 쪽에서 한 번 남긴다.
  static void logScreenView(String screenName) {
    try {
      FirebaseAnalytics.instance
          .logScreenView(screenName: screenName, screenClass: screenName)
          .catchError((Object error) {
        debugPrint('[AppAnalytics] 화면 기록 실패: $error');
      });
    } catch (error) {
      debugPrint('[AppAnalytics] 화면 기록 실패: $error');
    }
  }

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
