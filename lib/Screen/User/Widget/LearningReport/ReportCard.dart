import 'package:flutter/material.dart';

import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Motion/AppHaptic.dart';
import '../../../../Module/Motion/PressableScale.dart';
import '../../../../Module/Text/StandardText.dart';
import 'ReportPalette.dart';

/// 보고서의 흰 카드. 다섯 칸이 같은 모서리와 바탕을 쓴다.
class ReportCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ReportCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ReportPalette.cardRadius),
      ),
      child: child,
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

/// 검정 바탕에 흰 글자인 주 버튼.
///
/// 테마색 바탕에 흰 글자를 두면 분홍이나 하늘색 같은 파스텔 테마에서 글자가
/// 잘 안 읽힌다. 테마와 상관없이 검정으로 둔다.
class ReportPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ReportPrimaryButton({
    super.key,
    required this.label,
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
          color: AppColors.textPrimary,
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
