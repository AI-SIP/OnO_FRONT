import SwiftUI

/// 대형: 위에 프로필과 연속 일수, 가운데 최근 5주 달력, 점선 아래 오늘 복습 머리줄과 추천 3개.
/// 달력(과 나머지 빈 곳)은 widgetURL 로 학습 달력, 머리줄은 복습 예정, 추천 줄은 그 문제로 간다.
struct LargeWidgetView: View {
  let state: WidgetState
  let profile: UIImage?

  /// 추천 한 줄 높이와 줄 수. 아래 칸 높이를 고정해 두고 남는 높이를 달력이 쓴다.
  private let rowHeight: CGFloat = 27
  private let rowCount = 3

  var body: some View {
    let palette = state.palette
    VStack(alignment: .leading, spacing: 0) {
      header
        .frame(height: 50)
      CalendarColumn(
        state: state, weeks: 5, rowGap: 3, designCell: 22, designFont: 13,
        titleGap: 3, headerGap: 4, headerSize: 11
      )
      .padding(.top, 8)
      DashedRule()
        .padding(.top, 10)
      Group {
        if state.loggedIn {
          reviewSection(palette: palette)
        } else {
          Color.clear
        }
      }
      .frame(height: 7 + 20 + 4 + rowHeight * CGFloat(rowCount), alignment: .top)
    }
    .padding(EdgeInsets(top: 16, leading: 16, bottom: 12, trailing: 16))
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  @ViewBuilder private var header: some View {
    let palette = state.palette
    HStack(spacing: 12) {
      if state.loggedIn {
        ProfileSticker(image: profile, size: 50)
        VStack(alignment: .leading, spacing: 3) {
          InkText("\(state.streak)일째 공부 중", font: WidgetFont.hand(28), color: palette.ink, minimumScale: 0.5)
          InkText(
            "이번 달엔 \(state.monthStudyDays)일 공부했어요", font: WidgetFont.text(12, .medium),
            color: palette.inkSoft)
        }
      } else {
        BareFrog()
          .frame(width: 50, height: 50)
          .rotationEffect(.degrees(-6))
        InkText(state.emptyMessage, font: WidgetFont.text(13, .medium), color: palette.ink)
      }
      Spacer(minLength: 0)
    }
  }

  private func reviewSection(palette: WidgetPalette) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Link(destination: DeepLink.reviewDue(size: "large")) {
        HStack(alignment: .firstTextBaseline) {
          HighlightText(text: dueTitle, size: 14, palette: palette)
            .layoutPriority(1)
          Spacer(minLength: 6)
          if state.dueCount > 0 && state.overdueCount > 0 {
            InkText("밀린 문제 \(state.overdueCount)개", font: WidgetFont.digits(11), color: palette.inkSoft)
          }
        }
        .frame(height: 20)
      }
      .padding(.top, 7)

      if state.dueCount == 0 || state.recommendations.isEmpty {
        InkText("내일 복습할 문제는 내일 알려 줄게요", font: WidgetFont.text(13, .medium), color: palette.ink)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        VStack(spacing: 0) {
          ForEach(state.recommendations, id: \.problemId) { item in
            Link(destination: DeepLink.problem(id: item.problemId)) {
              RecommendationRow(item: item, palette: palette)
                .frame(height: rowHeight)
            }
          }
        }
        .padding(.top, 4)
      }
    }
  }

  private var dueTitle: String {
    if state.dueCount == 0 {
      return state.stale ? "복습 끝! (어제)" : "오늘 복습 끝!"
    }
    return state.stale ? "복습할 문제 \(state.dueCount)개 (어제)" : "오늘 복습할 문제 \(state.dueCount)개"
  }
}

private struct RecommendationRow: View {
  let item: WidgetSnapshot.Recommendation
  let palette: WidgetPalette

  var body: some View {
    HStack(spacing: 8) {
      RoundedRectangle(cornerRadius: 3)
        .strokeBorder(palette.inkSoft, lineWidth: 1.5)
        .frame(width: 12, height: 12)
      // 제목은 줄이지 않고 한 줄 말줄임. 길이가 제각각이라 줄이면 줄마다 글자 크기가 달라 보인다.
      Text(item.title)
        .font(WidgetFont.text(13))
        .foregroundColor(palette.ink)
        .lineLimit(1)
        .truncationMode(.tail)
        .frame(maxWidth: .infinity, alignment: .leading)
      if item.overdueDays > 0 {
        InkText("\(item.overdueDays)일 밀림", font: WidgetFont.digits(11), color: palette.overdue)
          .fixedSize()
      } else {
        InkText("오늘", font: WidgetFont.text(11, .medium), color: palette.inkSoft)
          .fixedSize()
      }
    }
    .frame(maxHeight: .infinity)
    .overlay(
      Rectangle()
        .fill(Paper.rule)
        .frame(height: 1),
      alignment: .bottom
    )
  }
}

/// 달력과 복습 칸을 나누는 1.5pt 점선.
private struct DashedRule: View {
  var body: some View {
    GeometryReader { geometry in
      Path { path in
        path.move(to: CGPoint(x: 0, y: 0.75))
        path.addLine(to: CGPoint(x: geometry.size.width, y: 0.75))
      }
      .stroke(Paper.dashed, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
    }
    .frame(height: 1.5)
  }
}
