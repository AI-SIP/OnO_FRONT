import 'package:flutter/material.dart';

import '../../../../Model/LearningReport/LearningOverviewModel.dart';
import '../../../../Module/Design/AppColors.dart';
import '../../../../Module/Motion/AppHaptic.dart';
import '../../../../Module/Motion/AppMotion.dart';
import '../../../../Module/Motion/AppearTransition.dart';
import '../../../../Module/Motion/PressableScale.dart';
import '../../../../Module/Text/StandardText.dart';
import 'ReportCard.dart';
import 'ReportPalette.dart';

/// 자주 틀린 폴더. 정답률이 낮은 순으로 최대 세 개다.
///
/// 예전 보고서는 서술형, 객관식 같은 문제 유형으로 약점을 묶어서 보고 나서
/// 할 수 있는 일이 없었다. 폴더로 묶으면 눌러서 그 폴더로 바로 갈 수 있다.
class WeakFolderCard extends StatelessWidget {
  final List<LearningWeakFolder> folders;

  /// [rank] 는 1 부터 센다.
  final void Function(LearningWeakFolder folder, int rank) onTap;

  final Duration delay;

  const WeakFolderCard({
    super.key,
    required this.folders,
    required this.onTap,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final shown = folders.take(3).toList();

    return ReportCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ReportCardTitle('자주 틀린 폴더'),
          const SizedBox(height: 6),
          ...AppearTransition.stagger(
            [
              for (var i = 0; i < shown.length; i++)
                _FolderRow(
                  folder: shown[i],
                  rank: i + 1,
                  divided: i < shown.length - 1,
                  onTap: () => onTap(shown[i], i + 1),
                ),
            ],
            initialDelay: delay + AppMotion.stagger,
          ),
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  final LearningWeakFolder folder;
  final int rank;
  final bool divided;
  final VoidCallback onTap;

  const _FolderRow({
    required this.folder,
    required this.rank,
    required this.divided,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 색은 보이는 숫자로 고른다. 49.6 을 50% 로 보이면서 빨강으로 칠하면
    // 기준과 어긋나 보인다.
    final percent = folder.accuracy.round();
    final ink = ReportPalette.accuracyInk(percent.toDouble());

    return PressableScale(
      haptic: HapticLevel.none,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          // 눌리는 줄 전체가 투명하면 글자 사이를 눌렀을 때 반응이 없다.
          color: AppColors.surface,
          border: divided
              ? const Border(bottom: BorderSide(color: ReportPalette.divider))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ReportPalette.accuracyBg(percent.toDouble()),
                borderRadius: BorderRadius.circular(9),
              ),
              child: StandardText(
                text: '$rank',
                fontSize: 13,
                height: 1.2,
                color: ink,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportTracking(
                    letterSpacing: -0.2,
                    child: StandardText(
                      text: folder.name,
                      fontSize: 15,
                      height: 1.3,
                      color: AppColors.textPrimary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 3),
                  StandardText(
                    text: '${folder.wrongCount}번 틀렸어요',
                    fontSize: 13,
                    height: 1.3,
                    fontFamily: 'PretendardLight',
                    fontWeight: FontWeight.w300,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StandardText(
                  text: '$percent%',
                  fontSize: 15,
                  height: 1.3,
                  color: ink,
                ),
                const SizedBox(height: 2),
                const StandardText(
                  text: '정답률',
                  fontSize: 12,
                  height: 1.3,
                  fontFamily: 'PretendardLight',
                  fontWeight: FontWeight.w300,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
