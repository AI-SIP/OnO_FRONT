import 'package:ono/Model/Achievement/AchievementBoardModel.dart';
import 'package:ono/Model/Achievement/AchievementModel.dart';
import 'package:ono/Provider/AchievementCelebrationStore.dart';
import 'package:ono/Provider/AchievementProvider.dart';
import 'package:ono/Service/Api/Achievement/AchievementService.dart';

import 'fixtures.dart';

/// 훈장 **계약 픽스처**다. `GET /api/achievements` 가 내려줄 것을 그대로 적어 둔다.
///
/// 앱에는 훈장 목록이 박혀 있지 않다. 열두 개의 key·이름·설명은 전부 서버가
/// 주고, 그 서버 시드는 `docs/훈장/훈장표.md` 에서 나온다. 그래서 **앱 쪽에서
/// 문서와 맞대 볼 수 있는 유일한 것이 이 픽스처**다. 어긋나지 않는지는
/// `test/screen/achievement/achievement_table_test.dart` 가 문서를 직접 읽어
/// 잠근다. 배치를 바꿀 일이 생기면 문서를 먼저 고친다.
///
/// **표를 Dart 로 다시 옮겨 적지 않는다.** 응답 JSON 파일
/// (`test/fixtures/achievement/*.json`)을 그대로 읽는다. Dart 리터럴로 적으면
/// 프론트가 지금 믿고 있는 것을 다시 적는 셈이라, 백엔드가 실제 응답에서 떠낸
/// 것과 나란히 놓고 diff 할 수 없다.
class AchievementMockData {
  const AchievementMockData._();

  /// 열두 개가 전부 담긴 응답. 껍데기까지 포함한 본문이다.
  static const String fullFixture =
      'achievement/get_achievements_response.json';

  /// 새로 받은 것이 없는 응답. `newlyEarned` 가 빈 배열인 모양을 잠근다.
  static const String noNewsFixture =
      'achievement/get_achievements_no_news_response.json';

  /// 껍데기를 벗긴 `data` 부분.
  static Map<String, dynamic> payload([String fixture = fullFixture]) {
    return loadJsonFixture(fixture)['data'] as Map<String, dynamic>;
  }

  /// 파싱까지 끝낸 훈장판.
  static AchievementBoardModel board([String fixture = fullFixture]) {
    return AchievementBoardModel.fromJsonOrNull(payload(fixture)) ??
        AchievementBoardModel.empty;
  }

  /// 열두 개 목록.
  static List<AchievementModel> get achievements => board().achievements;

  /// 서버가 준 순서 그대로의 key 목록.
  static List<String> get keys => [for (final item in achievements) item.key];

  /// 진행도를 안 내려주는 훈장들. 문서의 `## 진행도` 절이 말하는 그 둘이다.
  static Set<String> get keysWithoutProgress => {
        for (final item in achievements)
          if (item.current == null && item.target == null) item.key,
      };
}

/// 가짜 훈장 서버.
///
/// 서버가 들고 있는 훈장판과 이번에 새로 채워진 것을 테스트가 직접 정한다.
class FakeAchievementService implements AchievementService {
  FakeAchievementService({
    AchievementBoardModel? board,
    this.failLoad = false,
  }) : board = board ?? AchievementMockData.board();

  /// 서버가 들고 있는 훈장판.
  AchievementBoardModel board;

  /// 조회가 실패하는지. 404 나 연결 끊김을 흉내 낸다.
  bool failLoad;

  /// 조회가 몇 번 나갔는지.
  int loadCount = 0;

  /// **두 번째 조회부터 `newlyEarned` 를 비운다.**
  ///
  /// 진짜 서버가 그렇다. 새로 받은 것은 그 응답 한 번에만 실린다. 이걸 끄면
  /// 조회할 때마다 같은 축하가 실려 와서, 축하를 쌓아 두는 쪽의 버그가 안 드러난다.
  bool newsOnlyOnce = true;

  @override
  Future<AchievementBoardModel?> getAchievements() async {
    loadCount++;
    if (failLoad) return null;

    if (newsOnlyOnce && loadCount > 1) {
      return AchievementBoardModel(
        achievements: board.achievements,
        newlyEarned: const [],
      );
    }
    return board;
  }
}

/// 기기 저장소를 대신하는 가짜. 메모리에만 들고 있는다.
///
/// `SharedPreferences` 는 테스트에서 플랫폼 채널을 타므로 그대로 쓰면 예외가
/// 난다(진짜 구현은 그 예외를 삼키지만, 그러면 무엇이 적혔는지 볼 수 없다).
class FakeAchievementCelebrationStore implements AchievementCelebrationStore {
  FakeAchievementCelebrationStore([Set<String>? initial])
      : stored = {...?initial};

  Set<String> stored;

  /// 몇 번 썼는지. 축하가 실제로 기기에 적혔는지 잠그는 데 쓴다.
  int writeCount = 0;

  @override
  Future<Set<String>> read() async => {...stored};

  @override
  Future<void> write(Set<String> keys) async {
    writeCount++;
    stored = {...keys};
  }
}

/// 한 번 받아 둔 훈장 프로바이더.
Future<AchievementProvider> loadedAchievementProvider({
  FakeAchievementService? service,
  FakeAchievementCelebrationStore? store,
}) async {
  final provider = AchievementProvider(
    service: service ?? FakeAchievementService(),
    store: store ?? FakeAchievementCelebrationStore(),
  );
  await provider.load();
  return provider;
}
