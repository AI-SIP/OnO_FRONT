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

  // 전체 레벨 (서버에서 계산된 값 사용)
  int _getOverallLevel() {
    if (userInfo == null) return 0;
    return userInfo!.totalStudyLevel;
  }

  // 현재 경험치 (서버에서 계산된 값 사용)
  int _getCurrentPoint() {
    if (userInfo == null) return 0;
    return userInfo!.totalStudyCurrentPoint;
  }

  // 다음 레벨까지 필요한 경험치 (서버에서 계산된 값 사용)
  int _getNextLevelThreshold() {
    if (userInfo == null) return 40;
    return userInfo!.totalStudyNextLevelThreshold;
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    int currentLevel = _getOverallLevel();
    int currentPoint = _getCurrentPoint();
    int requiredPoint = _getNextLevelThreshold();
    double progress = requiredPoint > 0 ? currentPoint / requiredPoint : 0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * horizontalMarginFactor,
        vertical: screenHeight * 0.01,
      ),
      padding: EdgeInsets.all(screenHeight * 0.02),
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
                ),
              ),
              Expanded(
                child: Center(
                  child: FrogCharacter(level: currentLevel, size: 92),
                ),
              ),
            ],
          ),
          if (userInfo != null) ...[
            SizedBox(height: screenHeight * 0.018),
            Divider(height: 1, color: Colors.grey[200]),
            SizedBox(height: screenHeight * 0.016),
            _buildActivityRow(
              icon: Icons.waving_hand_rounded,
              category: '출석',
              level: userInfo!.attendanceLevel,
              point: userInfo!.attendancePoint,
              color: Colors.pink[300]!,
            ),
            SizedBox(height: screenHeight * 0.012),
            _buildActivityRow(
              icon: Icons.edit_note,
              category: '오답노트 작성',
              level: userInfo!.noteWriteLevel,
              point: userInfo!.noteWritePoint,
              color: Colors.purple[300]!,
            ),
            SizedBox(height: screenHeight * 0.012),
            _buildActivityRow(
              icon: Icons.chrome_reader_mode_outlined,
              category: '문제 복습',
              level: userInfo!.problemPracticeLevel,
              point: userInfo!.problemPracticePoint,
              color: Colors.green[400]!,
            ),
            SizedBox(height: screenHeight * 0.012),
            _buildActivityRow(
              icon: Icons.history,
              category: '복습 세트 복습',
              level: userInfo!.notePracticeLevel,
              point: userInfo!.notePracticePoint,
              color: Colors.blue[300]!,
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
    double progress,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const StandardText(
          text: '학습 레벨',
          fontSize: 14,
          color: Colors.black87,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 82,
          height: 82,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 9,
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
                    fontSize: 15,
                    color: themeProvider.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 2),
                  StandardText(
                    text: '$currentPoint/$requiredPoint',
                    fontSize: 9,
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

  Widget _buildActivityLabel({
    required IconData icon,
    required String category,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: StandardText(
              text: category,
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityProgress({
    required int level,
    required int point,
    required int requiredPoint,
    required double progress,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: StandardText(
            text: 'Lv.$level',
            fontSize: 9,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 38,
          child: StandardText(
            text: '$point/$requiredPoint',
            fontSize: 9,
            color: Colors.grey[600]!,
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
  }) {
    int requiredPoint = 10 + (level - 1) * 10;
    double progress = requiredPoint > 0 ? point / requiredPoint : 0;

    return Row(
      children: [
        _buildActivityLabel(
          icon: icon,
          category: category,
          color: color,
        ),
        const SizedBox(width: 16),
        _buildActivityProgress(
          level: level,
          point: point,
          requiredPoint: requiredPoint,
          progress: progress,
          color: color,
        ),
      ],
    );
  }
}
