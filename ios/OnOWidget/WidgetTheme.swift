import SwiftUI
import UIKit

/// 일기장 종이 재료. 앱 학습 달력 일기장(DiaryPage.dart)의 종이, 테두리, 줄과 같은 계열이다.
enum Paper {
  static let background = Color(hex: 0xFFFCF5)
  static let edge = Color(hex: 0xF0E7D6)
  static let rule = Color(hex: 0xF1E9D8)
  /// 소형과 중형 바탕의 공책 줄. 글자와 겹쳐 지저분해 보여서 줄 색을 반만 칠한다.
  static let notebookRule = rule.opacity(0.5)
  static let dashed = Color(hex: 0xE6DAC3)
  static let emptyDot = Color(hex: 0xE3D7C0)
  static let ruleSpacing: CGFloat = 22
  static let cornerRadius: CGFloat = 22
}

/// 글씨 색은 검정과 회색 대신 테마 색에서 뽑은 잉크를 쓴다. 테마가 24가지라 색을 고정해 두면
/// 파스텔 테마와 어울리지 않아서, 색상(hue)은 그대로 두고 채도와 밝기만 내린다.
/// 본문과 보조 잉크는 어느 테마에서도 종이와 대비가 4.5:1 이상 나오게 밝기를 잡는다.
struct WidgetPalette {
  let theme: Color
  let ink: Color
  let inkSoft: Color
  let inkFaint: Color
  /// 밀린 문제만 테라코타색. 어떤 테마 색에도 묻히지 않게 테마와 상관없이 고정이다.
  let overdue = Color(hue: 18, saturation: 0.5, lightness: 0.44)
  /// 칠한 동그라미 위에서 잉크 숫자가 안 읽히는 단계. 블랙, 딥인디고 같은 진한 테마에서
  /// 55%, 85% 칸이 잉크와 거의 같은 색이 돼서 그 칸만 흰 숫자로 바꾼다.
  let whiteTextLevels: Set<Int>

  private let themeRGB: RGB

  init(hex: String) {
    let rgb = RGB(hex: hex) ?? RGB(hex: WidgetState.defaultThemeHex)!
    themeRGB = rgb
    theme = rgb.color
    let hsl = rgb.hsl
    let inkRGB = RGB(hue: hsl.h, saturation: min(hsl.s, 0.5), lightness: 0.30)
    ink = inkRGB.color
    inkSoft = WidgetPalette.softInk(hue: hsl.h, saturation: min(hsl.s, 0.35)).color
    inkFaint = RGB(hue: hsl.h, saturation: min(hsl.s, 0.30), lightness: 0.48).color.opacity(0.45)

    // 종이 위에 테마 색을 덮은 색과 잉크의 대비가 3:1 도 안 되고 흰 글씨가 더 잘 읽히면 흰 글씨로 쓴다.
    let paper = WidgetPalette.paperRGB
    let white = RGB(r: 1, g: 1, b: 1)
    var levels = Set<Int>()
    for (level, alpha) in [(1, 0.30), (2, 0.55), (3, 0.85)] {
      let cell = rgb.blended(over: paper, alpha: alpha)
      let inkContrast = cell.contrast(with: inkRGB)
      if inkContrast < 3 && cell.contrast(with: white) > inkContrast {
        levels.insert(level)
      }
    }
    whiteTextLevels = levels
  }

  static let paperRGB = RGB(r: 1, g: 0.988, b: 0.961)

  /// 보조 잉크. 밝기 0.45 에서 시작해 종이와 대비가 4.5:1 이 될 때까지 0.01 씩 내린다.
  /// 노랑, 연두처럼 밝은 색상(hue)만 조금 더 진해지고 나머지 테마는 0.45 그대로다.
  static func softInk(hue: Double, saturation: Double) -> RGB {
    var lightness = 0.45
    while lightness > 0.30 {
      let candidate = RGB(hue: hue, saturation: saturation, lightness: lightness)
      if candidate.contrast(with: paperRGB) >= 4.5 { return candidate }
      lightness -= 0.01
    }
    return RGB(hue: hue, saturation: saturation, lightness: 0.30)
  }

  /// 공부한 날 동그라미. level 1~3 을 테마 색 30%, 55%, 85% 로 칠한다.
  func fill(level: Int) -> Color {
    switch level {
    case 1: return theme.opacity(0.30)
    case 2: return theme.opacity(0.55)
    case 3: return theme.opacity(0.85)
    default: return .clear
    }
  }

  var tape: Color { theme.opacity(0.30) }
  var highlighter: Color { theme.opacity(0.40) }
}

/// 손글씨는 연속 일수 큰 줄과 달력 월 제목 두 곳에만 쓴다. 문장, 요일, 날짜 숫자까지 손글씨로 쓰면
/// 작은 글자가 뭉개져 읽기 어려워서 나머지는 전부 시스템 둥근 글꼴이다.
/// 시스템 글꼴은 같은 pt 에서 손글씨보다 커 보여서 손글씨 자리보다 2~3pt 작게 쓴다(계약서 「크기별 내용」).
enum WidgetFont {
  /// Info.plist UIAppFonts 에 등록된 손글씨 서브셋 폰트의 PostScript 이름.
  static let postScriptName = "Ownglyph_ryurue-Rg"

  static func hand(_ size: CGFloat) -> Font {
    .custom(postScriptName, fixedSize: size)
  }

  static func text(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
    .system(size: size, weight: weight, design: .rounded)
  }

  /// 숫자가 들어간 글자. 자릿수마다 폭이 같아 달력 칸과 숫자가 흔들리지 않는다.
  static func digits(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
    text(size, weight).monospacedDigit()
  }
}

// MARK: - 색 계산

struct RGB {
  let r: Double
  let g: Double
  let b: Double

  init(r: Double, g: Double, b: Double) {
    self.r = r
    self.g = g
    self.b = b
  }

  init?(hex: String) {
    var text = hex.trimmingCharacters(in: .whitespaces)
    if text.hasPrefix("#") { text.removeFirst() }
    if text.count == 8 { text = String(text.suffix(6)) }  // AARRGGBB 로 와도 색만 쓴다
    guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
    r = Double((value >> 16) & 0xFF) / 255
    g = Double((value >> 8) & 0xFF) / 255
    b = Double(value & 0xFF) / 255
  }

  /// hue 는 도(0~360), 나머지는 0~1. CSS hsl() 과 같은 식이다.
  init(hue: Double, saturation s: Double, lightness l: Double) {
    let h = (hue.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) / 360
    if s == 0 {
      self.init(r: l, g: l, b: l)
      return
    }
    let q = l < 0.5 ? l * (1 + s) : l + s - l * s
    let p = 2 * l - q
    func channel(_ t0: Double) -> Double {
      var t = t0
      if t < 0 { t += 1 }
      if t > 1 { t -= 1 }
      if t < 1.0 / 6 { return p + (q - p) * 6 * t }
      if t < 1.0 / 2 { return q }
      if t < 2.0 / 3 { return p + (q - p) * (2.0 / 3 - t) * 6 }
      return p
    }
    self.init(r: channel(h + 1.0 / 3), g: channel(h), b: channel(h - 1.0 / 3))
  }

  var hsl: (h: Double, s: Double, l: Double) {
    let maxV = max(r, g, b)
    let minV = min(r, g, b)
    let l = (maxV + minV) / 2
    if maxV == minV { return (0, 0, l) }
    let d = maxV - minV
    let s = l > 0.5 ? d / (2 - maxV - minV) : d / (maxV + minV)
    var h: Double
    if maxV == r {
      h = (g - b) / d + (g < b ? 6 : 0)
    } else if maxV == g {
      h = (b - r) / d + 2
    } else {
      h = (r - g) / d + 4
    }
    h *= 60
    return (h, s, l)
  }

  var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: 1) }

  func blended(over base: RGB, alpha: Double) -> RGB {
    RGB(
      r: r * alpha + base.r * (1 - alpha),
      g: g * alpha + base.g * (1 - alpha),
      b: b * alpha + base.b * (1 - alpha))
  }

  private var luminance: Double {
    func linear(_ c: Double) -> Double {
      c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
  }

  func contrast(with other: RGB) -> Double {
    let a = luminance
    let b = other.luminance
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)
  }
}

extension Color {
  init(hex: UInt32) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: 1)
  }

  init(hue: Double, saturation: Double, lightness: Double) {
    self = RGB(hue: hue, saturation: saturation, lightness: lightness).color
  }
}
