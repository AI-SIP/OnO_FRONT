import 'package:flutter/material.dart';

/// 미션을 끝내면 오르는 능력치다.
///
/// 임의로 나눈 갈래가 아니라 **마이페이지의 활동별 레벨 네 가지와 같은 것**이다.
/// 미션마다 어떤 능력치가 오르는지는 서버의 `MissionMetric` 이 이미 들고 있고,
/// 앱은 그 능력치의 색을 그대로 쓴다. 그러면 색이 장식이 아니라 정보가 된다.
/// 카드 색만 보고 "이건 복습 경험치구나"를 알 수 있어야 한다.
enum MissionKind {
  /// 출석. 오늘 앱을 켜는 것, 기분을 남기는 것.
  attendance,

  /// 오답노트 작성.
  noteWrite,

  /// 문제 복습. 복습 횟수와 정답률.
  problemPractice,

  /// 복습 세트 완주.
  notePractice,

  /// 어느 능력치인지 모르는 것. 서버가 새 미션을 추가했을 때 여기로 떨어진다.
  etc,
}

/// 갈래 하나의 색 한 벌.
class MissionKindColors {
  /// 아이콘 타일과 진행바 바탕. 아주 옅게 깐다.
  final Color surface;

  /// 아이콘, 진행바 채움, 능력치 이름에 쓰는 색.
  final Color accent;

  const MissionKindColors({required this.surface, required this.accent});
}

/// 미션 색이다.
///
/// **마이페이지 활동별 레벨(`UserLevelCard`)과 같은 색을 쓴다.** 두 화면이 같은
/// 것을 다른 색으로 부르면 색이 정보를 잃는다. 그래서 그쪽도 이 파일에서 색을
/// 가져간다.
///
/// 색은 탁하지 않게 둔다. 채도를 낮추는 대신 명도를 올린 파스텔이라, 흰 바탕과
/// 부드러운 초록을 쓰는 이 앱의 다른 화면 옆에 놓아도 겉돌지 않는다.
abstract final class MissionPalette {
  static const Map<MissionKind, MissionKindColors> _colors = {
    // 분홍. 마이페이지 출석 줄과 같다.
    MissionKind.attendance: MissionKindColors(
      surface: Color(0xFFFDEDF3),
      accent: Color(0xFFF06292),
    ),
    // 보라. 마이페이지 오답노트 작성 줄과 같다.
    MissionKind.noteWrite: MissionKindColors(
      surface: Color(0xFFF6EDFA),
      accent: Color(0xFFBA68C8),
    ),
    // 초록. 마이페이지 문제 복습 줄과 같다.
    MissionKind.problemPractice: MissionKindColors(
      surface: Color(0xFFEAF6EB),
      accent: Color(0xFF66BB6A),
    ),
    // 파랑. 마이페이지 복습 세트 줄과 같다.
    MissionKind.notePractice: MissionKindColors(
      surface: Color(0xFFE9F3FD),
      accent: Color(0xFF64B5F6),
    ),
    // 중성. 모르는 미션.
    MissionKind.etc: MissionKindColors(
      surface: Color(0xFFF1F4F6),
      accent: Color(0xFF90A4AE),
    ),
  };

  /// 능력치 이름. 카드에 작게 붙여 색이 무엇을 뜻하는지 말로도 알린다.
  static const Map<MissionKind, String> _labels = {
    MissionKind.attendance: '출석',
    MissionKind.noteWrite: '오답노트',
    MissionKind.problemPractice: '문제 복습',
    MissionKind.notePractice: '복습 세트',
    MissionKind.etc: '',
  };

  /// 미션 코드로 어떤 능력치가 오르는지 정한다.
  ///
  /// 서버 응답에 능력치가 들어 있지 않아서 1차에는 코드로 판정한다. 나중에
  /// 서버가 능력치를 함께 내려주면 [_kindByCode] 를 지우고 그 값을 그대로
  /// 쓰면 된다. 판정이 이 파일 한 곳에만 있는 이유다.
  static MissionKind kindOf({String? code, String? iconKey}) {
    final byCode = _kindByCode[code];
    if (byCode != null) return byCode;
    return _kindByIconKey[iconKey] ?? MissionKind.etc;
  }

  static MissionKindColors colorsOf({String? code, String? iconKey}) {
    return _colors[kindOf(code: code, iconKey: iconKey)]!;
  }

  static MissionKindColors of(MissionKind kind) => _colors[kind]!;

  /// 이 미션이 올리는 능력치의 이름. 모르면 빈 문자열이다.
  static String labelOf({String? code, String? iconKey}) {
    return _labels[kindOf(code: code, iconKey: iconKey)]!;
  }

  static String labelOfKind(MissionKind kind) => _labels[kind]!;

  /// 받을 수 있는 카드의 바탕. 사용자가 고른 테마색을 아주 옅게 깐다.
  ///
  /// 예전에는 금색이었는데 누렇고 촌스러웠다. 보상 색을 따로 만들지 않고
  /// 테마색을 쓰면 어떤 테마에서도 앱의 다른 화면과 같은 결로 보인다.
  static Color claimableSurface(Color primary) =>
      Color.alphaBlend(primary.withValues(alpha: 0.10), Colors.white);

  /// 받을 수 있는 카드의 테두리.
  static Color claimableBorder(Color primary) =>
      primary.withValues(alpha: 0.45);

  static const Map<String, MissionKind> _kindByCode = {
    'DAILY_ATTEND': MissionKind.attendance,
    'WEEKLY_ATTEND_5': MissionKind.attendance,
    'DAILY_MOOD': MissionKind.attendance,
    'DAILY_NOTE_WRITE': MissionKind.noteWrite,
    'WEEKLY_NOTE_10': MissionKind.noteWrite,
    'DAILY_REVIEW_3': MissionKind.problemPractice,
    'DAILY_CORRECT_3': MissionKind.problemPractice,
    'WEEKLY_REVIEW_30': MissionKind.problemPractice,
    'DAILY_PRACTICE_SET': MissionKind.notePractice,
    'WEEKLY_SET_3': MissionKind.notePractice,
  };

  /// 코드를 모를 때의 차선책이다.
  static const Map<String, MissionKind> _kindByIconKey = {
    'attendance': MissionKind.attendance,
    'streak': MissionKind.attendance,
    'dawn': MissionKind.attendance,
    'night': MissionKind.attendance,
    'mood': MissionKind.attendance,
    'note_write': MissionKind.noteWrite,
    'reflection': MissionKind.noteWrite,
    'photo': MissionKind.noteWrite,
    'tag': MissionKind.noteWrite,
    'review': MissionKind.problemPractice,
    'revenge': MissionKind.problemPractice,
    'overdue': MissionKind.problemPractice,
    'accuracy': MissionKind.problemPractice,
    'master': MissionKind.problemPractice,
    'practice_set': MissionKind.notePractice,
    'cleanup': MissionKind.notePractice,
  };
}
