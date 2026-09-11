/// 레벨마다 그림이 통째로 바뀌던 시절의 개구리 에셋 경로다.
///
/// **임시다.** 개구리가 `BASE` 한 장에 치장 파츠를 겹치는 방식으로 바뀌면서
/// 이 규칙은 `FrogCharacter` 에서 빠졌다. 그런데 레벨업 연출(`MissionLevelUp`)은
/// 아직 옛 그림 두 장을 겹쳐 놓고 진화를 보여 주고 있어서, 그 화면이 새로
/// 쓰이기 전까지 컴파일이 되도록 규칙만 여기로 옮겨 둔 것이다.
///
/// 레벨업 연출이 `CosmeticProvider.layersAtLevel` 로 다시 쓰이면 이 파일과
/// `assets/FrogCharacter/FROG_LEVEL*.png` 는 함께 지운다.
abstract final class LegacyFrogAsset {
  /// 그 레벨의 개구리 그림 경로.
  static String pathOf(int level) {
    if (level >= 15) return 'assets/FrogCharacter/FROG_LEVEL15.png';
    if (level >= 13) return 'assets/FrogCharacter/FROG_LEVEL13.png';
    if (level >= 11) return 'assets/FrogCharacter/FROG_LEVEL11.png';
    if (level >= 9) return 'assets/FrogCharacter/FROG_LEVEL9.png';
    if (level >= 7) return 'assets/FrogCharacter/FROG_LEVEL7.png';
    if (level >= 5) return 'assets/FrogCharacter/FROG_LEVEL5.png';
    if (level >= 3) return 'assets/FrogCharacter/FROG_LEVEL3.png';
    return 'assets/FrogCharacter/FROG_LEVEL1.png';
  }

  /// [from] 에서 [to] 로 오를 때 그림이 실제로 바뀌는지.
  static bool evolvesBetween(int from, int to) => pathOf(from) != pathOf(to);
}
