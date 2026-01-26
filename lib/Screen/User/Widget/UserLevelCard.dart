import 'package:flutter/material.dart';

import '../../../Model/User/UserInfoModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import 'FrogCharacter.dart';

class UserLevelCard extends StatelessWidget {
  final UserInfoModel? userInfo;
  final ThemeHandler themeProvider;
  final String userName;

  const UserLevelCard({
    super.key,
    required this.userInfo,
    required this.themeProvider,
    required this.userName,
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

    int currentLevel = _calculateOverallLevel();
    int currentPoint = _calculateOverallPoint();
    int requiredPoint = _calculateRequiredPoint();
    double progress = requiredPoint > 0 ? currentPoint / requiredPoint : 0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      padding: EdgeInsets.all(screenHeight * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 총 경험치 바
          _buildExpBar(screenHeight, currentLevel, currentPoint, requiredPoint,
              progress),
          SizedBox(height: screenHeight * 0.02),

          // 개구리 캐릭터
          FrogCharacter(level: currentLevel),
        ],
      ),
    );
  }

  Widget _buildExpBar(double screenHeight, int currentLevel, int currentPoint,
      int requiredPoint, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const StandardText(
              text: '학습 레벨',
              fontSize: 16,
              color: Colors.black87,
            ),
            Row(
              children: [
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
                SizedBox(width: screenHeight * 0.01),
                StandardText(
                  text: '$currentPoint / $requiredPoint',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.01),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              themeProvider.primaryColor.withOpacity(0.6),
            ),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
