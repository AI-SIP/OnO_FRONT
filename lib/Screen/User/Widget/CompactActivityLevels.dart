import 'package:flutter/material.dart';

import '../../../Model/User/UserInfoModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';

class CompactActivityLevels extends StatelessWidget {
  final UserInfoModel? userInfo;
  final ThemeHandler themeProvider;

  const CompactActivityLevels({
    super.key,
    required this.userInfo,
    required this.themeProvider,
  });

  // 전체 레벨 계산 (4개 활동의 평균)
  int _calculateOverallLevel() {
    if (userInfo == null) return 0;
    return ((userInfo!.attendanceLevel +
                userInfo!.noteWriteLevel +
                userInfo!.problemPracticeLevel +
                userInfo!.notePracticeLevel) /
            4)
        .floor();
  }

  // 전체 경험치 계산
  int _calculateOverallPoint() {
    if (userInfo == null) return 0;
    return userInfo!.attendancePoint +
        userInfo!.noteWritePoint +
        userInfo!.problemPracticePoint +
        userInfo!.notePracticePoint;
  }

  // 다음 레벨까지 필요한 경험치
  int _calculateRequiredPoint() {
    int level = _calculateOverallLevel();
    return (level + 1) * 400; // 4개 활동 각각 100포인트씩 = 400포인트
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    if (userInfo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
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
          // 활동 레벨 타이틀
          const StandardText(
            text: '활동 레벨',
            fontSize: 15,
            color: Colors.black87,
          ),
          SizedBox(height: screenHeight * 0.015),
          _buildActivityRow(
            icon: Icons.waving_hand_rounded,
            category: '출석',
            level: userInfo!.attendanceLevel,
            point: userInfo!.attendancePoint,
            color: Colors.pink[300]!,
            screenHeight: screenHeight,
          ),
          SizedBox(height: screenHeight * 0.012),
          _buildActivityRow(
            icon: Icons.edit_note,
            category: '오답노트 작성',
            level: userInfo!.noteWriteLevel,
            point: userInfo!.noteWritePoint,
            color: Colors.purple[300]!,
            screenHeight: screenHeight,
          ),
          SizedBox(height: screenHeight * 0.012),
          _buildActivityRow(
            icon: Icons.chrome_reader_mode_outlined,
            category: '문제 복습',
            level: userInfo!.problemPracticeLevel,
            point: userInfo!.problemPracticePoint,
            color: Colors.green[400]!,
            screenHeight: screenHeight,
          ),
          SizedBox(height: screenHeight * 0.012),
          _buildActivityRow(
            icon: Icons.history,
            category: '복습노트 복습',
            level: userInfo!.notePracticeLevel,
            point: userInfo!.notePracticePoint,
            color: Colors.blue[300]!,
            screenHeight: screenHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallExpBar(double screenHeight) {
    int currentLevel = _calculateOverallLevel();
    int currentPoint = _calculateOverallPoint();
    int requiredPoint = _calculateRequiredPoint();
    double progress = requiredPoint > 0 ? currentPoint / requiredPoint : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                StandardText(
                  text: '총 경험치',
                  fontSize: 16,
                  color: Colors.black87,
                ),
                SizedBox(width: screenHeight * 0.01),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StandardText(
                    text: 'Lv.$currentLevel',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            StandardText(
              text: '$currentPoint / $requiredPoint',
              fontSize: 13,
              color: Colors.black54,
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.01),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              themeProvider.primaryColor,
            ),
            minHeight: 10,
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
    required double screenHeight,
  }) {
    // 활동별 경험치 필요량: 10 + (level - 1) * 10
    int requiredPoint = 10 + (level - 1) * 10;
    double progress = requiredPoint > 0 ? point / requiredPoint : 0;

    return Row(
      children: [
        // 아이콘
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        SizedBox(width: screenHeight * 0.012),
        // 카테고리명
        SizedBox(
          width: 100,
          child: StandardText(
            text: category,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        SizedBox(width: screenHeight * 0.008),
        // 레벨
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: StandardText(
            text: 'Lv.$level',
            fontSize: 11,
            color: Colors.white,
          ),
        ),
        SizedBox(width: screenHeight * 0.008),
        // 프로그레스 바
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        SizedBox(width: screenHeight * 0.008),
        // 포인트
        SizedBox(
          width: 50,
          child: StandardText(
            text: '$point/$requiredPoint',
            fontSize: 10,
            color: Colors.grey[600]!,
          ),
        ),
      ],
    );
  }
}
