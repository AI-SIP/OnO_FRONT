import 'package:flutter/material.dart';
import '../../../Model/User/UserInfoModel.dart';
import '../../../Module/Text/StandardText.dart';
import '../../../Module/Theme/ThemeHandler.dart';
import 'FrogCharacter.dart';

class UserLevelCard extends StatelessWidget {
  final UserInfoModel? userInfo;
  final ThemeHandler themeProvider;

  const UserLevelCard({
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

    int currentLevel = _calculateOverallLevel();
    int currentPoint = _calculateOverallPoint();
    int requiredPoint = _calculateRequiredPoint();
    double progress = requiredPoint > 0 ? currentPoint / requiredPoint : 0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      padding: EdgeInsets.all(screenHeight * 0.02),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeProvider.primaryColor.withOpacity(0.1),
            themeProvider.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeProvider.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // 레벨 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StandardText(
                text: 'Level ',
                fontSize: 24,
                color: themeProvider.primaryColor,
              ),
              StandardText(
                text: '$currentLevel',
                fontSize: 32,
                color: themeProvider.primaryColor,
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),

          // 개구리 캐릭터
          FrogCharacter(level: currentLevel),

          SizedBox(height: screenHeight * 0.02),

          // 경험치 바
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StandardText(
                    text: '총 경험치',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  StandardText(
                    text: '$currentPoint / $requiredPoint',
                    fontSize: 14,
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
                  minHeight: 12,
                ),
              ),
              SizedBox(height: screenHeight * 0.005),
              StandardText(
                text: '다음 레벨까지 ${requiredPoint - currentPoint}pt 남았어요!',
                fontSize: 12,
                color: themeProvider.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}