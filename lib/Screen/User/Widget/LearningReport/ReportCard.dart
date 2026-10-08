import 'package:flutter/material.dart';

import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Motion/AppHaptic.dart';
import '../../../../Module/Motion/PressableScale.dart';
import '../../../../Module/Text/StandardText.dart';
import 'ReportPalette.dart';

/// 보고서의 한 칸. 흰 바탕에 칸끼리는 [ReportSectionGap] 띠로 나눈다.
///
/// 처음에는 칸마다 둥근 흰 카드를 옅은 테마색 바탕 위에 띄웠는데, 카드가 다섯
/// 장 쌓이니 덩어리가 많아 보여서 흰 바탕 한 장으로 바꿨다.
class ReportCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ReportCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      color: AppColors.surface,
      child: child,
    );
  }
}

/// 칸 사이의 회색 띠.
class ReportSectionGap extends StatelessWidget {
  const ReportSectionGap({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 10,
      child: ColoredBox(color: ReportPalette.divider),
    );
  }
}

/// 카드 제목. `오답노트 상태`, `자주 틀린 폴더` 처럼 카드 맨 위에 둔다.
class ReportCardTitle extends StatelessWidget {
  final String text;

  const ReportCardTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return ReportTracking(
      letterSpacing: -0.3,
      child: StandardText(
        text: text,
        fontSize: 17,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// 테마색 바탕에 흰 글자인 주 버튼. 앱의 다른 주 버튼(`추가`)과 같은 색이다.
///
/// 처음에는 파스텔 테마에서 흰 글자가 옅어 보일까 봐 검정으로 두었는데,
/// 보고서만 테마와 따로 놀아서 테마색으로 바꿨다.
class ReportPrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ReportPrimaryButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      haptic: HapticLevel.primary,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        // 글자를 키우면 늘어나야 해서 높이는 최소만 잡는다.
        constraints: const BoxConstraints(minHeight: 52),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(ReportPalette.buttonRadius),
        ),
        child: StandardText(
          text: label,
          fontSize: 16,
          height: 1.3,
          color: Colors.white,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
