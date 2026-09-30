import SwiftUI
import WidgetKit

// MARK: - 딥링크

/// 계약서 「딥링크」의 주소. home_widget iOS 플러그인은 쿼리에 `homeWidget` 이 있는 주소만
/// 위젯 탭으로 알아채서(HomeWidgetPlugin.isWidgetUrl) Dart 의 widgetClicked 로 넘기므로 꼭 붙인다.
enum DeepLink {
  static func reviewDue(size: String) -> URL {
    URL(string: "onowidget://review-due?homeWidget&size=\(size)")!
  }

  static func calendar(size: String) -> URL {
    URL(string: "onowidget://calendar?homeWidget&size=\(size)")!
  }

  static func problem(id: Int) -> URL {
    URL(string: "onowidget://problem/\(id)?homeWidget&size=large")!
  }

  /// 위젯 전체를 눌렀을 때. 대형은 복습 머리줄과 추천 줄이 Link 로 따로 가고, 나머지(달력 포함)는 달력으로 간다.
  static func widgetURL(for family: WidgetFamily) -> URL {
    switch family {
    case .systemMedium: return calendar(size: "medium")
    case .systemLarge: return calendar(size: "large")
    default: return reviewDue(size: "small")
    }
  }
}

// MARK: - 종이

/// 일기장 한 쪽. 종이 배경, 테두리, 공책 줄(소형과 중형만), 위쪽 가운데 마스킹테이프.
struct PaperBackground: View {
  let family: WidgetFamily
  let palette: WidgetPalette

  var body: some View {
    ZStack(alignment: .top) {
      Paper.background
      // 대형은 달력과 줄이 겹쳐 어지러워서 줄을 긋지 않는다.
      if family != .systemLarge {
        NotebookRules()
      }
      RoundedRectangle(cornerRadius: Paper.cornerRadius, style: .continuous)
        .strokeBorder(Paper.edge, lineWidth: 1)
      MaskingTape(width: tapeWidth, angle: family == .systemSmall ? -4 : -3, color: palette.tape)
    }
  }

  private var tapeWidth: CGFloat {
    switch family {
    case .systemSmall: return 60
    case .systemMedium: return 68
    default: return 72
    }
  }
}

private struct NotebookRules: View {
  var body: some View {
    GeometryReader { geometry in
      Path { path in
        // 시안은 22px 마다 맨 아래 1px 을 줄로 칠한다. 줄 가운데가 21.5 에 오게 긋는다.
        var y = Paper.ruleSpacing - 0.5
        while y < geometry.size.height {
          path.move(to: CGPoint(x: 0, y: y))
          path.addLine(to: CGPoint(x: geometry.size.width, y: y))
          y += Paper.ruleSpacing
        }
      }
      .stroke(Paper.rule, lineWidth: 1)
    }
  }
}

private struct MaskingTape: View {
  let width: CGFloat
  let angle: Double
  let color: Color

  var body: some View {
    RoundedRectangle(cornerRadius: 2)
      .fill(color)
      .frame(width: width, height: 16)
      .rotationEffect(.degrees(angle))
      // 종이 위쪽 모서리에 걸쳐 붙인 모양이라 6pt 를 위로 내민다. 넘친 부분은 위젯 모양에 잘린다.
      .offset(y: -6)
  }
}

// MARK: - 글씨

struct HandText: View {
  let text: String
  let size: CGFloat
  let color: Color
  var minimumScale: CGFloat = 0.6

  init(_ text: String, size: CGFloat, color: Color, minimumScale: CGFloat = 0.6) {
    self.text = text
    self.size = size
    self.color = color
    self.minimumScale = minimumScale
  }

  var body: some View {
    // 글자는 줄여서라도 한 줄에 둔다(명세서 「UI 반응형 고려사항」).
    Text(text)
      .font(WidgetFont.hand(size))
      .foregroundColor(color)
      .lineLimit(1)
      .minimumScaleFactor(minimumScale)
  }
}

/// 형광펜을 칠한 글씨. 글자 아래 45% 높이에 테마 색 40% 띠를 깐다.
struct HighlightText: View {
  let text: String
  let size: CGFloat
  let palette: WidgetPalette

  var body: some View {
    HandText(text, size: size, color: palette.ink, minimumScale: 0.7)
      .padding(.horizontal, 2)
      .background(
        GeometryReader { geometry in
          VStack(spacing: 0) {
            Spacer(minLength: 0)
            Rectangle()
              .fill(palette.highlighter)
              .frame(height: geometry.size.height * 0.45)
          }
        }
      )
  }
}

// MARK: - 프로필

/// 스티커처럼 -6도 기울인 프로필. 앱이 찍어 준 ProfileAvatar PNG 를 그대로 붙이고,
/// 그림이 없으면(아직 안 찍었거나 로그아웃) 번들에 넣어 둔 맨 개구리 얼굴을 흰 원에 넣는다.
struct ProfileSticker: View {
  let image: UIImage?
  let size: CGFloat

  var body: some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .interpolation(.high)
          .scaledToFit()
      } else {
        BareFrog()
      }
    }
    .frame(width: size, height: size)
    .rotationEffect(.degrees(-6))
  }
}

struct BareFrog: View {
  var body: some View {
    Image("FrogFace")
      .resizable()
      .interpolation(.high)
      .scaledToFill()
      .background(Color.white)
      .clipShape(Circle())
      .overlay(Circle().strokeBorder(Paper.edge, lineWidth: 1.5))
  }
}

// MARK: - 달력

/// 요일 머리줄. 일요일부터 시작한다.
struct WeekdayHeader: View {
  let color: Color
  var size: CGFloat = 12

  static let labels = ["일", "월", "화", "수", "목", "금", "토"]

  var body: some View {
    HStack(spacing: 0) {
      ForEach(WeekdayHeader.labels, id: \.self) { label in
        HandText(label, size: size, color: color)
          .frame(maxWidth: .infinity)
      }
    }
  }
}

/// 가로 한 줄이 한 주인 달력. 칸 크기는 폭(7열 균등)과 높이(줄 수) 중 작은 쪽에 맞춘다.
/// 태블릿처럼 자리가 크면 칸과 숫자가 같이 커지고, 숫자가 9pt 보다 작아지면 숫자를 빼고 색만 남긴다.
struct StudyCalendarGrid: View {
  let cells: [DayCell]
  let palette: WidgetPalette
  let rowGap: CGFloat
  /// 시안의 칸 크기와 숫자 크기. 숫자는 칸에 비례해서 키우고 줄인다.
  let designCell: CGFloat
  let designFont: CGFloat

  private var rows: Int { max(1, cells.count / 7) }

  var body: some View {
    GeometryReader { geometry in
      let columnWidth = geometry.size.width / 7
      let rowHeight = (geometry.size.height - rowGap * CGFloat(rows - 1)) / CGFloat(rows)
      let cell = max(0, floor(min(columnWidth, rowHeight)))
      let fontSize = cell * designFont / designCell
      let showNumbers = fontSize >= 9

      VStack(spacing: rowGap) {
        ForEach(0..<rows, id: \.self) { row in
          HStack(spacing: 0) {
            ForEach(cells[(row * 7)..<(row * 7 + 7)]) { item in
              DayCircle(
                cell: item, palette: palette, size: cell, fontSize: fontSize,
                showNumber: showNumbers
              )
              .frame(maxWidth: .infinity)
            }
          }
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
    }
  }
}

private struct DayCircle: View {
  let cell: DayCell
  let palette: WidgetPalette
  let size: CGFloat
  let fontSize: CGFloat
  let showNumber: Bool

  var body: some View {
    ZStack {
      // 공부한 날만 칠한다. 안 한 날까지 빈 원을 그리면 글자와 점이 빽빽해 보였다.
      Circle().fill(palette.fill(level: cell.level))
      if cell.isToday {
        // 오늘은 글자로 적지 않고 잉크 테두리로만 표시한다.
        Circle().strokeBorder(palette.ink, lineWidth: 1.5)
      }
      if showNumber {
        Text("\(cell.day)")
          .font(WidgetFont.hand(fontSize))
          .foregroundColor(numberColor)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
          // 손글씨 폰트 숫자가 살짝 위로 떠 보여서 시안처럼 1pt 내린다.
          .padding(.top, 1)
      }
    }
    .frame(width: size, height: size)
  }

  private var numberColor: Color {
    if palette.whiteTextLevels.contains(cell.level) {
      // 진한 칸 위의 지난달 날짜는 흐린 잉크가 묻혀서 흰색을 옅게 쓴다.
      return cell.isFaint ? Color.white.opacity(0.7) : .white
    }
    return cell.isFaint ? palette.inkFaint : palette.ink
  }
}

/// 소형의 이번 주 한 줄. 요일 글자 아래 지름 15 점을 둔다.
struct WeekDots: View {
  let cells: [DayCell]
  let palette: WidgetPalette

  var body: some View {
    HStack(spacing: 0) {
      ForEach(cells) { cell in
        VStack(spacing: 3) {
          HandText(WeekdayHeader.labels[cell.id % 7], size: 12, color: palette.inkSoft)
          dot(for: cell)
            .frame(width: 15, height: 15)
        }
        .frame(maxWidth: .infinity)
      }
    }
  }

  @ViewBuilder
  private func dot(for cell: DayCell) -> some View {
    ZStack {
      if cell.level > 0 {
        Circle().fill(palette.fill(level: cell.level))
      } else if !cell.isToday {
        // 공부 안 한 지난 날과 아직 안 온 날은 점선 원.
        Circle()
          .strokeBorder(
            Paper.emptyDot,
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.1, 3]))
      }
      if cell.isToday {
        Circle().strokeBorder(palette.ink, lineWidth: 1.5)
      }
    }
  }
}

// MARK: - 문구

extension WidgetState {
  /// 소형과 중형의 형광펜 복습 문구. 앱을 안 열고 날이 바뀌었으면 어제 값이라고 붙인다.
  var shortDueText: String {
    if dueCount == 0 {
      return stale ? "복습 끝! (어제)" : "오늘 복습 끝!"
    }
    return stale ? "복습 \(dueCount)문제 (어제)" : "오늘 복습 \(dueCount)문제"
  }

  static let loggedOutMessage = "OnO 에 로그인하면 여기에 기록이 적혀요"
  static let loggedOutMessageSmall = "OnO 에 로그인하면\n여기에 기록이 적혀요"
  /// 스냅샷이 아직 없을 때(위젯을 새로 두고 앱을 아직 안 연 경우), 깨졌을 때, 모르는 버전일 때.
  static let noSnapshotMessage = "OnO 를 열면 여기에 기록이 적혀요"
  static let noSnapshotMessageSmall = "OnO 를 열면\n여기에 기록이 적혀요"

  /// 기록 대신 보여 줄 안내 문구. 로그아웃이면 로그인하라고, 스냅샷이 없으면 앱을 열라고 적는다.
  var emptyMessage: String {
    signedOut ? WidgetState.loggedOutMessage : WidgetState.noSnapshotMessage
  }

  /// 소형은 폭이 좁아 두 줄로 끊는다.
  var emptyMessageSmall: String {
    signedOut ? WidgetState.loggedOutMessageSmall : WidgetState.noSnapshotMessageSmall
  }
}
