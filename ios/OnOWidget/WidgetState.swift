import Foundation

/// 달력 한 칸.
struct DayCell: Identifiable {
  let id: Int
  let day: Int
  /// 0~3. 0 이면 칠하지 않는다.
  let level: Int
  let isToday: Bool
  let isFuture: Bool
  /// 지난달 날짜와 아직 안 온 날은 숫자를 흐리게 적는다.
  let isFaint: Bool
}

/// 스냅샷을 "위젯이 그려지는 순간의 오늘" 기준으로 풀어 놓은 값.
/// 자정 엔트리도 같은 스냅샷을 쓰기 때문에 날짜가 바뀌었을 때 규칙(계약서 「오늘과 날짜가 바뀐 경우」)이 여기 모여 있다.
struct WidgetState {
  let loggedIn: Bool
  /// 앱이 쓴 로그아웃 스냅샷(`loggedIn: false`)을 읽었는지. loggedIn 이 false 인데 이것도 false 면
  /// 스냅샷이 아직 없거나(위젯만 새로 둔 경우) 깨졌거나 모르는 버전이다. 안내 문구만 다르다.
  let signedOut: Bool
  let palette: WidgetPalette
  /// 스냅샷을 만든 날보다 오늘이 뒤. 앱을 안 열고 자정을 넘긴 경우다.
  let stale: Bool
  let streak: Int
  let monthStudyDays: Int
  let dueCount: Int
  let overdueCount: Int
  let recommendations: [WidgetSnapshot.Recommendation]
  let monthTitle: String

  private let today: Date
  private let snapshotDay: Date?
  private let levels: [String: Int]

  /// 기본 테마 색. 로그아웃이면 사용자 테마를 모르니 앱 기본 분홍으로 그린다.
  static let defaultThemeHex = "#F48FB1"

  init(snapshot: WidgetSnapshot?, now: Date) {
    let calendar = WidgetDates.calendar
    today = calendar.startOfDay(for: now)
    monthTitle = "\(calendar.component(.month, from: today))월"

    guard let snapshot,
      snapshot.v <= WidgetContract.supportedVersion,
      snapshot.loggedIn,
      let snapshotToday = snapshot.today.flatMap(WidgetDates.parse)
    else {
      loggedIn = false
      if let snapshot, (1...WidgetContract.supportedVersion).contains(snapshot.v), !snapshot.loggedIn {
        signedOut = true
      } else {
        signedOut = false
      }
      palette = WidgetPalette(hex: WidgetState.defaultThemeHex)
      stale = false
      streak = 0
      monthStudyDays = 0
      dueCount = 0
      overdueCount = 0
      recommendations = []
      snapshotDay = nil
      levels = [:]
      return
    }

    loggedIn = true
    signedOut = false
    palette = WidgetPalette(hex: snapshot.themeColor ?? WidgetState.defaultThemeHex)
    snapshotDay = snapshotToday
    stale = today > snapshotToday

    // 서버 연속 일수는 "마지막 공부한 날이 어제 이후면 이어진다"는 규칙이라 위젯도 같은 비교로 끊는다.
    // 스냅샷 날에 공부했으면 다음 날까지 이어지고, 안 했으면 다음 날엔 0 이 된다.
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
    if let last = snapshot.lastStudiedDate.flatMap(WidgetDates.parse), last >= yesterday {
      streak = max(0, snapshot.currentStreak ?? 0)
    } else {
      streak = 0
    }

    // thisMonthStudyDays 는 스냅샷 날이 속한 달의 값이다. 앱을 안 열고 달이 넘어갔으면
    // 새 달에 공부한 기록은 아직 모르니 0 으로 둔다.
    if calendar.isDate(snapshotToday, equalTo: today, toGranularity: .month) {
      monthStudyDays = max(0, snapshot.thisMonthStudyDays ?? 0)
    } else {
      monthStudyDays = 0
    }

    dueCount = max(0, snapshot.dueCount ?? 0)
    overdueCount = max(0, snapshot.overdueCount ?? 0)
    recommendations = Array((snapshot.recommendations ?? []).prefix(3))

    var map: [String: Int] = [:]
    for day in snapshot.days ?? [] {
      map[day.date] = min(3, max(0, day.level))
    }
    levels = map
  }

  /// 오늘이 속한 주가 맨 아래 줄인 `weeks` 주짜리 달력. 한 주는 일요일부터 시작한다.
  func cells(weeks: Int) -> [DayCell] {
    let calendar = WidgetDates.calendar
    let weekday = calendar.component(.weekday, from: today)  // 1 = 일요일
    guard
      let thisSunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: today),
      let start = calendar.date(byAdding: .day, value: -7 * (weeks - 1), to: thisSunday)
    else { return [] }

    let todayMonth = calendar.component(.month, from: today)
    return (0..<(weeks * 7)).compactMap { index in
      guard let date = calendar.date(byAdding: .day, value: index, to: start) else { return nil }
      let isFuture = date > today
      var level = 0
      // 스냅샷 날 뒤의 칸은 앱이 아직 모르는 날이라 비워 둔다.
      if loggedIn, !isFuture, let snapshotDay, date <= snapshotDay {
        level = levels[WidgetDates.format(date)] ?? 0
      }
      let otherMonth = calendar.component(.month, from: date) != todayMonth
      return DayCell(
        id: index,
        day: calendar.component(.day, from: date),
        level: level,
        // 로그아웃 화면은 누구의 오늘도 아니라 테두리를 두지 않는다.
        isToday: loggedIn && calendar.isDate(date, inSameDayAs: today),
        isFuture: isFuture,
        isFaint: otherMonth || isFuture
      )
    }
  }
}

/// 날짜는 전부 기기 현지 날짜로 다룬다. 스냅샷의 today 도 앱이 기기 날짜로 만든다.
enum WidgetDates {
  static var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
  }

  private static var formatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }

  static func parse(_ text: String) -> Date? {
    formatter.date(from: text).map { calendar.startOfDay(for: $0) }
  }

  static func format(_ date: Date) -> String {
    formatter.string(from: date)
  }

  static func nextMidnight(after date: Date) -> Date {
    let calendar = calendar
    let start = calendar.startOfDay(for: date)
    return calendar.date(byAdding: .day, value: 1, to: start) ?? date.addingTimeInterval(86_400)
  }
}
