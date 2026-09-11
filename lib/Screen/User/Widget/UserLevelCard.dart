import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/User/UserInfoModel.dart';
import '../../../Provider/CosmeticProvider.dart';
import '../../../Module/Motion/AnimatedCountText.dart';
import '../../../Module/Motion/AnimatedGauge.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import 'FrogCharacter.dart';
import '../../../Module/Design/AppRadius.dart';
import '../../../Module/Design/AppColors.dart';
import '../../../Module/Design/AppSpacing.dart';
import '../../../Module/Motion/PressableScale.dart';
import '../../../Module/Motion/TossPageRoute.dart';
import '../../Cosmetic/CosmeticClosetScreen.dart';
import '../../Mission/MissionPalette.dart';
import '../../Mission/MissionScreen.dart';

class UserLevelCard extends StatelessWidget {
  final UserInfoModel? userInfo;
  final ThemeHandler themeProvider;
  final String userName;
  final double horizontalMarginFactor;

  const UserLevelCard({
    super.key,
    required this.userInfo,
    required this.themeProvider,
    required this.userName,
    this.horizontalMarginFactor = 0.04,
  });

  /// 활동 레벨 막대가 위에서부터 하나씩 차오르도록 매기는 간격이다.
  /// 다섯 개가 한꺼번에 움직이면 산만하고, 너무 벌리면 마지막 것이 늦게 끝난다.
  static const Duration _activityStart = Duration(milliseconds: 140);
  static const Duration _activityGap = Duration(milliseconds: 90);

  Duration _activityDelay(int index) => _activityStart + _activityGap * index;

  int _getOverallLevel() {
    if (userInfo == null) return 0;
    return userInfo!.totalStudyLevel;
  }

  int _getCurrentPoint() {
    if (userInfo == null) return 0;
    return userInfo!.totalStudyCurrentPoint;
  }

  int _getNextLevelThreshold() {
    if (userInfo == null) return 40;
    return userInfo!.totalStudyNextLevelThreshold;
  }

  /// 미션 화면으로 간다.
  ///
  /// 마이페이지의 레벨과 미션 보상 XP 는 같은 값이다. 두 화면이 이어져 있다는
  /// 것이 눌러 보면 드러나게 한다.
  void _openMissions(BuildContext context) {
    Navigator.push(
      context,
      TossPageRoute(builder: (_) => const MissionScreen()),
    );
  }

  /// 개구리 옷장으로 간다.
  ///
  /// **개구리를 직접 누르는 것이 첫 번째 길이다.** 꾸미러 가는 문이 개구리
  /// 자신인 쪽이 가장 자연스럽다. 격려 말풍선은 옷장 무대의 개구리로 자리를
  /// 옮겼다. 여기 링크는 그 길이 있다는 것을 글로도 알리는 두 번째 길이다.
  void _openCloset(BuildContext context) {
    Navigator.push(
      context,
      TossPageRoute(builder: (_) => const CosmeticClosetScreen()),
    );
  }

  /// 활동별 경험치 위에 붙는 작은 길잡이다.
  ///
  /// 아래 네 줄이 미션으로 오르는 경험치라서 그 바로 위에 둔다. 카드 전체를
  /// 누르게 하지 않는 이유는 왼쪽 도넛과 오른쪽 개구리가 서로 다른 화면으로
  /// 가기 때문이다. 카드가 누름을 가로채면 둘 다 죽는다.
  Widget _buildMissionLink(BuildContext context, {required bool isTablet}) {
    // 좁은 폰에서 두 링크가 한 줄에 다 안 들어가면 아래로 접히게 한다.
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildCardLink(
          label: '개구리 꾸미기',
          onTap: () => _openCloset(context),
          isTablet: isTablet,
        ),
        _buildCardLink(
          label: '미션 보기',
          onTap: () => _openMissions(context),
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _buildCardLink({
    required String label,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StandardText(
              text: label,
              fontSize: isTablet ? 13 : 12,
              color: themeProvider.primaryColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Icon(
              Icons.chevron_right,
              size: isTablet ? 18 : 15,
              color: themeProvider.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final double screenHeight = mq.size.height;
    final double screenWidth = mq.size.width;
    final bool isTablet = mq.size.shortestSide >= 600;
    final bool isTabletLandscape = isTablet && screenWidth > screenHeight;

    final double donutSize = isTablet ? 120.0 : 82.0;
    final double labelFontSize = isTablet ? 16.0 : 14.0;
    final double frogTopSpace = isTablet ? 14.0 : 10.0;
    final double frogSize =
        donutSize + 8.0 + labelFontSize * 1.3 - frogTopSpace;

    int currentLevel = _getOverallLevel();
    int currentPoint = _getCurrentPoint();
    int requiredPoint = _getNextLevelThreshold();
    double progress = requiredPoint > 0 ? currentPoint / requiredPoint : 0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * horizontalMarginFactor,
        vertical: screenHeight * 0.01,
      ),
      padding: EdgeInsets.all(
        isTabletLandscape
            ? screenHeight * 0.038
            : isTablet
                ? screenHeight * 0.025
                : screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                // 왼쪽 도넛은 미션, 오른쪽 개구리는 옷장이다. 카드 전체를
                // 누르게 하면 둘 중 하나만 남는다.
                child: PressableScale(
                  onTap: () => _openMissions(context),
                  child: _buildLevelDonut(
                    currentLevel,
                    currentPoint,
                    requiredPoint,
                    progress,
                    donutSize: donutSize,
                    isTablet: isTablet,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: frogTopSpace),
                    // 개구리를 누르면 바로 옷장으로 간다. 꾸미러 가는 문이
                    // 개구리 자신인 쪽이 작은 글자 링크보다 훨씬 잘 보인다.
                    // 격려 말풍선은 옷장 무대로 옮겨서, 여기서는 누름 하나가
                    // 한 가지 일만 하게 한다.
                    FrogCharacter(
                      layers: context.watch<CosmeticProvider>().layers,
                      size: frogSize,
                      showEncouragement: false,
                      onTap: () => _openCloset(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (userInfo != null) ...[
            SizedBox(
                height: isTabletLandscape
                    ? screenHeight * 0.030
                    : screenHeight * 0.018),
            Divider(height: 1, color: Colors.grey[200]),
            SizedBox(
                height: isTabletLandscape
                    ? screenHeight * 0.020
                    : screenHeight * 0.012),
            Align(
              alignment: Alignment.centerRight,
              child: _buildMissionLink(context, isTablet: isTablet),
            ),
            SizedBox(
                height: isTabletLandscape
                    ? screenHeight * 0.016
                    : screenHeight * 0.008),
            _buildActivityRow(
              icon: Icons.waving_hand_rounded,
              category: '출석',
              level: userInfo!.attendanceLevel,
              point: userInfo!.attendancePoint,
              color: MissionPalette.of(MissionKind.attendance).accent,
              isTablet: isTablet,
              delay: _activityDelay(0),
            ),
            SizedBox(
                height: isTabletLandscape
                    ? screenHeight * 0.022
                    : screenHeight * 0.012),
            _buildActivityRow(
              icon: Icons.edit_note,
              category: '오답노트 작성',
              level: userInfo!.noteWriteLevel,
              point: userInfo!.noteWritePoint,
              color: MissionPalette.of(MissionKind.noteWrite).accent,
              isTablet: isTablet,
              delay: _activityDelay(1),
            ),
            SizedBox(
                height: isTabletLandscape
                    ? screenHeight * 0.022
                    : screenHeight * 0.012),
            _buildActivityRow(
              icon: Icons.chrome_reader_mode_outlined,
              category: '문제 복습',
              level: userInfo!.problemPracticeLevel,
              point: userInfo!.problemPracticePoint,
              color: MissionPalette.of(MissionKind.problemPractice).accent,
              isTablet: isTablet,
              delay: _activityDelay(2),
            ),
            SizedBox(
                height: isTabletLandscape
                    ? screenHeight * 0.022
                    : screenHeight * 0.012),
            _buildActivityRow(
              icon: Icons.history,
              category: '복습 세트 복습',
              level: userInfo!.notePracticeLevel,
              point: userInfo!.notePracticePoint,
              color: MissionPalette.of(MissionKind.notePractice).accent,
              isTablet: isTablet,
              delay: _activityDelay(3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelDonut(
    int currentLevel,
    int currentPoint,
    int requiredPoint,
    double progress, {
    double donutSize = 82.0,
    bool isTablet = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StandardText(
          text: '학습 레벨',
          fontSize: isTablet ? 16.0 : 14.0,
          color: AppColors.textPrimary,
        ),
        const SizedBox(height: 8),
        AnimatedCircularGauge(
          value: progress,
          size: donutSize,
          strokeWidth: isTablet ? 12.0 : 9.0,
          color: themeProvider.primaryColor.withValues(alpha: 0.72),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StandardText(
                text: 'Lv.$currentLevel',
                fontSize: isTablet ? 19.0 : 15.0,
                color: themeProvider.primaryColor,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 2),
              AnimatedCountText(
                value: currentPoint,
                formatter: (value) => '${value.round()}/$requiredPoint',
                fontSize: isTablet ? 11.0 : 9.0,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required String category,
    required int level,
    required int point,
    required Color color,
    bool isTablet = false,
    Duration delay = Duration.zero,
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
            backgroundColor: Colors.grey[200],
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
            color: Colors.grey[600]!,
            delay: delay,
          ),
        ),
      ],
    );
  }
}
