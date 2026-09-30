import 'dart:convert';

/// 홈 화면 위젯에 넘기는 스냅샷 한 장.
///
/// 키 이름과 모양은 `docs/홈 화면 위젯/위젯_데이터_계약.md` 에 적힌 그대로다.
/// iOS 위젯과 Android 위젯이 이 JSON 을 따로 읽기 때문에 **필드 이름을 한 글자도
/// 바꾸면 안 된다.** 바꿔야 하면 세 쪽을 같이 고친다.
class HomeWidgetSnapshot {
  /// 공유 저장소에 스냅샷을 저장하는 키. JSON 문자열 하나로 둔다.
  ///
  /// 키를 여러 개로 나누면 위젯이 쓰다 만 값을 읽을 수 있다.
  static const String storageKey = 'ono_widget_snapshot';

  /// 스키마 버전. 위젯은 자기가 아는 값보다 크면 로그아웃 화면을 보여 준다.
  static const int schemaVersion = 1;

  final bool loggedIn;

  /// 아래는 전부 [loggedIn] 이 true 일 때만 쓴다.
  final String? generatedAt;
  final String? today;
  final String? themeColor;
  final int currentStreak;
  final int thisMonthStudyDays;
  final String? lastStudiedDate;
  final int dueCount;
  final int overdueCount;
  final List<HomeWidgetRecommendation> recommendations;
  final List<HomeWidgetDay> days;
  final int profileVersion;

  const HomeWidgetSnapshot({
    required String this.generatedAt,
    required String this.today,
    required String this.themeColor,
    required this.currentStreak,
    required this.thisMonthStudyDays,
    required this.lastStudiedDate,
    required this.dueCount,
    required this.overdueCount,
    required this.recommendations,
    required this.days,
    required this.profileVersion,
  }) : loggedIn = true;

  /// 로그아웃 상태. `{ "v": 1, "loggedIn": false }` 만 남는다.
  ///
  /// 키를 지우지 않고 이것으로 덮어쓴다. 지우면 위젯이 "앱을 한 번도 안 연
  /// 상태"와 구분할 수 없다.
  const HomeWidgetSnapshot.loggedOut()
      : loggedIn = false,
        generatedAt = null,
        today = null,
        themeColor = null,
        currentStreak = 0,
        thisMonthStudyDays = 0,
        lastStudiedDate = null,
        dueCount = 0,
        overdueCount = 0,
        recommendations = const [],
        days = const [],
        profileVersion = 0;

  Map<String, dynamic> toJson() {
    if (!loggedIn) {
      return <String, dynamic>{'v': schemaVersion, 'loggedIn': false};
    }
    return <String, dynamic>{
      'v': schemaVersion,
      'loggedIn': true,
      'generatedAt': generatedAt,
      'today': today,
      'themeColor': themeColor,
      'currentStreak': currentStreak,
      'thisMonthStudyDays': thisMonthStudyDays,
      'lastStudiedDate': lastStudiedDate,
      'dueCount': dueCount,
      'overdueCount': overdueCount,
      'recommendations': [for (final r in recommendations) r.toJson()],
      'days': [for (final d in days) d.toJson()],
      'profileVersion': profileVersion,
    };
  }

  String encode() => jsonEncode(toJson());
}

/// 대형 위젯 아래쪽에 적는 추천 복습 문제 한 줄.
class HomeWidgetRecommendation {
  final int problemId;
  final String title;

  /// 오늘까지 며칠 밀렸는지. 0 이면 오늘 복습할 문제다.
  final int overdueDays;

  const HomeWidgetRecommendation({
    required this.problemId,
    required this.title,
    required this.overdueDays,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'problemId': problemId,
        'title': title,
        'overdueDays': overdueDays,
      };
}

/// 학습 달력 한 칸.
class HomeWidgetDay {
  /// `yyyy-MM-dd`.
  final String date;

  /// 앱 달력과 같은 `DailyStudyRecord.intensityLevel` (0~3).
  final int level;

  const HomeWidgetDay({required this.date, required this.level});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': date,
        'level': level,
      };
}
