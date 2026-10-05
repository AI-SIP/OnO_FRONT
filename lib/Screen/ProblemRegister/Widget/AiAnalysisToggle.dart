import 'package:flutter/material.dart';

import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Motion/AppHaptic.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Text/mobile_font_size.dart';

/// 오답노트를 등록할 때 AI 분석을 돌릴지 고르는 줄.
///
/// 줄 어디를 눌러도 바뀐다. 끄면 등록한 뒤 분석을 요청하지 않고, 나중에
/// 문제 상세에서 그 문제만 분석할 수 있다.
class AiAnalysisToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color color;

  const AiAnalysisToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return PressableScale(
      haptic: HapticLevel.selection,
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: color.withValues(alpha: 0.16),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Icon(Icons.auto_awesome, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StandardText(
                    text: 'AI 분석',
                    fontSize: MobileFontSize.reduced(context, 14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 2),
                  StandardText(
                    text: value
                        ? '등록하면 풀이 방향과 주의할 점을 정리해 드려요'
                        : '분석하지 않아요. 문제 상세에서 따로 분석할 수 있어요',
                    fontSize: MobileFontSize.reduced(context, 12),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              activeColor: color,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
