import 'AchievementModel.dart';

/// `GET /api/achievements` 의 응답 전체다.
///
/// **열두 개가 전부 온다.** 받은 것과 못 받은 것이 섞여 있고, 못 받은 것에도
/// 이름과 설명과 진행도가 실려 온다. 무엇이 기다리고 있는지 보여야 갖고
/// 싶어지기 때문이다.
class AchievementBoardModel {
  /// 훈장 전부. **서버가 준 순서를 그대로 들고 있는다.**
  ///
  /// 화면도 이 순서로 그린다. 정렬하지 않는다. 무엇을 먼저 보여 줄지는
  /// 훈장표(`docs/훈장/훈장표.md`)의 순서고 그것을 서버가 내려준다. 앱이 다시
  /// 정렬하면 문서를 고쳐도 화면이 안 따라온다.
  final List<AchievementModel> achievements;

  /// **이번 호출에서 처음 채워진** 훈장의 key 들. 없으면 빈 목록이다.
  ///
  /// 이 값은 이 응답 한 번에만 실려 온다. 다음에 다시 물으면 그 훈장은 그냥
  /// `earned: true` 일 뿐 새 것이 아니다. 그래서 받은 쪽([AchievementProvider])
  /// 이 이것을 **쌓아 두고 기기에 적어 둔다.** 자세한 이유는 그쪽에 적었다.
  final List<String> newlyEarned;

  const AchievementBoardModel({
    required this.achievements,
    required this.newlyEarned,
  });

  /// 아직 한 번도 못 받았을 때의 빈 훈장판.
  static const AchievementBoardModel empty = AchievementBoardModel(
    achievements: [],
    newlyEarned: [],
  );

  /// 못 읽으면 null 이다.
  ///
  /// `achievements` 가 목록이 아니면 훈장판으로 치지 않는다. 빈 목록으로
  /// 떨어뜨리면 화면이 "훈장이 하나도 없어요"를 조용히 그려서, 통신이 깨진
  /// 것과 정말로 비어 있는 것이 구분되지 않는다.
  static AchievementBoardModel? fromJsonOrNull(Object? json) {
    if (json is! Map) return null;

    final raw = json['achievements'];
    if (raw is! List) return null;

    return AchievementBoardModel(
      achievements: [
        for (final entry in raw)
          if (AchievementModel.fromJsonOrNull(entry) case final item?) item,
      ],
      newlyEarned: _keysFrom(json['newlyEarned']),
    );
  }

  static List<String> _keysFrom(Object? json) {
    if (json is! List) return const [];
    return [
      for (final entry in json)
        if (entry is String && entry.isNotEmpty) entry,
    ];
  }

  int get total => achievements.length;

  int get earnedCount {
    var count = 0;
    for (final item in achievements) {
      if (item.earned) count++;
    }
    return count;
  }

  /// key 로 훈장을 찾는다. 없으면 null 이다.
  AchievementModel? of(String key) {
    for (final item in achievements) {
      if (item.key == key) return item;
    }
    return null;
  }
}
