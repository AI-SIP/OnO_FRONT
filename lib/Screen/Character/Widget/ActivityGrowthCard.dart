import 'package:flutter/material.dart';

import '../../../Model/User/UserInfoModel.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Motion/AnimatedCountText.dart';
import '../../../Module/Motion/AnimatedGauge.dart';
import '../../../Module/Text/StandardText.dart';
import '../../Mission/MissionPalette.dart';

/// 무엇을 해서 레벨이 오르는지 네 줄로 보여 주는 카드다.
///
/// 마이페이지 레벨 카드(`UserLevelCard`) 아래쪽에 있던 것을 그대로 옮겨 왔다.
/// 레벨과 경험치가 캐릭터 탭으로 온 이상, **그 경험치가 어디서 오는지**도
/// 같은 화면에 있어야 한다. 위에서 미션을 받으면 여기 네 줄 중 하나가 오르는
/// 것이라, 미션 목록 바로 아래가 제 자리다.
///
/// 줄마다 색이 다른 것은 장식이 아니다. 미션 카드의 아이콘 색과 같은 색이라
/// ([MissionPalette]), 방금 받은 미션이 어느 줄을 올렸는지 색만 보고 알 수
/// 있다.
class ActivityGrowthCard extends StatelessWidget {
  final UserInfoModel userInfo;

  const ActivityGrowthCard({super.key, required this.userInfo});

  /// 막대가 위에서부터 하나씩 차오르도록 매기는 간격이다.
  /// 넷이 한꺼번에 움직이면 산만하고, 너무 벌리면 마지막 것이 늦게 끝난다.
  static const Duration _start = Duration(milliseconds: 140);
  static const Duration _gap = Duration(milliseconds: 90);

  static Duration _delay(int index) => _start + _gap * index;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    final rows = <({IconData icon, String category, int level, int point})>[
      (
        icon: Icons.waving_hand_rounded,
        category: '출석',
        level: userInfo.attendanceLevel,
        point: userInfo.attendancePoint,
      ),
      (
        icon: Icons.edit_note,
        category: '오답노트 작성',
        level: userInfo.noteWriteLevel,
        point: userInfo.noteWritePoint,
      ),
      (
        icon: Icons.chrome_reader_mode_outlined,
        category: '문제 복습',
        level: userInfo.problemPracticeLevel,
        point: userInfo.problemPracticePoint,
      ),
      (
        icon: Icons.history,
        category: '복습 세트 복습',
        level: userInfo.notePracticeLevel,
        point: userInfo.notePracticePoint,
      ),
    ];

    const kinds = [
      MissionKind.attendance,
      MissionKind.noteWrite,
      MissionKind.problemPractice,
      MissionKind.notePractice,
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StandardText(
            text: '무엇으로 자랐나',
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.md),
            _buildRow(
              icon: rows[index].icon,
              category: rows[index].category,
              level: rows[index].level,
              point: rows[index].point,
              color: MissionPalette.of(kinds[index]).accent,
              isTablet: isTablet,
              delay: _delay(index),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String category,
    required int level,
    required int point,
    required Color color,
    required bool isTablet,
    required Duration delay,
  }) {
    final requiredPoint = 10 + (level - 1) * 10;
    final progress = requiredPoint > 0 ? point / requiredPoint : 0.0;
    final iconSize = isTablet ? 18.0 : 15.0;
    final iconPadding = isTablet ? 6.0 : 5.0;
    final labelFontSize = isTablet ? 13.0 : 11.0;
    final levelFontSize = isTablet ? 10.0 : 9.0;
    final barMinHeight = isTablet ? 7.0 : 5.0;
    final pointsWidth = isTablet ? 56.0 : 38.0;
    final pointsFontSize = isTablet ? 10.0 : 9.0;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: StandardText(
            text: category,
            fontSize: labelFontSize,
            color: AppColors.textPrimary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: StandardText(
            text: 'Lv.$level',
            fontSize: levelFontSize,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: AnimatedLinearGauge(
            value: progress,
            color: color,
            backgroundColor: AppColors.surfaceMuted,
            height: barMinHeight,
            delay: delay,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: pointsWidth,
          child: AnimatedCountText(
            value: point,
            formatter: (value) => '${value.round()}/$requiredPoint',
            fontSize: pointsFontSize,
            color: AppColors.textTertiary,
            delay: delay,
          ),
        ),
      ],
    );
  }
}
