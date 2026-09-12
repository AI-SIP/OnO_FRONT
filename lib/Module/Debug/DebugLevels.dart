import 'package:flutter/foundation.dart';

import '../../Model/Cosmetic/CosmeticAbilityLevels.dart';
import '../../Model/User/UserInfoModel.dart';

/// **디버그 전용.** 시안에서 사람이 옮겨 놓은 능력치 레벨을 **앱 전체가 함께
/// 보는 자리**다.
///
/// 그전에는 출처가 둘이었다. 꾸미기 화면의 디버그 패널은 `CosmeticProvider`
/// 안의 레벨을 바꾸는데, 테마 해금은 `ThemeLockManager` 가 `UserInfoModel` 의
/// 능력치 넷을 읽는다. 그 값은 `UserProvider` 에서 온다. 그래서 디버그로
/// 레벨을 올려도 **테마는 진짜 레벨을 봤다.** 옷장은 Lv.15 인데 테마는 Lv.3
/// 이라고 말하는 화면이 둘 생긴 것이다.
///
/// 레벨을 여기 한 곳에 두고, `UserProvider` 가 `userInfoModel` 을 **내주는
/// 자리에서** 갈아 끼운다. 그러면 레벨을 읽는 화면 전부가 따라온다. 테마
/// 다이얼로그, 옷장 탭 스탯창, 꾸미기 해금 판정, 마이페이지가 같은 값을 말한다.
///
/// 지키는 것 셋이다.
///
/// 1. **`kDebugMode` 에서만 돈다.** [levels] 가 릴리즈에서 늘 null 이고
///    [applyTo] 가 받은 것을 그대로 돌려주므로, 컴파일러가 이 경로를 통째로
///    걷어낸다.
/// 2. **한 번도 안 옮겼으면 진짜 값 그대로다.** 옮기기 전에는 null 이다.
///    `CosmeticProvider` 가 이미 그 규칙을 쓰고 있어서 같은 규칙을 쓴다.
/// 3. **서버가 준 것을 덮어쓰지 않는다.** [applyTo] 는 원본을 건드리지 않고
///    레벨만 갈아 낀 **사본**을 만든다. `UserProvider` 가 들고 있는 것은
///    서버가 준 그대로라, 로그인이나 재조회가 이 값에 오염되지 않는다.
abstract final class DebugLevels {
  /// 사람이 옮겨 놓은 레벨. 한 번도 안 옮겼으면 null 이다.
  ///
  /// [ValueNotifier] 인 것은 `UserProvider` 가 이 값이 바뀔 때 제 화면들을
  /// 다시 그려야 하기 때문이다. 디버그 패널은 `CosmeticProvider` 를 부르는데,
  /// 테마 다이얼로그는 `UserProvider` 를 보고 있어서 그쪽이 따로 알아야 한다.
  static final ValueNotifier<CosmeticAbilityLevels?> _levels =
      ValueNotifier<CosmeticAbilityLevels?>(null);

  /// 값이 바뀔 때 알려 준다.
  static Listenable get listenable => _levels;

  /// 지금 옮겨 놓은 레벨. **릴리즈에서는 언제나 null 이다.**
  static CosmeticAbilityLevels? get levels => kDebugMode ? _levels.value : null;

  /// 디버그 패널을 한 번이라도 만졌는지.
  static bool get isTouched => levels != null;

  /// 레벨을 옮긴다. 디버그 패널만 부른다.
  static void override(CosmeticAbilityLevels next) {
    if (!kDebugMode) return;
    _levels.value = next;
  }

  /// 옮겨 놓은 것을 지운다. 로그아웃과 테스트 준비가 부른다.
  static void reset() {
    if (!kDebugMode) return;
    _levels.value = null;
  }

  /// 유저 정보에 옮겨 놓은 레벨을 갈아 낀 **사본**.
  ///
  /// 안 옮겼으면 [info] 를 그대로 돌려준다. 원본은 절대 건드리지 않는다.
  ///
  /// 경험치 점수는 능력치 넷의 것을 그대로 둔다. 디버그 패널이 옮기는 것은
  /// 레벨뿐이라 점수까지 지어내면 `24 / 100` 처럼 진짜와 가짜가 섞인 줄이
  /// 나온다. 총 학습만 문턱과 점수를 함께 지어내는데, 그러지 않으면 Lv.20 에
  /// `24 / 60` 같은 줄이 나와 막대가 아예 안 움직인다.
  static UserInfoModel? applyTo(UserInfoModel? info) {
    if (!kDebugMode) return info;

    final override = levels;
    if (override == null || info == null) return info;

    final threshold = totalStudyThreshold(override.totalStudy);

    return UserInfoModel(
      userId: info.userId,
      email: info.email,
      name: info.name,
      profileImageUrl: info.profileImageUrl,
      createdAt: info.createdAt,
      updatedAt: info.updatedAt,
      attendanceLevel: override.attendance,
      attendancePoint: info.attendancePoint,
      noteWriteLevel: override.noteWrite,
      noteWritePoint: info.noteWritePoint,
      problemPracticeLevel: override.problemPractice,
      problemPracticePoint: info.problemPracticePoint,
      notePracticeLevel: override.notePractice,
      notePracticePoint: info.notePracticePoint,
      totalStudyLevel: override.totalStudy,
      totalStudyCurrentPoint: totalStudyPoint(override.totalStudy),
      totalStudyNextLevelThreshold: threshold,
      notificationEnabled: info.notificationEnabled,
    );
  }

  /// **시안 전용.** 그 총 학습 레벨에서 다음 레벨까지 필요한 경험치.
  ///
  /// 백엔드가 확정한 식이 `40 × 레벨` 이고 상한은
  /// [CosmeticAbilityLevels.maxTotalStudy] 다. **서버가 붙으면 서버가 내려준
  /// `totalStudyNextLevelThreshold` 가 이긴다.** 여기 있는 것은 디버그 패널로
  /// 레벨을 옮겨 볼 때 막대가 빈 채로 남지 않게 하려는 더미일 뿐이다.
  static int totalStudyThreshold(int level) => 40 * level;

  /// **시안 전용.** 그 레벨에서 지금까지 모은 경험치.
  ///
  /// 레벨을 옮길 때마다 막대가 다르게 차야 게이지가 어떻게 보이는지 한 번에
  /// 훑을 수 있다. 5분의 1씩 네 칸을 돈다. 끝까지 올라간 뒤에는 더 갈 곳이
  /// 없으니 꽉 채운다. 이것도 서버가 붙으면 `totalStudyCurrentPoint` 가 이긴다.
  static int totalStudyPoint(int level) {
    final threshold = totalStudyThreshold(level);
    if (level >= CosmeticAbilityLevels.maxTotalStudy) return threshold;
    return (threshold * ((level % 4) + 1) / 5).round();
  }
}
