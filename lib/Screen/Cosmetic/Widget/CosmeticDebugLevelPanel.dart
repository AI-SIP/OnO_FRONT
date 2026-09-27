import 'package:flutter/material.dart';

import '../../../Model/Cosmetic/CosmeticAbilityLevels.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/AppMotion.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Text/StandardText.dart';
import 'CosmeticAbilityStyle.dart';

/// **디버그 전용.** 능력치 레벨 다섯을 직접 옮겨 보는 접이식 패널이다.
///
/// 해금이 능력치별로 갈리면서 조절할 것이 하나에서 다섯으로 늘었다. 슬라이더
/// 다섯 개를 화면에 붙박이로 세우면 개구리보다 조절기가 큰 화면이 된다. 그래서
/// **접어 둔다.** 접힌 모습은 한 줄이고, 그 줄에 다섯 레벨이 색 점으로 적혀
/// 있어서 펴지 않아도 지금 어디에 서 있는지는 읽힌다.
///
/// 생김새를 일부러 앱의 다른 화면과 다르게 뒀다. 회색 바탕에 벌레 아이콘을
/// 달고 `디버그` 라고 적는다. 출시본에는 [kDebugMode] 로 아예 들어가지 않는
/// 물건이라, 시안을 보는 사람이 이것을 제품의 일부로 착각하면 안 된다.
///
/// 총 학습 레벨은 실제로는 능력치 넷을 합산해 오르는 값이지만 여기서는 따로
/// 조절한다. 넷에 묶어 두면 `총 학습 Lv.16 부터` 인 랜턴을 보려고 넷을 전부
/// 끝까지 올려야 하고, 그러면 능력치별 잠금이 하나도 안 남아 시안이 보여
/// 줘야 할 것의 절반이 사라진다.
class CosmeticDebugLevelPanel extends StatefulWidget {
  /// 지금 레벨 다섯.
  final CosmeticAbilityLevels levels;

  /// 하나를 옮겼을 때. null 이면 총 학습 레벨이다.
  final void Function(CosmeticAbility? ability, int level) onChanged;

  /// 다섯을 통째로 갈아 끼울 때. `전부 1` / `전부 최대` 가 쓴다.
  final ValueChanged<CosmeticAbilityLevels> onReplaced;

  const CosmeticDebugLevelPanel({
    super.key,
    required this.levels,
    required this.onChanged,
    required this.onReplaced,
  });

  /// 조절할 것들. 왼쪽부터 스탯창의 눈금판 순서와 같고 총 학습이 맨 뒤다.
  static const List<CosmeticAbility?> abilities = <CosmeticAbility?>[
    CosmeticAbility.attendance,
    CosmeticAbility.noteWrite,
    CosmeticAbility.problemPractice,
    CosmeticAbility.notePractice,
    null,
  ];

  @override
  State<CosmeticDebugLevelPanel> createState() =>
      _CosmeticDebugLevelPanelState();
}

class _CosmeticDebugLevelPanelState extends State<CosmeticDebugLevelPanel> {
  /// 펴 놓았는지. 처음에는 접혀 있다. 개구리가 주인공인 화면이다.
  bool _expanded = false;

  void _toggle() {
    AppHaptic.selection();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: AnimatedSize(
        duration: AppMotion.normal,
        curve: AppMotion.emphasized,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            if (_expanded) ...[
              const Divider(height: 1, color: AppColors.border),
              _buildSliders(),
            ],
          ],
        ),
      ),
    );
  }

  /// 접힌 줄. 눌러서 편다.
  ///
  /// 접혀 있어도 다섯 레벨을 색 점으로 적어 둔다. 무엇이 얼마나 올라가 있는지
  /// 보려고 매번 펴야 하면 접어 둔 값어치가 없다.
  Widget _buildHeader() {
    return PressableScale(
      onTap: _toggle,
      haptic: HapticLevel.none,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.bug_report_outlined,
              size: 15,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.xs),
            const StandardText(
              text: '디버그 레벨',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              maxLines: 1,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final ability in CosmeticDebugLevelPanel.abilities)
                      _buildChip(ability),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  /// 접힌 줄에 붙는 레벨 한 조각. 능력치 색으로 물들인다.
  Widget _buildChip(CosmeticAbility? ability) {
    final colors = CosmeticAbilityStyle.colorsOf(ability);

    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: StandardText(
        text: '${widget.levels.levelOf(ability)}',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: colors.accent,
        maxLines: 1,
      ),
    );
  }

  /// 펼친 몸통. 능력치마다 한 줄이고 맨 아래에 한 번에 옮기는 버튼 둘이 있다.
  Widget _buildSliders() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final ability in CosmeticDebugLevelPanel.abilities)
            _AbilitySlider(
              ability: ability,
              level: widget.levels.levelOf(ability),
              onChanged: (level) => widget.onChanged(ability, level),
            ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _buildPreset(
                  '전부 1',
                  CosmeticAbilityLevels.start,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildPreset(
                  '전부 최대',
                  CosmeticAbilityLevels.max,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreset(String label, CosmeticAbilityLevels levels) {
    return PressableScale(
      onTap: () {
        AppHaptic.selection();
        widget.onReplaced(levels);
      },
      haptic: HapticLevel.none,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: AppColors.border),
        ),
        child: StandardText(
          text: label,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}

/// 능력치 하나를 옮기는 줄.
///
/// 왼쪽에 아이콘과 이름, 오른쪽 끝에 지금 레벨, 가운데가 슬라이더다. 이름 칸을
/// 고정 폭으로 두지 않는 이유는 글자를 키운 기기에서 `문제 복습` 이 잘리기
/// 때문이다. 대신 [FittedBox] 로 줄여 앉힌다.
class _AbilitySlider extends StatelessWidget {
  final CosmeticAbility? ability;
  final int level;
  final ValueChanged<int> onChanged;

  const _AbilitySlider({
    required this.ability,
    required this.level,
    required this.onChanged,
  });

  /// 이름 칸의 폭. 다섯 줄의 슬라이더 왼쪽 끝이 가지런해야 훑어보기 좋다.
  static const double _labelWidth = 74.0;

  @override
  Widget build(BuildContext context) {
    final colors = CosmeticAbilityStyle.colorsOf(ability);
    final max = CosmeticAbilityLevels.maxLevelOf(ability);

    return Row(
      children: [
        SizedBox(
          width: _labelWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CosmeticAbilityStyle.iconOf(ability),
                  size: 14,
                  color: colors.accent,
                ),
                const SizedBox(width: 3),
                StandardText(
                  text: CosmeticAbilityStyle.labelOf(ability),
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: level.toDouble(),
              min: CosmeticAbilityLevels.minLevel.toDouble(),
              max: max.toDouble(),
              divisions: max - CosmeticAbilityLevels.minLevel,
              label: 'Lv.$level',
              activeColor: colors.accent,
              inactiveColor: colors.surface,
              onChanged: (value) => onChanged(value.round()),
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: StandardText(
            text: 'Lv.$level',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.accent,
            textAlign: TextAlign.right,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
