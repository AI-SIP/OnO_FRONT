import 'package:flutter/material.dart';

import '../../../Model/User/UserInfoModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import 'FrogCharacter.dart';

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
    final double frogSize = donutSize + 8.0 + labelFontSize * 1.3 - frogTopSpace;

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
        isTabletLandscape ? screenHeight * 0.038 : isTablet ? screenHeight * 0.025 : screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
                child: _buildLevelDonut(
                  currentLevel,
                  currentPoint,
                  requiredPoint,
                  progress,
                  donutSize: donutSize,
                  isTablet: isTablet,
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: frogTopSpace),
                    FrogCharacter(level: currentLevel, size: frogSize),
                  ],
                ),
              ),
            ],
          ),
          if (userInfo != null) ...[
            SizedBox(height: isTabletLandscape ? screenHeight * 0.030 : screenHeight * 0.018),
            Divider(height: 1, color: Colors.grey[200]),
            SizedBox(height: isTabletLandscape ? screenHeight * 0.028 : screenHeight * 0.016),
            _buildActivityRow(
              icon: Icons.waving_hand_rounded,
              category: '출석',
              level: userInfo!.attendanceLevel,
              point: userInfo!.attendancePoint,
              color: Colors.pink[300]!,
              isTablet: isTablet,
            ),
            SizedBox(height: isTabletLandscape ? screenHeight * 0.022 : screenHeight * 0.012),
            _buildActivityRow(
              icon: Icons.edit_note,
              category: '오답노트 작성',
              level: userInfo!.noteWriteLevel,
              point: userInfo!.noteWritePoint,
              color: Colors.purple[300]!,
              isTablet: isTablet,
            ),
            SizedBox(height: isTabletLandscape ? screenHeight * 0.022 : screenHeight * 0.012),
            _buildActivityRow(
              icon: Icons.chrome_reader_mode_outlined,
              category: '문제 복습',
              level: userInfo!.problemPracticeLevel,
              point: userInfo!.problemPracticePoint,
              color: Colors.green[400]!,
              isTablet: isTablet,
            ),
            SizedBox(height: isTabletLandscape ? screenHeight * 0.022 : screenHeight * 0.012),
            _buildActivityRow(
              icon: Icons.history,
              category: '복습 세트 복습',
              level: userInfo!.notePracticeLevel,
              point: userInfo!.notePracticePoint,
              color: Colors.blue[300]!,
              isTablet: isTablet,
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
          color: Colors.black87,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: donutSize,
          height: donutSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: donutSize,
                height: donutSize,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: isTablet ? 12.0 : 9.0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeProvider.primaryColor.withValues(alpha: 0.72),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StandardText(
                    text: 'Lv.$currentLevel',
                    fontSize: isTablet ? 19.0 : 15.0,
                    color: themeProvider.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 2),
                  StandardText(
                    text: '$currentPoint/$requiredPoint',
                    fontSize: isTablet ? 11.0 : 9.0,
                    color: Colors.black45,
                  ),
                ],
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: StandardText(
            text: category,
            fontSize: labelFontSize,
            color: Colors.black87,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: barMinHeight,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: pointsWidth,
          child: StandardText(
            text: '$point/$requiredPoint',
            fontSize: pointsFontSize,
            color: Colors.grey[600]!,
          ),
        ),
      ],
    );
  }
}