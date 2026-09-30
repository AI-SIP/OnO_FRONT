import SwiftUI

/// 소형: 프로필과 연속 일수, 이번 주 한 줄, 맨 아래 오늘 복습 수. 누르면 전체가 복습 예정 화면으로 간다.
struct SmallWidgetView: View {
  let state: WidgetState
  let profile: UIImage?

  var body: some View {
    Group {
      if state.loggedIn {
        loggedInBody
      } else {
        loggedOutBody
      }
    }
    .padding(EdgeInsets(top: 16, leading: 14, bottom: 12, trailing: 14))
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var loggedInBody: some View {
    let palette = state.palette
    return VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 10) {
        ProfileSticker(image: profile, size: 46)
        VStack(alignment: .leading, spacing: 2) {
          HandText("\(state.streak)일째", size: 30, color: palette.ink, minimumScale: 0.5)
          HandText("연속으로 공부 중", size: 14, color: palette.inkSoft)
        }
      }
      WeekDots(cells: state.cells(weeks: 1), palette: palette)
        .padding(.top, 12)
      Spacer(minLength: 4)
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        HighlightText(text: state.shortDueText, size: 17, palette: palette)
          .layoutPriority(1)
        if state.dueCount > 0 && state.overdueCount > 0 {
          HandText("밀린 \(state.overdueCount)", size: 13, color: palette.overdue)
        }
      }
    }
  }

  private var loggedOutBody: some View {
    VStack(spacing: 8) {
      BareFrog()
        .frame(width: 56, height: 56)
        .rotationEffect(.degrees(-6))
      Text(state.emptyMessageSmall)
        .font(WidgetFont.hand(15))
        .foregroundColor(state.palette.ink)
        .multilineTextAlignment(.center)
        .lineSpacing(3)
        .minimumScaleFactor(0.7)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
