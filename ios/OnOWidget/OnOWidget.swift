import SwiftUI
import WidgetKit

struct StudyEntry: TimelineEntry {
  let date: Date
  let state: WidgetState
  let profile: UIImage?
}

/// 앱이 HomeWidget.updateWidget 을 부를 때와 자정에만 다시 그린다.
/// 위젯이 서버를 부르지 않기 때문에 그 사이에 새로 알 수 있는 값이 없다.
struct StudyProvider: TimelineProvider {
  /// 프로필은 최대 50pt 로 그린다. 3배 화면 기준으로 넉넉히 잡은 디코드 크기.
  private static let profilePixel: CGFloat = 180

  func placeholder(in context: Context) -> StudyEntry {
    StudyEntry(date: Date(), state: WidgetState(snapshot: nil, now: Date()), profile: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (StudyEntry) -> Void) {
    completion(makeEntry(at: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<StudyEntry>) -> Void) {
    let now = Date()
    let midnight = WidgetDates.nextMidnight(after: now)
    // 자정 엔트리는 같은 스냅샷을 새 날짜로 푼다. 앱을 안 열어도 오늘 칸과 연속 일수가 넘어간다.
    let entries = [makeEntry(at: now), makeEntry(at: midnight)]
    completion(Timeline(entries: entries, policy: .after(midnight)))
  }

  private func makeEntry(at date: Date) -> StudyEntry {
    let state = WidgetState(snapshot: WidgetStore.loadSnapshot(), now: date)
    // 로그아웃이면 앞 사용자 그림이 남아 있어도 읽지 않는다.
    let profile =
      state.loggedIn ? WidgetStore.loadProfileImage(maxPixel: StudyProvider.profilePixel) : nil
    return StudyEntry(date: date, state: state, profile: profile)
  }
}

struct StudyWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: StudyEntry

  var body: some View {
    content
      .widgetBackground(PaperBackground(family: family, palette: entry.state.palette))
      .widgetURL(DeepLink.widgetURL(for: family))
  }

  @ViewBuilder private var content: some View {
    switch family {
    case .systemMedium:
      MediumWidgetView(state: entry.state, profile: entry.profile)
    case .systemLarge:
      LargeWidgetView(state: entry.state, profile: entry.profile)
    default:
      SmallWidgetView(state: entry.state, profile: entry.profile)
    }
  }
}

@main
struct OnOStudyWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetContract.kind, provider: StudyProvider()) { entry in
      StudyWidgetView(entry: entry)
    }
    .configurationDisplayName("OnO 학습 기록")
    .description("연속 학습과 오늘 복습할 문제를 보여 줘요")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .disableContentMarginsIfAvailable()
  }
}

// MARK: - iOS 17 대응

extension View {
  /// iOS 17 부터는 containerBackground 를 쓰지 않으면 위젯 자리에 채택하라는 안내 문구가 뜬다.
  /// 15, 16 에서는 그 API 가 없어서 배경을 직접 깔고 여백도 직접 준다.
  @ViewBuilder
  func widgetBackground<Background: View>(_ background: Background) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { background }
    } else {
      self.background(background)
    }
  }
}

extension WidgetConfiguration {
  /// iOS 17 은 기본 여백을 한 번 더 넣어서 시안 여백(위 16, 좌우 16/14, 아래 12)보다 안쪽으로 밀린다.
  /// 여백은 뷰에서 직접 주고 있으니 시스템 여백은 끈다.
  func disableContentMarginsIfAvailable() -> some WidgetConfiguration {
    if #available(iOSApplicationExtension 17.0, *) {
      return self.contentMarginsDisabled()
    } else {
      return self
    }
  }
}
