import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticAbilityLevels.dart';
import '../../../Model/Cosmetic/CosmeticItemModel.dart';
import '../../../Provider/CosmeticProvider.dart';
import '../../Mission/MissionPalette.dart';

/// 치장을 여는 능력치를 **화면에 어떻게 그릴지**를 모아 둔 곳이다.
///
/// 색과 이름과 아이콘을 새로 만들지 않고 미션·스탯창이 쓰는 것을 그대로
/// 가져온다. 같은 능력치가 화면마다 다른 색이면 색이 정보를 잃는다. 꾸미기
/// 화면의 잠금 배지가 출석 핑크면, 스탯창에서 핑크로 차오르던 그 눈금판을
/// 올리면 된다는 뜻이 된다.
///
/// **총 학습 레벨(능력치가 null)은 중성색**을 쓴다. 넷 중 하나를 빌려 쓰면
/// 그 능력치만 올려도 열리는 것으로 읽히고, 테마색을 쓰면 사용자가 테마를
/// 분홍으로 바꾸는 순간 출석과 같은 색이 된다.
abstract final class CosmeticAbilityStyle {
  /// 능력치를 미션 화면의 갈래로 옮긴다. 총 학습은 중성 갈래다.
  static MissionKind kindOf(CosmeticAbility? ability) => switch (ability) {
        CosmeticAbility.attendance => MissionKind.attendance,
        CosmeticAbility.noteWrite => MissionKind.noteWrite,
        CosmeticAbility.problemPractice => MissionKind.problemPractice,
        CosmeticAbility.notePractice => MissionKind.notePractice,
        null => MissionKind.etc,
      };

  /// 능력치 이름. `출석`, `총 학습` 처럼 사용자가 읽는 말이다.
  static String labelOf(CosmeticAbility? ability) =>
      cosmeticAbilityLabel(ability);

  /// 능력치 색 한 벌.
  static MissionKindColors colorsOf(CosmeticAbility? ability) =>
      MissionPalette.of(kindOf(ability));

  /// 능력치 아이콘. 총 학습은 넷을 합친 것이라 꽃 한 송이를 쓴다.
  ///
  /// 옷장 탭 무대의 학습 레벨 이름표와 같은 그림이다.
  static IconData iconOf(CosmeticAbility? ability) => ability == null
      ? Icons.local_florist_rounded
      : MissionPalette.iconOfKind(kindOf(ability));

  /// 이 아이템을 열려면 무엇을 얼마나 올려야 하는지. `출석 Lv.9`.
  static String requirementOf(CosmeticItemModel item) =>
      cosmeticRequirementLabel(item);

  /// 지금 내가 그 능력치에서 몇 레벨이고 몇 레벨이 남았는지.
  ///
  /// 필요 레벨만 적어 두면 그것이 코앞인지 한참 남았는지 알 수 없다. 지금
  /// 레벨을 옆에 붙이면 `한 레벨만 더` 가 생긴다. 한 칸 차이일 때 그 말을
  /// 그대로 쓰는 이유다.
  static String progressOf(
    CosmeticItemModel item,
    CosmeticAbilityLevels levels,
  ) {
    final label = labelOf(item.requiredAbility);
    final current = levels.levelOf(item.requiredAbility);
    final remaining = item.remainingLevelsAt(levels);

    if (remaining <= 0) return '지금 $label Lv.$current · 열려 있어요';
    if (remaining == 1) return '지금 $label Lv.$current · 한 레벨만 더!';
    return '지금 $label Lv.$current · $remaining 레벨 남았어요';
  }
}
