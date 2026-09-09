import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Module/Design/AppColors.dart';
import '../../Module/Design/AppRadius.dart';
import '../../Module/Design/AppSpacing.dart';
import '../../Module/Motion/TossDialog.dart';
import '../../Module/Text/StandardText.dart';
import '../../Module/Theme/ThemeHandler.dart';

/// 미션 보상으로 레벨이 올랐을 때 띄우는 알림이다.
///
/// 1차는 다이얼로그 하나로 끝낸다. 레벨별 개구리 15종은 아직 제작 중이라
/// 그림을 쓰지 않는다. 에셋이 들어오면 이 다이얼로그 안에만 넣으면 된다.
Future<void> showMissionLevelUpDialog(
  BuildContext context, {
  int? level,
}) {
  return showTossDialog<void>(
    context: context,
    builder: (dialogContext) => _MissionLevelUpDialog(level: level),
  );
}

class _MissionLevelUpDialog extends StatelessWidget {
  final int? level;

  const _MissionLevelUpDialog({this.level});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                color: themeProvider.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            StandardText(
              text: '레벨이 올랐어요!',
              fontSize: 18,
              color: themeProvider.primaryColor,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            StandardText(
              text: level != null ? '이제 Lv.$level 이에요.' : '축하해요. 한 단계 자랐어요.',
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                child: const StandardText(
                  text: '확인',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
