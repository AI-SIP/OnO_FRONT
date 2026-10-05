import SwiftUI

/// 중형: 왼쪽에 프로필과 연속 일수, 오른쪽에 최근 4주 달력. 누르면 전체가 학습 달력으로 간다.
/// 5주를 넣으면 줄 사이가 좁아 빽빽해 보여서 4주만 둔다.
struct MediumWidgetView: View {
  let state: WidgetState
  let profile: UIImage?

  var body: some View {
    HStack(alignment: .top, spacing: 16) {
      leftColumn
        .frame(width: 118, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
      CalendarColumn(state: state, weeks: 4, rowGap: 5, designCell: 20, designFont: 12)
    }
    .padding(EdgeInsets(top: 16, leading: 16, bottom: 12, trailing: 16))
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  @ViewBuilder private var leftColumn: some View {
    let palette = state.palette
    if state.loggedIn {
      VStack(alignment: .leading, spacing: 0) {
        ProfileSticker(image: profile, size: 50)
        InkText("\(state.streak)일째", font: WidgetFont.hand(32), color: palette.ink, minimumScale: 0.5)
          .padding(.top, 8)
        InkText("연속으로 공부 중", font: WidgetFont.text(12, .medium), color: palette.inkSoft)
          .padding(.top, 2)
        Spacer(minLength: 4)
        HighlightText(text: state.shortDueText, size: 14, palette: palette)
      }
    } else {
      VStack(alignment: .leading, spacing: 10) {
        BareFrog()
          .frame(width: 50, height: 50)
          .rotationEffect(.degrees(-6))
        Text(state.emptyMessage)
          .font(WidgetFont.text(13, .medium))
          .foregroundColor(palette.ink)
          .lineSpacing(3)
          .minimumScaleFactor(0.7)
      }
    }
  }
}

/// `9월` 제목, 요일 머리줄, 달력. 중형 오른쪽과 대형 가운데가 같이 쓴다.
struct CalendarColumn: View {
  let state: WidgetState
  let weeks: Int
  let rowGap: CGFloat
  let designCell: CGFloat
  let designFont: CGFloat
  var titleGap: CGFloat = 4
  var headerGap: CGFloat = 5
  /// 요일 글자 크기. 중형 10, 대형 11. 줄 높이는 12 그대로다.
  var headerSize: CGFloat = 10

  var body: some View {
    let palette = state.palette
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        InkText(state.monthTitle, font: WidgetFont.hand(19), color: palette.ink)
        if state.stale {
          InkText("어제까지 기록", font: WidgetFont.text(10, .medium), color: palette.inkSoft)
        }
      }
      .frame(height: 20, alignment: .bottomLeading)
      WeekdayHeader(color: palette.inkSoft, size: headerSize)
        .frame(height: 12)
        .padding(.top, titleGap)
      StudyCalendarGrid(
        cells: state.cells(weeks: weeks), palette: palette, rowGap: rowGap,
        designCell: designCell, designFont: designFont
      )
      .padding(.top, headerGap)
    }
  }
}
