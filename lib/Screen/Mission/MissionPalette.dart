import 'package:flutter/material.dart';

/// 미션의 갈래다. 무엇을 하는 미션인지로 나눈다.
///
/// 목록이 흰 카드에 같은 색 아이콘 타일만 반복되면 어느 미션이 어떤 종류인지
/// 눈으로 구분되지 않는다. 갈래마다 색을 달리해서 스크롤하다가도 "복습 쪽"
/// "출석 쪽"이 색으로 먼저 읽히게 한다.
enum MissionKind {
  /// 오답노트 등록, 기록 남기기.
  record,

  /// 문제 복습.
  review,

  /// 정답률, 정확도.
  accuracy,

  /// 출석과 연속.
  attendance,

  /// 복습 세트 완주.
  practiceSet,

  /// 그 밖의 것. 서버가 새 미션을 추가했을 때 여기로 떨어진다.
  etc,
}

/// 갈래 하나의 색 한 벌.
class MissionKindColors {
  /// 아이콘 타일의 바탕. 아주 옅게 깐다.
  final Color surface;

  /// 아이콘과 진행바에 쓰는 진한 톤.
  final Color accent;

  const MissionKindColors({required this.surface, required this.accent});
}

/// 미션 갈래의 색이다.
///
/// **테마색과 역할을 나눈다.** 사용자가 고르는 테마는 24색이라, 갈래 색까지
/// 테마를 따라가면 색이 서로 싸우거나 어떤 테마에서는 구분이 사라진다. 그래서
/// 갈래 색은 채도를 낮춘 고정 팔레트로 두고, 테마색은 히어로의 링 게이지처럼
/// "지금 이 사람의 색"이 필요한 자리에만 쓴다. 보상의 금색도 마찬가지로 고정이다.
abstract final class MissionPalette {
  static const Map<MissionKind, MissionKindColors> _colors = {
    // 파랑 계열. 쓰는 일이라 차분하게.
    MissionKind.record: MissionKindColors(
      surface: Color(0xFFEDF2FB),
      accent: Color(0xFF4F6DA8),
    ),
    // 청록 계열. 되돌아보는 일.
    MissionKind.review: MissionKindColors(
      surface: Color(0xFFE7F3F1),
      accent: Color(0xFF3D857B),
    ),
    // 산호 계열. 맞히는 일이라 조금 뜨겁게.
    MissionKind.accuracy: MissionKindColors(
      surface: Color(0xFFFBEDEC),
      accent: Color(0xFFB86258),
    ),
    // 보라 계열. 날마다 쌓이는 일. 금색과 섞이지 않게 골랐다.
    MissionKind.attendance: MissionKindColors(
      surface: Color(0xFFF2EEFA),
      accent: Color(0xFF7059A6),
    ),
    // 초록 계열. 끝까지 가는 일.
    MissionKind.practiceSet: MissionKindColors(
      surface: Color(0xFFEDF4EA),
      accent: Color(0xFF578A4B),
    ),
    // 중성. 모르는 미션.
    MissionKind.etc: MissionKindColors(
      surface: Color(0xFFF0F2F4),
      accent: Color(0xFF6B7684),
    ),
  };

  /// 미션 코드로 갈래를 정한다. 코드를 모르면 아이콘 키로 본다.
  static MissionKind kindOf({String? code, String? iconKey}) {
    final byCode = _kindByCode[code];
    if (byCode != null) return byCode;
    return _kindByIconKey[iconKey] ?? MissionKind.etc;
  }

  static MissionKindColors colorsOf({String? code, String? iconKey}) {
    return _colors[kindOf(code: code, iconKey: iconKey)]!;
  }

  static MissionKindColors of(MissionKind kind) => _colors[kind]!;

  static const Map<String, MissionKind> _kindByCode = {
    'DAILY_NOTE_WRITE': MissionKind.record,
    'WEEKLY_NOTE_10': MissionKind.record,
    'DAILY_REVIEW_3': MissionKind.review,
    'WEEKLY_REVIEW_30': MissionKind.review,
    'DAILY_CORRECT_3': MissionKind.accuracy,
    'DAILY_ATTEND': MissionKind.attendance,
    'WEEKLY_ATTEND_5': MissionKind.attendance,
    'DAILY_PRACTICE_SET': MissionKind.practiceSet,
    'WEEKLY_SET_3': MissionKind.practiceSet,
    'DAILY_MOOD': MissionKind.etc,
  };

  static const Map<String, MissionKind> _kindByIconKey = {
    'note_write': MissionKind.record,
    'reflection': MissionKind.record,
    'photo': MissionKind.record,
    'tag': MissionKind.record,
    'review': MissionKind.review,
    'revenge': MissionKind.review,
    'overdue': MissionKind.review,
    'accuracy': MissionKind.accuracy,
    'master': MissionKind.accuracy,
    'attendance': MissionKind.attendance,
    'streak': MissionKind.attendance,
    'dawn': MissionKind.attendance,
    'night': MissionKind.attendance,
    'practice_set': MissionKind.practiceSet,
    'cleanup': MissionKind.practiceSet,
  };
}
