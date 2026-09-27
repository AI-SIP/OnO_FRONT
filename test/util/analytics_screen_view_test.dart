import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 앱의 모든 화면이 들어올 때 Analytics 에 화면 조회를 남기는지 잠가 둔다.
///
/// 화면 이동에 이름을 주지 않아서 FirebaseAnalyticsObserver 는 하위 화면을
/// 하나도 남기지 못한다. 그래서 화면마다 initState 에서
/// `AppAnalytics.logScreenView` 를 부르는데, 새 화면을 만들 때 빠뜨리면 그
/// 화면은 콘솔에서 보이지 않는다 (#275).
void main() {
  /// 일부러 화면 조회를 남기지 않는 화면과 그 이유.
  const excluded = {
    // 하단 탭. 탭을 누를 때 ScreenIndexProvider 가 남긴다.
    'DirectoryScreen': '하단 탭',
    'PracticeThumbnailScreen': '하단 탭',
    'CharacterScreen': '하단 탭',
    'StudyRoomListScreen': '하단 탭',
    'SettingScreen': '하단 탭',
    // StatelessWidget 이라 여는 쪽(PracticeDetailLoader, 알림)이 대신 남긴다.
    'PracticeDetailScreen': '여는 쪽이 남김',
    // 운영에서 열리지 않는 화면.
    'CosmeticCombinationPreviewScreen': '디버그 전용',
    'TemplateSelectionScreen': '여는 곳 없음',
    'ColorPickerScreen': '여는 곳 없음',
    'CoordinatePickerScreen': '여는 곳 없음',
    'AnswerShareScreen': '여는 곳 없음',
    'ProblemShareScreen': '여는 곳 없음',
  };

  final screenClass = RegExp(
    r'^class (_?\w+Screen) extends State(?:ful|less)Widget',
    multiLine: true,
  );

  Map<String, String> collectScreens() {
    final screens = <String, String>{};
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final match in screenClass.allMatches(source)) {
        screens[match.group(1)!] = source;
      }
    }
    return screens;
  }

  test('화면 클래스를 찾는다', () {
    // 정규식이 어긋나 아무것도 못 찾으면 아래 검사가 그냥 통과한다.
    expect(collectScreens().length, greaterThan(30));
  });

  test('모든 화면이 화면 조회를 남긴다', () {
    final missing = [
      for (final MapEntry(key: name, value: source) in collectScreens().entries)
        if (!excluded.containsKey(name) &&
            !source.contains('AppAnalytics.logScreenView('))
          name,
    ];

    expect(
      missing,
      isEmpty,
      reason: 'initState 에서 AppAnalytics.logScreenView 를 부르거나, '
          '일부러 빼는 화면이면 excluded 에 이유와 함께 적는다',
    );
  });

  test('빼 둔 화면이 아직 있다', () {
    // 화면을 지웠는데 목록에만 남아 있으면 목록이 거짓말을 한다.
    final screens = collectScreens();
    final stale = excluded.keys.where((name) => !screens.containsKey(name));

    expect(stale, isEmpty);
  });
}
