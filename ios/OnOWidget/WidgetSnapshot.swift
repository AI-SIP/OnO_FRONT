import Foundation
import ImageIO
import UIKit

// 앱과 위젯이 같이 지키는 이름. 값은 docs/홈 화면 위젯/위젯_데이터_계약.md 와 한 글자도 다르면 안 된다.
enum WidgetContract {
  static let appGroup = "group.com.aisip.OnO"
  static let kind = "OnOStudyWidget"
  static let snapshotKey = "ono_widget_snapshot"
  static let profileKey = "ono_widget_profile"
  /// 위젯이 읽을 줄 아는 스냅샷 버전. 이보다 큰 값이 오면 모르는 모양이라 스냅샷이 없는 것과 같은 안내 화면으로 둔다.
  static let supportedVersion = 1
}

/// 앱이 App Group UserDefaults 에 JSON 문자열로 써 두는 스냅샷 (계약서 「스냅샷 JSON (v1)」).
/// 로그아웃 스냅샷은 v 와 loggedIn 만 있어서 나머지는 전부 옵셔널로 받는다.
struct WidgetSnapshot: Decodable {
  struct Recommendation: Decodable {
    let problemId: Int
    let title: String
    let overdueDays: Int
  }

  struct DayLevel: Decodable {
    let date: String
    let level: Int
  }

  let v: Int
  let loggedIn: Bool
  let today: String?
  let themeColor: String?
  let currentStreak: Int?
  let thisMonthStudyDays: Int?
  let lastStudiedDate: String?
  let dueCount: Int?
  let overdueCount: Int?
  let recommendations: [Recommendation]?
  let days: [DayLevel]?
  let profileVersion: Int?
}

/// 공유 저장소에서 스냅샷과 프로필 그림을 읽는다. 위젯은 서버도 토큰도 모르고 이것만 본다.
enum WidgetStore {
  static func loadSnapshot() -> WidgetSnapshot? {
    guard let defaults = UserDefaults(suiteName: WidgetContract.appGroup) else { return nil }
    // home_widget 은 Dart String 을 그대로 setValue 한다. 혹시 바이트로 들어와도 읽히게 둘 다 받는다.
    let raw = defaults.object(forKey: WidgetContract.snapshotKey)
    let data: Data?
    if let text = raw as? String {
      data = text.data(using: .utf8)
    } else {
      data = raw as? Data
    }
    guard let data else { return nil }
    return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
  }

  /// renderFlutterWidget 이 저장한 프로필 PNG.
  /// home_widget 은 `{App Group 폴더}/home_widget/ono_widget_profile.png` 에 쓰고 그 절대 경로를 키에 넣는다.
  /// 저장된 경로에 파일이 없으면(컨테이너 경로가 바뀐 경우 등) 같은 규칙으로 한 번 더 찾는다.
  static func loadProfileImage(maxPixel: CGFloat) -> UIImage? {
    let defaults = UserDefaults(suiteName: WidgetContract.appGroup)
    var candidates: [URL] = []
    if let path = defaults?.string(forKey: WidgetContract.profileKey), !path.isEmpty {
      candidates.append(URL(fileURLWithPath: path))
    }
    if let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: WidgetContract.appGroup)
    {
      candidates.append(
        container.appendingPathComponent("home_widget/\(WidgetContract.profileKey).png"))
    }
    for url in candidates where FileManager.default.fileExists(atPath: url.path) {
      if let image = downsample(url: url, maxPixel: maxPixel) { return image }
    }
    return nil
  }

  /// 위젯 확장은 메모리 한도가 30MB 안팎이라 원본(88pt x3 = 264px)을 통째로 풀지 않고
  /// 그릴 크기만큼만 줄여서 디코드한다.
  private static func downsample(url: URL, maxPixel: CGFloat) -> UIImage? {
    let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }
    let options =
      [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: max(1, Int(maxPixel)),
      ] as CFDictionary
    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
    return UIImage(cgImage: cgImage)
  }
}
